const { onCall } = require("firebase-functions/v2/https");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");
admin.initializeApp();
const db = admin.firestore();

/**
 * Cloud Function untuk membuat user baru oleh admin tanpa mengubah auth state admin
 * DITAMBAHKAN: Fungsi baru untuk mengatasi masalah logout
 */
exports.createUserByAdmin = onCall({ region: "asia-southeast1" }, async (request) => {
  try {
    // 1. Verifikasi bahwa pengguna sudah login
    if (!request.auth) {
      logger.error("Fungsi dipanggil oleh pengguna yang tidak terautentikasi.");
      throw new functions.https.HttpsError("unauthenticated", "Anda harus login untuk menggunakan fungsi ini.");
    }

    const callerUid = request.auth.uid;

    // 2. Verifikasi bahwa caller adalah admin
    const callerDoc = await db.collection("users").doc(callerUid).get();
    if (!callerDoc.exists || callerDoc.data().role !== "admin") {
      logger.warn(`Pengguna non-admin (UID: ${callerUid}) mencoba membuat user baru.`);
      throw new functions.https.HttpsError("permission-denied", "Hanya admin yang dapat membuat user baru.");
    }

    // 3. Ambil dan validasi parameter
    const { email, password, name, role, isDriver } = request.data;

    if (!email || !password || !name || !role) {
      logger.error("Parameter tidak lengkap.", { data: request.data });
      throw new functions.https.HttpsError("invalid-argument", "Parameter email, password, name, dan role harus disediakan.");
    }

    // Validasi email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      throw new functions.https.HttpsError("invalid-argument", "Format email tidak valid.");
    }

    // Validasi password
    if (password.length < 6) {
      throw new functions.https.HttpsError("invalid-argument", "Password harus minimal 6 karakter.");
    }

    // Validasi role
    const validRoles = ["employee", "officer", "technician", "admin"];
    if (!validRoles.includes(role)) {
      throw new functions.https.HttpsError("invalid-argument", `Role harus salah satu dari: ${validRoles.join(", ")}`);
    }

    logger.info(`Admin ${callerUid} membuat user baru: ${name} (${email}) dengan role: ${role}, isDriver: ${isDriver}`);

    // 4. Buat user di Firebase Auth
    let userRecord;
    try {
      userRecord = await admin.auth().createUser({
        email: email,
        password: password,
        displayName: name,
        emailVerified: false,
      });
      logger.info(`✅ User Firebase Auth berhasil dibuat dengan UID: ${userRecord.uid}`);
    } catch (authError) {
      logger.error(`❌ Gagal membuat user di Firebase Auth: ${authError.message}`);

      // Handle specific auth errors
      if (authError.code === "auth/email-already-exists") {
        throw new functions.https.HttpsError("already-exists", "Email sudah terdaftar dalam sistem.");
      } else if (authError.code === "auth/invalid-email") {
        throw new functions.https.HttpsError("invalid-argument", "Format email tidak valid.");
      } else if (authError.code === "auth/weak-password") {
        throw new functions.https.HttpsError("invalid-argument", "Password terlalu lemah.");
      } else {
        throw new functions.https.HttpsError("internal", `Gagal membuat user: ${authError.message}`);
      }
    }

    const newUserUid = userRecord.uid;

    try {
      // 5. Buat user document di Firestore
      const userData = {
        uid: newUserUid,
        name: name,
        email: email,
        role: role,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      // Tambahkan flag isDriver jika role technician dan isDriver true
      if (role === "technician" && isDriver === true) {
        userData.isDriver = true;
      }

      await db.collection("users").doc(newUserUid).set(userData);
      logger.info(`✅ User document berhasil dibuat di Firestore untuk UID: ${newUserUid}`);

      // 6. Buat driver document jika diperlukan
      let isDriverCreated = false;
      if (role === "technician") {
        // Cek apakah user harus jadi driver (berdasarkan flag atau nama/email)
        const shouldBeDriver = isDriver === true || name.toLowerCase().includes("driver") || email.toLowerCase().includes("driver");

        if (shouldBeDriver) {
          logger.info(`🚗 Membuat driver document untuk user: ${name} (${newUserUid})`);

          try {
            await db.collection("drivers").doc(newUserUid).set({
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              currentVehicleId: null,
              currentVehicleName: null,
              email: email,
              isAvailable: true,
              name: name,
              status: "active",
              uid: newUserUid,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            logger.info(`✅ Driver document berhasil dibuat untuk UID: ${newUserUid}`);
            isDriverCreated = true;
          } catch (driverError) {
            logger.warn(`⚠️ Gagal membuat driver document untuk UID: ${newUserUid}`, driverError);
            // Tidak gagalkan seluruh proses jika driver document gagal
          }
        }
      }

      // 7. Log audit trail
      await db.collection("admin_actions").add({
        adminUid: callerUid,
        adminEmail: callerDoc.data().email || "",
        adminName: callerDoc.data().name || "",
        action: "create_user",
        targetUserUid: newUserUid,
        targetUserEmail: email,
        targetUserName: name,
        targetUserRole: role,
        isDriverCreated: isDriverCreated,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        success: true,
      });

      logger.info(`✅ User creation completed successfully by admin ${callerUid} for ${email}`);

      return {
        success: true,
        message: `User ${name} berhasil dibuat dengan role ${role}${isDriverCreated ? " (dengan driver capabilities)" : ""}`,
        uid: newUserUid,
        isDriverCreated: isDriverCreated,
      };
    } catch (firestoreError) {
      // Jika Firestore gagal, hapus user dari Auth untuk konsistensi
      logger.error(`❌ Gagal membuat user document, menghapus user dari Auth: ${firestoreError.message}`);

      try {
        await admin.auth().deleteUser(newUserUid);
        logger.info(`🧹 User berhasil dihapus dari Auth setelah kegagalan Firestore`);
      } catch (deleteError) {
        logger.error(`❌ Gagal menghapus user dari Auth: ${deleteError.message}`);
      }

      throw new functions.https.HttpsError("internal", `Gagal membuat user document: ${firestoreError.message}`);
    }
  } catch (error) {
    // Log error untuk debugging
    logger.error(`❌ Error pada createUserByAdmin: ${error.message}`, error);

    // Jika error bukan HttpsError, wrap dalam HttpsError
    if (!(error instanceof functions.https.HttpsError)) {
      throw new functions.https.HttpsError("internal", `Terjadi kesalahan tidak terduga: ${error.message}`);
    }

    // Re-throw HttpsError
    throw error;
  }
});

/**
 * Cloud Function untuk menghapus pengguna dari Firebase Auth dan Firestore.
 * Hanya admin yang bisa memanggil fungsi ini.
 */
exports.deleteUser = onCall({ region: "asia-southeast1" }, async (request) => {
  // 1. Verifikasi bahwa pemanggil fungsi adalah admin.
  const callerUid = request.auth.uid;
  if (!callerUid) {
    logger.error("Fungsi dipanggil oleh pengguna yang tidak terautentikasi.");
    throw new functions.https.HttpsError("unauthenticated", "Fungsi ini harus dipanggil saat Anda login.");
  }

  const callerDoc = await db.collection("users").doc(callerUid).get();
  if (!callerDoc.exists || callerDoc.data().role !== "admin") {
    logger.warn(`Pengguna non-admin (UID: ${callerUid}) mencoba menghapus akun.`);
    throw new functions.https.HttpsError("permission-denied", "Hanya admin yang dapat menghapus pengguna.");
  }

  // 2. Dapatkan UID pengguna yang akan dihapus dari data yang dikirim.
  const uidToDelete = request.data.uid;
  if (!uidToDelete || typeof uidToDelete !== "string") {
    logger.error("Argumen UID tidak valid.", { data: request.data });
    throw new functions.https.HttpsError("invalid-argument", "UID pengguna yang akan dihapus tidak valid.");
  }

  try {
    // 3. Hapus pengguna dari berbagai service secara bersamaan.
    logger.info(`Memulai proses penghapusan untuk UID: ${uidToDelete}`);

    const deleteAuthPromise = admin.auth().deleteUser(uidToDelete);
    const deleteFirestoreUserPromise = db.collection("users").doc(uidToDelete).delete();

    const driverDocRef = db.collection("drivers").doc(uidToDelete);
    const deleteFirestoreDriverPromise = driverDocRef.get().then((doc) => {
      if (doc.exists) {
        logger.info(`Menghapus dokumen driver untuk UID: ${uidToDelete}`);
        return doc.ref.delete();
      }
      return Promise.resolve();
    });

    await Promise.all([deleteAuthPromise, deleteFirestoreUserPromise, deleteFirestoreDriverPromise]);

    logger.info(`✅ Berhasil menghapus pengguna dengan UID: ${uidToDelete}`);
    return { success: true, message: "Pengguna berhasil dihapus." };
  } catch (error) {
    logger.error(`❌ Gagal menghapus pengguna dengan UID: ${uidToDelete}`, error);
    throw new functions.https.HttpsError("internal", `Terjadi kesalahan saat menghapus pengguna: ${error.message}`);
  }
});

/**
 * Cloud Function untuk membuat dokumen driver.
 * Fungsi ini dapat dipanggil oleh admin atau oleh user teknisi untuk dirinya sendiri.
 */
exports.createDriverDocument = onCall({ region: "asia-southeast1" }, async (request) => {
  try {
    // Verifikasi bahwa pengguna sudah login
    if (!request.auth) {
      logger.error("Fungsi dipanggil oleh pengguna yang tidak terautentikasi.");
      throw new functions.https.HttpsError("unauthenticated", "Anda harus login untuk menggunakan fungsi ini.");
    }

    // Ambil parameter yang diperlukan
    const { uid, name, email } = request.data;

    // Validasi parameter
    if (!uid || !name || !email) {
      logger.error("Parameter tidak lengkap.", { data: request.data });
      throw new functions.https.HttpsError("invalid-argument", "Parameter uid, name, dan email harus disediakan.");
    }

    // Periksa apakah pengguna adalah admin atau sedang membuat dokumen untuk dirinya sendiri
    const callerUid = request.auth.uid;
    const isAdmin = await isUserAdmin(callerUid);

    // Validasi izin: harus admin atau diri sendiri
    if (!isAdmin && callerUid !== uid) {
      logger.warn(`Pengguna (UID: ${callerUid}) mencoba membuat driver document untuk user lain (UID: ${uid})`);
      throw new functions.https.HttpsError("permission-denied", "Anda hanya dapat membuat driver document untuk diri sendiri, kecuali Anda adalah admin.");
    }

    // Jika membuat untuk orang lain (sebagai admin), verifikasi bahwa target user adalah teknisi
    if (callerUid !== uid) {
      const targetUserDoc = await db.collection("users").doc(uid).get();
      if (!targetUserDoc.exists || targetUserDoc.data().role !== "technician") {
        logger.warn(`Mencoba membuat driver document untuk non-teknisi: ${uid}`);
        throw new functions.https.HttpsError("failed-precondition", "Hanya user dengan role 'technician' yang dapat memiliki driver document.");
      }
    }

    // Cek apakah dokumen driver sudah ada
    const driverDoc = await db.collection("drivers").doc(uid).get();

    if (driverDoc.exists) {
      // Jika sudah ada, update saja
      logger.info(`Driver document sudah ada untuk ${uid}, melakukan update`);

      await db.collection("drivers").doc(uid).update({
        name: name,
        email: email,
        isAvailable: true,
        status: "active",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        message: "Driver document berhasil diperbarui",
        updated: true,
      };
    } else {
      // Buat dokumen driver baru
      logger.info(`Membuat driver document baru untuk ${uid}`);

      await db.collection("drivers").doc(uid).set({
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        currentVehicleId: null,
        currentVehicleName: null,
        email: email,
        isAvailable: true,
        name: name,
        status: "active",
        uid: uid,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        message: "Driver document berhasil dibuat",
        created: true,
      };
    }
  } catch (error) {
    logger.error(`Error saat membuat driver document: ${error.message}`, error);
    throw new functions.https.HttpsError("internal", `Terjadi kesalahan saat membuat driver document: ${error.message}`);
  }
});

/**
 * Trigger untuk membuat driver document otomatis saat user baru dibuat
 * dengan role 'technician' dan isDriver=true atau nama/email mengandung 'driver'
 */
exports.createDriverOnUserCreation = onDocumentCreated("users/{userId}", async (event) => {
  try {
    const snapshot = event.data;
    if (!snapshot) {
      logger.error("Event tidak memiliki data snapshot.");
      return;
    }

    const userId = event.params.userId;
    const userData = snapshot.data();

    logger.info(`User baru dibuat: ${userId}, role: ${userData.role}`);

    // Hanya proses jika user adalah teknisi
    if (userData.role === "technician") {
      // Cek apakah user adalah driver (berdasarkan flag atau nama/email)
      const isDriverUser = userData.isDriver === true || (userData.name && userData.name.toLowerCase().includes("driver")) || (userData.email && userData.email.toLowerCase().includes("driver"));

      if (isDriverUser) {
        logger.info(`User ${userId} adalah teknisi dan driver, membuat driver document`);

        // Cek apakah dokumen driver sudah ada (untuk keamanan)
        const driverDoc = await db.collection("drivers").doc(userId).get();

        if (!driverDoc.exists) {
          // Buat dokumen driver baru
          await db
            .collection("drivers")
            .doc(userId)
            .set({
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              currentVehicleId: null,
              currentVehicleName: null,
              email: userData.email || "",
              isAvailable: true,
              name: userData.name || "",
              status: "active",
              uid: userId,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

          logger.info(`✅ Driver document berhasil dibuat untuk user ${userId}`);
        } else {
          logger.info(`⚠️ Driver document sudah ada untuk user ${userId}`);
        }
      }
    }
  } catch (error) {
    logger.error(`Error pada trigger createDriverOnUserCreation: ${error.message}`, error);
  }
});

/**
 * Cloud Function (v2) yang dipicu setiap kali rating baru dibuat.
 * Fungsi ini akan menghitung ulang rata-rata rating teknisi berdasarkan data
 * dari SEMUA aplikasi dan memperbarui dokumen di koleksi 'users'.
 */
async function updateTechnicianStats(technicianId) {
  if (!technicianId) {
    logger.log("technicianId tidak diberikan ke fungsi inti.");
    return null;
  }
  logger.log(`Memulai kalkulasi statistik untuk teknisi: ${technicianId}`);

  const resourceRatingsPromise = db.collection("technician_ratings_resource").where("technicianId", "==", technicianId).get();
  const maintenanceRatingsPromise = db.collection("technician_ratings").where("technicianId", "==", technicianId).get();

  const [resourceSnapshot, maintenanceSnapshot] = await Promise.all([resourceRatingsPromise, maintenanceRatingsPromise]);

  const allRatingsDocs = [...resourceSnapshot.docs, ...maintenanceSnapshot.docs];
  const totalRatings = allRatingsDocs.length;

  if (totalRatings === 0) {
    logger.log(`Tidak ada rating ditemukan untuk ${technicianId}. Reset ke 0.`);
    const userRefZero = db.collection("users").doc(technicianId);
    return userRefZero.update({ averageRating: 0, totalRatings: 0 });
  }

  let sumOfRatings = 0;
  allRatingsDocs.forEach((doc) => {
    sumOfRatings += doc.data().rating;
  });
  const averageRating = sumOfRatings / totalRatings;

  const userRef = db.collection("users").doc(technicianId);
  logger.info(`Memperbarui user ${technicianId}: averageRating=${averageRating.toFixed(2)}, totalRatings=${totalRatings}`);

  return userRef.update({
    averageRating: averageRating,
    totalRatings: totalRatings,
  });
}

// Helper function to check if user is admin
async function isUserAdmin(uid) {
  try {
    const userDoc = await db.collection("users").doc(uid).get();
    return userDoc.exists && userDoc.data().role === "admin";
  } catch (error) {
    logger.error(`Error checking admin status: ${error.message}`, error);
    return false;
  }
}

// TRIGGER 1: Untuk aplikasi Resource
exports.aggregateResourceRating = onDocumentCreated("technician_ratings_resource/{ratingId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    logger.error("Event tidak memiliki data snapshot.");
    return;
  }
  const ratingData = snapshot.data();
  try {
    await updateTechnicianStats(ratingData.technicianId);
  } catch (error) {
    logger.error(`Error memicu agregasi dari resourceApp untuk teknisi ${ratingData.technicianId}`, error);
  }
});

// TRIGGER 2: Untuk aplikasi Maintenance
exports.aggregateMaintenanceRating = onDocumentCreated("technician_ratings/{ratingId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    logger.error("Event tidak memiliki data snapshot.");
    return;
  }
  const ratingData = snapshot.data();
  try {
    await updateTechnicianStats(ratingData.technicianId);
  } catch (error) {
    logger.error(`Error memicu agregasi dari maintenanceApp untuk teknisi ${ratingData.technicianId}`, error);
  }
});
/**
 * Cloud Function untuk menghitung ulang rata-rata rating driver
 * berdasarkan semua rating yang diterima
 */
async function updateDriverStats(driverId) {
  if (!driverId) {
    logger.log("driverId tidak diberikan ke fungsi inti.");
    return null;
  }
  logger.log(`Memulai kalkulasi statistik driver untuk: ${driverId}`);

  try {
    // Ambil semua rating untuk driver ini
    const ratingsSnapshot = await db.collection("driver_ratings").where("driverId", "==", driverId).get();
    const totalRatings = ratingsSnapshot.docs.length;

    if (totalRatings === 0) {
      logger.log(`Tidak ada rating ditemukan untuk driver ${driverId}. Reset ke 0.`);
      const driverRef = db.collection("drivers").doc(driverId);
      return driverRef.update({
        averageRating: 0,
        totalRatings: 0,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    let sumOfRatings = 0;
    ratingsSnapshot.docs.forEach((doc) => {
      sumOfRatings += doc.data().rating;
    });
    const averageRating = sumOfRatings / totalRatings;

    const driverRef = db.collection("drivers").doc(driverId);
    logger.info(`Memperbarui driver ${driverId}: averageRating=${averageRating.toFixed(2)}, totalRatings=${totalRatings}`);

    return driverRef.update({
      averageRating: averageRating,
      totalRatings: totalRatings,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    logger.error(`Error updating driver stats for ${driverId}:`, error);
    throw error;
  }
}

/**
 * Cloud Function untuk menghitung ulang rata-rata rating vehicle
 * berdasarkan semua rating yang diterima
 */
async function updateVehicleStats(vehicleId) {
  if (!vehicleId) {
    logger.log("vehicleId tidak diberikan ke fungsi inti.");
    return null;
  }
  logger.log(`Memulai kalkulasi statistik vehicle untuk: ${vehicleId}`);

  try {
    // Ambil semua rating untuk vehicle ini
    const ratingsSnapshot = await db.collection("vehicle_ratings").where("vehicleId", "==", vehicleId).get();
    const totalRatings = ratingsSnapshot.docs.length;

    if (totalRatings === 0) {
      logger.log(`Tidak ada rating ditemukan untuk vehicle ${vehicleId}. Reset ke 0.`);
      const vehicleRef = db.collection("vehicles").doc(vehicleId);
      return vehicleRef.update({
        averageRating: 0,
        totalRatings: 0,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    let sumOfRatings = 0;
    ratingsSnapshot.docs.forEach((doc) => {
      sumOfRatings += doc.data().rating;
    });
    const averageRating = sumOfRatings / totalRatings;

    const vehicleRef = db.collection("vehicles").doc(vehicleId);
    logger.info(`Memperbarui vehicle ${vehicleId}: averageRating=${averageRating.toFixed(2)}, totalRatings=${totalRatings}`);

    return vehicleRef.update({
      averageRating: averageRating,
      totalRatings: totalRatings,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    logger.error(`Error updating vehicle stats for ${vehicleId}:`, error);
    throw error;
  }
}

/**
 * Trigger untuk menghitung ulang rating driver saat rating baru dibuat
 */
exports.aggregateDriverRating = onDocumentCreated("driver_ratings/{ratingId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    logger.error("Event tidak memiliki data snapshot.");
    return;
  }

  const ratingData = snapshot.data();
  try {
    await updateDriverStats(ratingData.driverId);
    logger.info(`✅ Driver stats updated for rating: ${event.params.ratingId}`);
  } catch (error) {
    logger.error(`❌ Error updating driver stats for rating ${event.params.ratingId}:`, error);
  }
});

/**
 * Trigger untuk menghitung ulang rating vehicle saat rating baru dibuat
 */
exports.aggregateVehicleRating = onDocumentCreated("vehicle_ratings/{ratingId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    logger.error("Event tidak memiliki data snapshot.");
    return;
  }

  const ratingData = snapshot.data();
  try {
    await updateVehicleStats(ratingData.vehicleId);
    logger.info(`✅ Vehicle stats updated for rating: ${event.params.ratingId}`);
  } catch (error) {
    logger.error(`❌ Error updating vehicle stats for rating ${event.params.ratingId}:`, error);
  }
});

/**
 * Cloud Function untuk membuat atau memperbarui driver/vehicle secara batch
 * Berguna untuk migrasi data existing atau sync data
 */
exports.syncDriverVehicleRatings = onCall({ region: "asia-southeast1" }, async (request) => {
  try {
    // Verifikasi admin
    if (!request.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Harus login sebagai admin");
    }

    const callerUid = request.auth.uid;
    const callerDoc = await db.collection("users").doc(callerUid).get();
    if (!callerDoc.exists || callerDoc.data().role !== "admin") {
      throw new functions.https.HttpsError("permission-denied", "Hanya admin yang dapat menjalankan sync");
    }

    logger.info(`Admin ${callerUid} memulai sync driver/vehicle ratings`);

    // Sync semua driver ratings
    const driversSnapshot = await db.collection("drivers").get();
    const driverPromises = driversSnapshot.docs.map((doc) => updateDriverStats(doc.id));
    await Promise.all(driverPromises);

    // Sync semua vehicle ratings
    const vehiclesSnapshot = await db.collection("vehicles").get();
    const vehiclePromises = vehiclesSnapshot.docs.map((doc) => updateVehicleStats(doc.id));
    await Promise.all(vehiclePromises);

    logger.info(`✅ Sync completed: ${driversSnapshot.docs.length} drivers, ${vehiclesSnapshot.docs.length} vehicles`);

    return {
      success: true,
      message: `Successfully synced ratings for ${driversSnapshot.docs.length} drivers and ${vehiclesSnapshot.docs.length} vehicles`,
      driversCount: driversSnapshot.docs.length,
      vehiclesCount: vehiclesSnapshot.docs.length,
    };
  } catch (error) {
    logger.error(`❌ Error in syncDriverVehicleRatings:`, error);
    throw new functions.https.HttpsError("internal", `Sync failed: ${error.message}`);
  }
});

/**
 * Cloud Function untuk mendapatkan statistik rating driver
 */
exports.getDriverRatingStats = onCall({ region: "asia-southeast1" }, async (request) => {
  try {
    if (!request.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Harus login");
    }

    const { driverId } = request.data;
    if (!driverId) {
      throw new functions.https.HttpsError("invalid-argument", "driverId diperlukan");
    }

    // Ambil data driver
    const driverDoc = await db.collection("drivers").doc(driverId).get();
    if (!driverDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Driver tidak ditemukan");
    }

    // Ambil rating statistics
    const ratingsSnapshot = await db.collection("driver_ratings").where("driverId", "==", driverId).orderBy("timestamp", "desc").get();

    const reviews = [];
    let totalRating = 0;

    ratingsSnapshot.docs.forEach((doc) => {
      const data = doc.data();
      totalRating += data.rating;

      if (data.review) {
        reviews.push({
          rating: data.rating,
          review: data.review,
          timestamp: data.timestamp,
          requestId: data.requestId,
        });
      }
    });

    const driverData = driverDoc.data();
    const averageRating = ratingsSnapshot.docs.length > 0 ? totalRating / ratingsSnapshot.docs.length : 0;

    return {
      success: true,
      data: {
        driverInfo: {
          name: driverData.name,
          email: driverData.email,
          isAvailable: driverData.isAvailable,
        },
        ratingStats: {
          averageRating: averageRating,
          totalRatings: ratingsSnapshot.docs.length,
          recentReviews: reviews.slice(0, 10), // 10 review terbaru
        },
      },
    };
  } catch (error) {
    logger.error(`Error getting driver stats:`, error);
    throw new functions.https.HttpsError("internal", `Failed to get stats: ${error.message}`);
  }
});

/**
 * Cloud Function untuk mendapatkan statistik rating vehicle
 */
exports.getVehicleRatingStats = onCall({ region: "asia-southeast1" }, async (request) => {
  try {
    if (!request.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Harus login");
    }

    const { vehicleId } = request.data;
    if (!vehicleId) {
      throw new functions.https.HttpsError("invalid-argument", "vehicleId diperlukan");
    }

    // Ambil data vehicle
    const vehicleDoc = await db.collection("vehicles").doc(vehicleId).get();
    if (!vehicleDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Vehicle tidak ditemukan");
    }

    // Ambil rating statistics
    const ratingsSnapshot = await db.collection("vehicle_ratings").where("vehicleId", "==", vehicleId).orderBy("timestamp", "desc").get();

    const reviews = [];
    let totalRating = 0;

    ratingsSnapshot.docs.forEach((doc) => {
      const data = doc.data();
      totalRating += data.rating;

      if (data.review) {
        reviews.push({
          rating: data.rating,
          review: data.review,
          timestamp: data.timestamp,
          requestId: data.requestId,
        });
      }
    });

    const vehicleData = vehicleDoc.data();
    const averageRating = ratingsSnapshot.docs.length > 0 ? totalRating / ratingsSnapshot.docs.length : 0;

    return {
      success: true,
      data: {
        vehicleInfo: {
          model: vehicleData.model,
          licensePlate: vehicleData.licensePlate,
          capacity: vehicleData.capacity,
          isAvailable: vehicleData.isAvailable,
        },
        ratingStats: {
          averageRating: averageRating,
          totalRatings: ratingsSnapshot.docs.length,
          recentReviews: reviews.slice(0, 10), // 10 review terbaru
        },
      },
    };
  } catch (error) {
    logger.error(`Error getting vehicle stats:`, error);
    throw new functions.https.HttpsError("internal", `Failed to get stats: ${error.message}`);
  }
});
/**
 * Cloud Function untuk admin mereset password user secara langsung
 * tanpa memerlukan verifikasi email
 */
exports.resetPasswordByAdmin = onCall({ region: "asia-southeast1" }, async (request) => {
  try {
    // 1. Verifikasi bahwa pengguna sudah login
    if (!request.auth) {
      logger.error("Fungsi dipanggil oleh pengguna yang tidak terautentikasi.");
      throw new functions.https.HttpsError("unauthenticated", "Anda harus login untuk menggunakan fungsi ini.");
    }

    const callerUid = request.auth.uid;

    // 2. Verifikasi bahwa caller adalah admin
    const callerDoc = await db.collection("users").doc(callerUid).get();
    if (!callerDoc.exists || callerDoc.data().role !== "admin") {
      logger.warn(`Pengguna non-admin (UID: ${callerUid}) mencoba mereset password.`);
      throw new functions.https.HttpsError("permission-denied", "Hanya admin yang dapat mereset password pengguna.");
    }

    // 3. Ambil dan validasi parameter
    const { uid, newPassword } = request.data;

    if (!uid || !newPassword) {
      logger.error("Parameter tidak lengkap.", { data: request.data });
      throw new functions.https.HttpsError("invalid-argument", "Parameter uid dan newPassword harus disediakan.");
    }

    // Validasi password
    if (newPassword.length < 6) {
      throw new functions.https.HttpsError("invalid-argument", "Password harus minimal 6 karakter.");
    }

    // 4. Verifikasi bahwa target user exists
    let targetUserDoc;
    try {
      targetUserDoc = await db.collection("users").doc(uid).get();
      if (!targetUserDoc.exists) {
        throw new functions.https.HttpsError("not-found", "User dengan UID tersebut tidak ditemukan.");
      }
    } catch (error) {
      logger.error(`Error mengecek target user: ${error.message}`);
      throw new functions.https.HttpsError("internal", "Gagal memverifikasi target user.");
    }

    const targetUserData = targetUserDoc.data();
    logger.info(`Admin ${callerUid} mereset password untuk user: ${targetUserData.name} (${targetUserData.email})`);

    // 5. Reset password menggunakan Firebase Admin SDK
    try {
      await admin.auth().updateUser(uid, {
        password: newPassword,
      });
      logger.info(`✅ Password berhasil direset untuk UID: ${uid}`);
    } catch (authError) {
      logger.error(`❌ Gagal mereset password: ${authError.message}`);

      // Handle specific auth errors
      if (authError.code === "auth/user-not-found") {
        throw new functions.https.HttpsError("not-found", "User tidak ditemukan dalam sistem autentikasi.");
      } else if (authError.code === "auth/weak-password") {
        throw new functions.https.HttpsError("invalid-argument", "Password terlalu lemah.");
      } else {
        throw new functions.https.HttpsError("internal", `Gagal mereset password: ${authError.message}`);
      }
    }

    // 6. Log audit trail
    try {
      await db.collection("admin_actions").add({
        adminUid: callerUid,
        adminEmail: callerDoc.data().email || "",
        adminName: callerDoc.data().name || "",
        action: "reset_password",
        targetUserUid: uid,
        targetUserEmail: targetUserData.email || "",
        targetUserName: targetUserData.name || "",
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        success: true,
        details: "Password reset by admin without email verification",
      });
    } catch (auditError) {
      logger.warn(`⚠️ Gagal mencatat audit trail: ${auditError.message}`);
      // Tidak gagalkan seluruh proses jika audit gagal
    }

    logger.info(`✅ Password reset completed successfully by admin ${callerUid} for user ${uid}`);

    return {
      success: true,
      message: `Password untuk ${targetUserData.name} berhasil direset`,
      targetUserName: targetUserData.name,
      targetUserEmail: targetUserData.email,
    };
  } catch (error) {
    // Log error untuk debugging
    logger.error(`❌ Error pada resetPasswordByAdmin: ${error.message}`, error);

    // Jika error bukan HttpsError, wrap dalam HttpsError
    if (!(error instanceof functions.https.HttpsError)) {
      throw new functions.https.HttpsError("internal", `Terjadi kesalahan tidak terduga: ${error.message}`);
    }

    // Re-throw HttpsError
    throw error;
  }
});

/**
 * Cloud Function untuk admin mereset password menggunakan email
 * (alternatif jika UID tidak diketahui)
 */
exports.resetPasswordByEmailAdmin = onCall({ region: "asia-southeast1" }, async (request) => {
  try {
    // 1. Verifikasi admin
    if (!request.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Harus login sebagai admin");
    }

    const callerUid = request.auth.uid;
    const callerDoc = await db.collection("users").doc(callerUid).get();
    if (!callerDoc.exists || callerDoc.data().role !== "admin") {
      throw new functions.https.HttpsError("permission-denied", "Hanya admin yang dapat mereset password");
    }

    // 2. Validasi parameter
    const { email, newPassword } = request.data;

    if (!email || !newPassword) {
      throw new functions.https.HttpsError("invalid-argument", "Email dan password baru harus disediakan");
    }

    if (newPassword.length < 6) {
      throw new functions.https.HttpsError("invalid-argument", "Password harus minimal 6 karakter");
    }

    // 3. Cari user berdasarkan email di Firestore
    const userQuery = await db.collection("users").where("email", "==", email).limit(1).get();

    if (userQuery.empty) {
      throw new functions.https.HttpsError("not-found", "User dengan email tersebut tidak ditemukan");
    }

    const userDoc = userQuery.docs[0];
    const userData = userDoc.data();
    const uid = userDoc.id;

    logger.info(`Admin ${callerUid} mereset password untuk user: ${userData.name} (${email}) via email lookup`);

    // 4. Reset password
    try {
      await admin.auth().updateUser(uid, {
        password: newPassword,
      });
      logger.info(`✅ Password berhasil direset untuk email: ${email}`);
    } catch (authError) {
      logger.error(`❌ Gagal mereset password: ${authError.message}`);

      if (authError.code === "auth/user-not-found") {
        throw new functions.https.HttpsError("not-found", "User tidak ditemukan dalam sistem autentikasi");
      } else {
        throw new functions.https.HttpsError("internal", `Gagal mereset password: ${authError.message}`);
      }
    }

    // 5. Log audit trail
    try {
      await db.collection("admin_actions").add({
        adminUid: callerUid,
        adminEmail: callerDoc.data().email || "",
        adminName: callerDoc.data().name || "",
        action: "reset_password_by_email",
        targetUserUid: uid,
        targetUserEmail: email,
        targetUserName: userData.name || "",
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        success: true,
        details: "Password reset by admin using email lookup",
      });
    } catch (auditError) {
      logger.warn(`⚠️ Gagal mencatat audit trail: ${auditError.message}`);
    }

    return {
      success: true,
      message: `Password untuk ${userData.name} (${email}) berhasil direset`,
      targetUserName: userData.name,
      targetUserEmail: email,
      targetUserUid: uid,
    };
  } catch (error) {
    logger.error(`❌ Error pada resetPasswordByEmailAdmin: ${error.message}`, error);

    if (!(error instanceof functions.https.HttpsError)) {
      throw new functions.https.HttpsError("internal", `Terjadi kesalahan: ${error.message}`);
    }

    throw error;
  }
});

/**
 * Fungsi pembantu untuk mengambil token dan mengirim notifikasi.
 * @param {string} userId - ID pengguna penerima.
 * @param {string} title - Judul notifikasi.
 * @param {string} body - Isi pesan notifikasi.
 * @param {object} data - Data tambahan untuk navigasi di aplikasi.
 */
async function sendNotification(userId, title, body, data = {}) {
  if (!userId) {
    logger.warn("Attempted to send notification to a null userId.");
    return;
  }

  try {
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) {
      logger.error(`User document not found for userId: ${userId}`);
      return;
    }

    const notificationData = {
      userId: userId,
      title: title,
      body: body,
      data: data,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    await db.collection("notifications").add(notificationData);
    logger.info(`Notification saved to Firestore for user ${userId}.`);

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) {
      logger.warn(`FCM Token not found for user: ${userId}`);
      return;
    }

    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: data,
      token: fcmToken,
      android: {
        notification: {
          channelId: "masbroapp_channel",
          icon: "logo_masbro",
          sound: "default",
        },
      },
      // Jika nanti butuh untuk iOS
      apns: {
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
    };

    logger.info(`Sending notification to user ${userId} (token: ${fcmToken.substring(0, 10)}...) with title: "${title}"`);
    await admin.messaging().send(message);
    logger.info(`Successfully sent notification to user ${userId}.`);
  } catch (error) {
    logger.error(`Failed to send notification to user ${userId}:`, error);
  }
}

/**
 * Trigger yang berjalan setiap kali dokumen di koleksi 'reports', 'requests',
 * 'ride_requests', atau 'bookings' di-update.
 */
exports.sendStatusUpdateNotifications = onDocumentUpdated("{collectionId}/{docId}", async (event) => {
  try {
    const { collectionId, docId } = event.params;
    const validCollections = ["reports", "requests_resource", "ride_requests", "bookings"];

    if (!validCollections.includes(collectionId)) {
      return null;
    }

    const newData = event.data.after.data();
    const oldData = event.data.before.data();

    // Menambahkan pengecekan untuk memastikan data ada sebelum diproses
    if (!newData || !oldData) {
      logger.error(`Data sebelum atau sesudah update tidak ditemukan untuk ${collectionId}/${docId}`);
      return null;
    }

    // Cek perubahan yang relevan
    const statusChanged = newData.status !== oldData.status;
    const technicianChanged = newData.assignedTechnicianId !== oldData.assignedTechnicianId;
    const driverChanged = newData.driverId !== oldData.driverId;
    const ratingAdded = (newData.technicianRating && !oldData.technicianRating) || (newData.driverRating && !oldData.driverRating) || (newData.rating && !oldData.rating);

    // Jika tidak ada perubahan status, teknisi, atau driver, hentikan fungsi
    if (!statusChanged && !technicianChanged && !driverChanged && !ratingAdded) {
      logger.log(`No relevant changes for ${collectionId}/${docId}. No notification sent.`);
      return null;
    }

    if (technicianChanged || driverChanged) {
      await markOfficerNotificationsAsRead(docId);
    }

    // Jika status berubah menjadi 'completed', tandai notifikasi teknisi/driver sebagai terbaca.
    if (statusChanged && newData.status === "completed") {
      const assigneeId = newData.assignedTechnicianId || newData.driverId;
      if (assigneeId) {
        await markAssigneeNotificationAsRead(docId, assigneeId);
      }
    }

    // Jika user menambahkan rating, tandai notifikasi 'completed' mereka sebagai terbaca.
    if (ratingAdded) {
      const employeeId = newData.employeeId;
      if (employeeId) {
        await markUserNotificationAsRead(docId, employeeId);
      }
    }

    logger.info(`[${collectionId}] Change detected for ${docId}. Processing status update notifications.`);
    // Menambahkan fallback untuk nama agar fungsi tidak crash jika field kosong
    const technicianName = newData.technicianName || "seorang teknisi";
    const driverName = newData.driverName || "seorang driver";
    const employeeName = newData.employeeName || "pengguna";

    // logger.log(`Change detected for ${collectionId}/${docId}. Processing notifications.`);

    if (technicianChanged && oldData.assignedTechnicianId) {
      await clearExistingNotifications(docId, "technician");
    }
    if (driverChanged && oldData.driverId) {
      // Asumsi driver juga memiliki role 'technician' di koleksi 'users'
      await clearExistingNotifications(docId, "technician");
    }

    let title = "";
    const notificationsToSend = [];

    switch (collectionId) {
      case "reports":
        title = `Laporan "${newData.itemName || "Tanpa Nama"}"`;
        if (statusChanged) {
          if (newData.status === "inProgress") {
            notificationsToSend.push({ userId: newData.employeeId, body: `Laporan Anda sedang dikerjakan oleh ${newData.technicianName}.` });
          } else if (newData.status === "completed") {
            notificationsToSend.push({ userId: newData.employeeId, body: `Laporan Anda telah diselesaikan oleh ${newData.technicianName}.` });
          }
        }
        if (technicianChanged && newData.assignedTechnicianId) {
          notificationsToSend.push({ userId: newData.assignedTechnicianId, body: `Anda mendapat tugas baru untuk laporan dari ${newData.employeeName}.` });
        }
        break;

      case "requests_resource":
        title = `Permintaan "${newData.description.substring(0, 20)}..."`;
        if (statusChanged) {
          if (newData.status === "inProgress") {
            notificationsToSend.push({ userId: newData.employeeId, body: `Permintaan Anda sedang diproses oleh ${newData.technicianName}.` });
          } else if (newData.status === "completed") {
            notificationsToSend.push({ userId: newData.employeeId, body: `Permintaan Anda telah diselesaikan oleh ${newData.technicianName}.` });
          }
        }
        if (technicianChanged && newData.assignedTechnicianId) {
          notificationsToSend.push({ userId: newData.assignedTechnicianId, body: `Anda mendapat tugas baru untuk permintaan dari ${newData.employeeName}.` });
        }
        break;

      case "ride_requests":
        title = `Perjalanan dari "${newData.pickupLocation}"`;
        if (statusChanged) {
          if (newData.status === "inProgress") {
            notificationsToSend.push({ userId: newData.employeeId, body: `Perjalanan Anda akan diantar oleh driver ${newData.driverName}.` });
          } else if (newData.status === "completed") {
            notificationsToSend.push({ userId: newData.employeeId, body: `Perjalanan Anda dengan driver ${newData.driverName} telah selesai.` });
          }
        }
        if (driverChanged && newData.driverId) {
          notificationsToSend.push({ userId: newData.driverId, body: `Anda mendapat tugas perjalanan baru dari ${newData.employeeName}.` });
        }
        break;

      case "bookings":
        title = `Booking Ruang "${newData.roomName}"`;
        if (statusChanged) {
          if (newData.status === "approved") {
            notificationsToSend.push({ userId: newData.employeeId, body: `Booking ruangan Anda untuk acara "${newData.eventAgenda}" telah disetujui.` });
          } else if (newData.status === "cancelled") {
            notificationsToSend.push({ userId: newData.employeeId, body: `Booking ruangan Anda untuk acara "${newData.eventAgenda}" telah dibatalkan.` });
          }
        }
        break;
    }

    if (notificationsToSend.length > 0) {
      const promises = notificationsToSend.map((notif) => {
        const dataPayload = {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          collection: collectionId,
          docId: docId,
        };
        return sendNotification(notif.userId, title, notif.body, dataPayload);
      });
      return Promise.all(promises);
    }

    return null;
  } catch (error) {
    logger.error(`❌❌ FATAL ERROR in sendStatusUpdateNotifications for ${event.params.collectionId}/${event.params.docId}:`, error);
    return null;
  }
});

/**
 * FUNGSI Menghapus notifikasi yang sudah ada untuk sebuah tugas.
 * Berguna saat teknisi diganti.
 * @param {string} docId - ID dokumen tugas (laporan, permintaan, dll.).
 * @param {string} roleToClear - Role yang notifikasinya akan dihapus (misal: 'technician').
 */
async function clearExistingNotifications(docId, roleToClear) {
  logger.info(`Clearing existing notifications for docId: ${docId} and role: ${roleToClear}`);
  const notificationsRef = db.collection("notifications");
  const snapshot = await notificationsRef.where("data.docId", "==", docId).get();

  if (snapshot.empty) {
    logger.info("No existing notifications found to clear.");
    return;
  }

  const batch = db.batch();
  let clearedCount = 0;

  for (const doc of snapshot.docs) {
    const notifData = doc.data();
    const userDoc = await db.collection("users").doc(notifData.userId).get();
    if (userDoc.exists && userDoc.data().role === roleToClear) {
      batch.delete(doc.ref);
      clearedCount++;
    }
  }

  if (clearedCount > 0) {
    await batch.commit();
    logger.info(`Successfully cleared ${clearedCount} old notifications.`);
  }
}

/**
 * FUNGSI Mengirim notifikasi ke SEMUA OFFICER saat ada permintaan baru dibuat.
 */
exports.sendNewRequestNotification = onDocumentCreated("{collectionId}/{docId}", async (event) => {
  const { collectionId, docId } = event.params;
  const validCollections = ["reports", "requests_resource", "ride_requests", "bookings"];

  if (!validCollections.includes(collectionId)) {
    return null;
  }

  try {
    const newData = event.data.data();
    if (!newData) {
      logger.error(`[${collectionId}/${docId}] No data found in created document.`);
      return null;
    }

    // Menambahkan fallback jika 'employeeName' kosong untuk mencegah error.
    const employeeName = newData.employeeName || "seorang pengguna";
    logger.info(`[${collectionId}/${docId}] Triggered by ${employeeName}. Starting notification process.`);

    logger.info("--> STEP 1: Querying for users with role 'officer'.");

    const officersSnapshot = await db.collection("users").where("role", "==", "officer").get();

    if (officersSnapshot.empty) {
      logger.warn("--> STEP 2: FAILED. No documents found for officers. Check 'users' collection for documents with role field set to 'officer' (all lowercase).");
      return null;
    }

    // LOGGING JUMLAH DAN DETAIL OFFICER YANG DITEMUKAN
    logger.info(`--> STEP 2: SUCCESS. Found ${officersSnapshot.docs.length} officer user(s).`);
    officersSnapshot.docs.forEach((doc) => {
      logger.info(`     - Found Officer ID: ${doc.id}, Role: ${doc.data().role}`);
    });

    // Siapkan pesan notifikasi
    let title = "Permintaan Baru Diterima";
    let body = `Permintaan baru dari ${newData.employeeName} membutuhkan perhatian Anda.`;

    switch (collectionId) {
      case "reports":
        title = `Laporan Maintenance Baru`;
        body = `Laporan kerusakan "${newData.itemName}" dari ${newData.employeeName}.`;
        break;
      case "requests_resource":
        title = `Permintaan Resource Baru`;
        body = `Permintaan "${newData.request}" dari ${newData.employeeName}.`;
        break;
      case "ride_requests":
        title = `Permintaan Perjalanan Baru`;
        body = `Perjalanan dari "${newData.pickupLocation}" oleh ${newData.employeeName}.`;
        break;
      case "bookings":
        title = `Booking Ruangan Baru`;
        body = `Ruang "${newData.roomName}" dibooking oleh ${newData.employeeName}.`;
        break;
    }

    // 3. Kirim notifikasi ke setiap officer
    const promises = officersSnapshot.docs.map((officerDoc) => {
      const officerId = officerDoc.id;
      const dataPayload = {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        collection: collectionId,
        docId: docId,
      };
      logger.info(`--> STEP 3: Preparing to send notification for doc ${docId} to Officer ID: ${officerId}`);
      return sendNotification(officerId, title, body, dataPayload);
    });
    return Promise.all(promises);
  } catch (error) {
    logger.error(`❌❌ FATAL ERROR in sendNewRequestNotification for ${collectionId}/${docId}:`, error);
    return null;
  }
});

/**
 * Menemukan notifikasi asli yang dikirim ke semua officer terkait sebuah
 * dokumen (laporan/permintaan) dan menandainya sebagai sudah dibaca.
 * @param {string} docId - ID dokumen laporan/permintaan.
 */
async function markOfficerNotificationsAsRead(docId) {
  logger.info(`Marking original officer notifications as read for docId: ${docId}`);
  try {
    // 1. Cari semua notifikasi yang terkait dengan dokumen ini.
    const notificationsRef = db.collection("notifications");
    const snapshot = await notificationsRef.where("data.docId", "==", docId).get();

    if (snapshot.empty) {
      logger.info(`No notifications found for docId ${docId} to mark as read.`);
      return;
    }

    // 2. Filter notifikasi ini untuk menemukan mana yang dikirim ke officer.
    const batch = db.batch();
    let markedCount = 0;

    for (const doc of snapshot.docs) {
      const notifData = doc.data();
      // Cek apakah penerima adalah officer
      const userDoc = await db.collection("users").doc(notifData.userId).get();
      if (userDoc.exists && userDoc.data().role === "officer") {
        // Jika notifikasi belum dibaca, tandai untuk diupdate.
        if (notifData.isRead === false) {
          batch.update(doc.ref, { isRead: true });
          markedCount++;
        }
      }
    }

    // 3. Jalankan update jika ada notifikasi yang ditandai.
    if (markedCount > 0) {
      await batch.commit();
      logger.info(`Successfully marked ${markedCount} officer notifications as read.`);
    }
  } catch (error) {
    logger.error(`Error marking officer notifications as read for docId ${docId}:`, error);
  }
}

/**
 * Menemukan notifikasi "tugas baru" yang dikirim ke teknisi/driver
 * dan menandainya sebagai sudah dibaca.
 * @param {string} docId - ID dokumen tugas.
 * @param {string} assigneeId - ID teknisi atau driver.
 */
async function markAssigneeNotificationAsRead(docId, assigneeId) {
  logger.info(`Marking assignee notification as read for docId: ${docId}, assignee: ${assigneeId}`);
  try {
    const notificationsRef = db.collection("notifications");
    const snapshot = await notificationsRef.where("data.docId", "==", docId).where("userId", "==", assigneeId).where("isRead", "==", false).get();

    if (snapshot.empty) {
      logger.info("No unread assignee notification found to mark as read.");
      return;
    }

    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.update(doc.ref, { isRead: true });
    });
    await batch.commit();
    logger.info(`Successfully marked ${snapshot.docs.length} assignee notifications as read.`);
  } catch (error) {
    logger.error(`Error marking assignee notification as read for docId ${docId}:`, error);
  }
}

/**
 * Menemukan notifikasi "tugas selesai" yang dikirim ke user
 * dan menandainya sebagai sudah dibaca.
 * @param {string} docId - ID dokumen tugas.
 * @param {string} employeeId - ID user/employee.
 */
async function markUserNotificationAsRead(docId, employeeId) {
  logger.info(`Marking user notification as read for docId: ${docId}, user: ${employeeId}`);
  try {
    const notificationsRef = db.collection("notifications");
    const snapshot = await notificationsRef.where("data.docId", "==", docId).where("userId", "==", employeeId).where("isRead", "==", false).get();

    if (snapshot.empty) {
      logger.info("No unread user notification found to mark as read.");
      return;
    }

    const batch = db.batch();
    // Biasanya hanya ada satu notifikasi 'completed' per tugas untuk user.
    snapshot.docs.forEach((doc) => {
      if (doc.data().body.includes("diselesaikan") || doc.data().body.includes("selesai")) {
        batch.update(doc.ref, { isRead: true });
      }
    });
    await batch.commit();
    logger.info(`Successfully marked ${snapshot.docs.length} user notifications as read.`);
  } catch (error) {
    logger.error(`Error marking user notification as read for docId ${docId}:`, error);
  }
}
