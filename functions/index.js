const { onCall } = require("firebase-functions/v2/https");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
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

    const userData = userDoc.data();
    // Coba ambil dari field array 'fcmTokens' yang baru
    const tokens = userData.fcmTokens;
    // Cek juga field 'fcmToken' yang lama untuk jaga-jaga jika ada user dengan app versi lama
    const singleToken = userData.fcmToken;

    // Gabungkan keduanya menjadi satu array token yang valid
    const validTokens = Array.isArray(tokens) ? tokens.filter((t) => t) : [];
    if (singleToken && !validTokens.includes(singleToken)) {
      validTokens.push(singleToken);
    }

    if (validTokens.length === 0) {
      logger.warn(`Tidak ada FCM Token yang valid ditemukan untuk pengguna: ${userId}`);
      return;
    }

    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: data,
      tokens: validTokens,
    };

    logger.info(`Mengirim notifikasi ke ${validTokens.length} perangkat untuk pengguna ${userId}.`);
    // 'sendToDevice' (atau 'sendMulticast') lebih efisien untuk mengirim ke banyak token
    const response = await admin.messaging().sendEachForMulticast(message);

    // Bagian ini sangat penting: Membersihkan token yang sudah tidak valid dari database
    const tokensToRemove = [];
    response.responses.forEach((result, index) => {
      if (!result.success) {
        const error = result.error;
        logger.error(`Gagal mengirim ke token: ${validTokens[index]}`, error);
        // Jika errornya adalah karena token sudah tidak terdaftar, kita tandai untuk dihapus
        if (["messaging/invalid-registration-token", "messaging/registration-token-not-registered"].includes(error.code)) {
          tokensToRemove.push(validTokens[index]);
        }
      }
    });

    // Jika ada token yang perlu dihapus, update dokumen pengguna
    if (tokensToRemove.length > 0) {
      logger.info(`Menghapus ${tokensToRemove.length} token yang tidak valid dari database.`);
      await userDoc.ref.update({
        fcmTokens: admin.firestore.FieldValue.arrayRemove(...tokensToRemove),
      });
    }
  } catch (error) {
    logger.error(`Failed to send notification to user ${userId}:`, error);
  }
}

/**
 * Trigger yang berjalan setiap kali dokumen di koleksi 'reports', 'requests',
 * 'ride_requests', atau 'bookings' di-update.
 */
exports.sendStatusUpdateNotifications = onDocumentUpdated("{collectionId}/{docId}", async (event) => {
  const { collectionId, docId } = event.params;
  const validCollections = ["reports", "requests_resource", "ride_requests", "bookings"];
  if (!validCollections.includes(collectionId)) {
    return null;
  }

  try {
    const newData = event.data.after.data();
    const oldData = event.data.before.data();
    if (!newData || !oldData) {
      logger.error(`[${collectionId}/${docId}] Data update tidak lengkap.`);
      return null;
    }

    const promises = [];
    const dataPayload = {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      collection: collectionId,
      docId: docId,
    };

    // --- Identifikasi Perubahan Spesifik ---
    const statusChanged = newData.status !== oldData.status;

    // Logika deteksi pergantian teknisi/driver
    // Membandingkan UID teknisi/driver dari data lama dan baru.
    const technicianChanged = newData.assignedTechnicianId !== oldData.assignedTechnicianId;
    const driverChanged = newData.driverId !== oldData.driverId;

    let scheduleChanged = false;
    let roomChanged = false;
    if (collectionId === "bookings") {
      const oldStartSeconds = oldData.usageStartDate?._seconds;
      const newStartSeconds = newData.usageStartDate?._seconds;
      const oldEndSeconds = oldData.usageEndDate?._seconds;
      const newEndSeconds = newData.usageEndDate?._seconds;

      if (oldStartSeconds !== newStartSeconds || oldEndSeconds !== newEndSeconds) {
        scheduleChanged = true;
      }
      if (newData.roomName !== oldData.roomName) {
        roomChanged = true;
      }
    }

    if (!statusChanged && !technicianChanged && !driverChanged && !scheduleChanged && !roomChanged) {
      logger.log(`[${collectionId}/${docId}] Tidak ada perubahan relevan. Notifikasi tidak dikirim.`);
      return null;
    }

    // --- LOGIKA INTI ---

    // Menangani pergantian teknisi/driver
    // Logika ini sekarang memeriksa secara spesifik jika ada pergantian.
    if (technicianChanged) {
      // Jika ada teknisi lama, hapus notifikasi miliknya.
      if (oldData.assignedTechnicianId) {
        logger.info(`[${collectionId}/${docId}] Menghapus notifikasi untuk teknisi lama: ${oldData.assignedTechnicianId}`);
        clearExistingNotifications(docId, oldData.assignedTechnicianId);
      }
      // Jika ada teknisi baru, kirim notifikasi tugas baru kepadanya.
      if (newData.assignedTechnicianId) {
        const targetTechnicianId = newData.assignedTechnicianId;
        logger.info(`[${collectionId}/${docId}] Teknisi diganti/baru ditugaskan ke ${targetTechnicianId}. Mengirim notifikasi.`);
        const title = "Tugas Baru Untuk Anda";
        const body = `Anda mendapat tugas baru dari ${newData.employeeName || "seorang pengguna"}.`;
        promises.push(sendNotification(targetTechnicianId, title, body, dataPayload));
        await markOfficerNotificationsAsRead(docId);
      }
    }

    if (driverChanged) {
      // Jika ada driver lama, hapus notifikasi miliknya.
      if (oldData.driverId) {
        logger.info(`[${collectionId}/${docId}] Menghapus notifikasi untuk driver lama: ${oldData.driverId}`);
        clearExistingNotifications(docId, oldData.driverId);
      }
      // Jika ada driver baru, kirim notifikasi tugas baru kepadanya.
      if (newData.driverId) {
        const targetDriverId = newData.driverId;
        logger.info(`[${collectionId}/${docId}] Driver diganti/baru ditugaskan ke ${targetDriverId}. Mengirim notifikasi.`);
        const title = "Tugas Perjalanan Baru";
        const body = `Anda mendapat tugas perjalanan baru dari ${newData.employeeName || "seorang pengguna"}.`;
        promises.push(sendNotification(targetDriverId, title, body, dataPayload));
        await markOfficerNotificationsAsRead(docId);
      }
    }

    // Notifikasi untuk Employee terkait perubahan STATUS
    if (statusChanged && newData.employeeId) {
      const targetEmployeeId = newData.employeeId;
      let title = "";
      let body = "";
      let handlerName = "petugas";

      switch (collectionId) {
        case "reports":
        case "requests_resource":
          title = collectionId === "reports" ? `Update Laporan Maintenance` : `Update Permintaan Resource`;
          if (newData.status === "inProgress") {
            handlerName = newData.technicianName || "petugas";
            body = `Permintaan Anda sedang dikerjakan oleh ${handlerName}.`;
          } else if (newData.status === "completed") {
            handlerName = newData.technicianName || "petugas";
            body = `Permintaan Anda telah diselesaikan oleh ${handlerName}. Silakan beri rating.`;
          }
          break;
        case "ride_requests":
          title = `Update Perjalanan`;
          if (newData.status === "inProgress") {
            handlerName = newData.driverName || "petugas";
            body = `${handlerName} akan menjadi driver Anda dan akan menjemput sesuai waktu yang telah Anda tentukan.`;
          } else if (newData.status === "completed") {
            handlerName = newData.driverName || "petugas";
            body = `Perjalanan Anda dengan ${handlerName} telah selesai. Silakan beri rating.`;
          }
          break;
        case "bookings":
          title = `Update Booking Ruang "${newData.roomName}"`;
          handlerName = newData.officerName || "petugas";
          if (newData.status === "approved") {
            body = `Booking Anda telah disetujui oleh ${handlerName}.`;
          } else if (newData.status === "cancelled") {
            body = `Booking Anda telah ditolak/dibatalkan.`;
          }
          break;
      }

      if (body) {
        logger.info(`[${collectionId}/${docId}] Status berubah menjadi '${newData.status}'. Notifikasi untuk employee ${targetEmployeeId}.`);
        promises.push(sendNotification(targetEmployeeId, title, body, dataPayload));
      }
    }

    // Notifikasi untuk Employee terkait perubahan JADWAL
    if ((scheduleChanged || roomChanged) && newData.employeeId) {
      const targetEmployeeId = newData.employeeId;
      const title = `Update Booking Ruang "${newData.roomName}"`;
      let body = "";

      // Membuat pesan notifikasi yang dinamis
      if (scheduleChanged && roomChanged) {
        body = `Jadwal dan ruangan untuk booking Anda telah diubah. Mohon periksa kembali detailnya.`;
      } else if (scheduleChanged) {
        body = `Jadwal booking Anda telah diubah oleh officer. Mohon periksa kembali detailnya.`;
      } else if (roomChanged) {
        body = `Ruangan untuk booking Anda telah diubah dari "${oldData.roomName}" menjadi "${newData.roomName}".`;
      }

      logger.info(`[${collectionId}/${docId}] Jadwal/Ruangan berubah. Notifikasi untuk employee ${targetEmployeeId}.`);
      promises.push(sendNotification(targetEmployeeId, title, body, dataPayload));
    }

    return Promise.all(promises);
  } catch (error) {
    logger.error(`[FATAL] Gagal di sendStatusUpdateNotifications untuk ${collectionId}/${docId}:`, error);
    return null;
  }
});

/**
 * FUNGSI Menghapus notifikasi yang sudah ada untuk sebuah tugas.
 * Berguna saat teknisi diganti.
 * @param {string} docId - ID dokumen tugas (laporan, permintaan, dll.).
 * @param {string} roleToClear - Role yang notifikasinya akan dihapus (misal: 'technician').
 */
async function clearExistingNotifications(docId, userIdToClear) {
  if (!userIdToClear) return;

  logger.info(`Mencari notifikasi untuk dihapus: docId=${docId}, userId=${userIdToClear}`);
  const notificationsRef = db.collection("notifications");
  // Query spesifik untuk notifikasi tugas terkait PADA PENGGUNA LAMA
  const snapshot = await notificationsRef.where("data.docId", "==", docId).where("userId", "==", userIdToClear).get();

  if (snapshot.empty) {
    logger.info("Tidak ada notifikasi lama yang ditemukan untuk dihapus.");
    return;
  }

  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    logger.info(`Menandai untuk penghapusan notifikasi ID: ${doc.id}`);
    batch.delete(doc.ref);
  });

  await batch.commit();
  logger.info(`Berhasil menghapus ${snapshot.docs.length} notifikasi lama.`);
}

/**
 * FUNGSI Mengirim notifikasi ke SEMUA OFFICER saat ada permintaan baru dibuat.
 * Cek apakah sudah ada penugasan, jika belum baru kirim ke semua officer.
 */
exports.sendNewRequestNotification = onDocumentCreated("{collectionId}/{docId}", async (event) => {
  const { collectionId, docId } = event.params;
  const validCollections = ["reports", "requests_resource", "ride_requests", "bookings"];
  if (!validCollections.includes(collectionId)) {
    return null; // Abaikan koleksi lain
  }

  try {
    const data = event.data.data();
    if (!data) {
      logger.error(`[${collectionId}/${docId}] Dokumen baru tidak memiliki data.`);
      return null;
    }

    const promises = [];
    const dataPayload = {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      collection: collectionId,
      docId: docId,
    };

    const employeeName = data.employeeName || "seorang pengguna";

    // --- LOGIKA INTI  ---
    const targetTechnicianId = data.assignedTechnicianId;
    const targetDriverId = data.driverId;

    if (targetTechnicianId) {
      // KASUS 1A: Laporan/Permintaan dibuat dan LANGSUNG ditugaskan ke Teknisi
      logger.info(`[${collectionId}/${docId}] Dibuat dengan penugasan teknisi ${targetTechnicianId}. Mengirim notifikasi TERTARGET.`);
      const title = "Tugas Baru Untuk Anda";
      const body = `Anda mendapat tugas baru dari ${employeeName}.`;
      promises.push(sendNotification(targetTechnicianId, title, body, dataPayload));
    } else if (targetDriverId) {
      // KASUS 1B: Perjalanan dibuat dan LANGSUNG ditugaskan ke Driver
      logger.info(`[${collectionId}/${docId}] Dibuat dengan penugasan driver ${targetDriverId}. Mengirim notifikasi TERTARGET.`);
      const title = "Tugas Perjalanan Baru";
      const body = `Anda mendapat tugas perjalanan baru dari ${employeeName}.`;
      promises.push(sendNotification(targetDriverId, title, body, dataPayload));
    } else {
      // KASUS 2: Permintaan baru TANPA penugasan. SATU-SATUNYA skenario broadcast.
      logger.info(`[${collectionId}/${docId}] Dibuat tanpa penugasan. Notifikasi akan dikirim ke semua officer.`);
      const officersSnapshot = await db.collection("users").where("role", "==", "officer").get();

      if (officersSnapshot.empty) {
        logger.warn(`[${collectionId}/${docId}] Permintaan baru dibuat, tetapi tidak ada officer yang ditemukan.`);
        return null;
      }

      let title = "Permintaan Baru Diterima";
      let body = `Permintaan dari ${employeeName} memerlukan perhatian Anda.`;

      // Sesuaikan pesan untuk setiap jenis permintaan
      if (collectionId === "reports") {
        title = "Laporan Maintenance Baru";
        body = `Laporan kerusakan aset dari ${employeeName}.`;
      } else if (collectionId === "requests_resource") {
        title = "Permintaan Resource Baru";
        body = `Permintaan "${data.request || "Resource"}" dari ${employeeName}.`;
      } else if (collectionId === "ride_requests") {
        title = "Permintaan Perjalanan Baru";
        body = `Perjalanan dari "${data.pickupLocation}" oleh ${employeeName}.`;
      } else if (collectionId === "bookings") {
        title = "Booking Ruangan Baru";
        body = `Ruang "${data.roomName}" dibooking oleh ${employeeName}.`;
      }

      officersSnapshot.docs.forEach((officerDoc) => {
        const officerId = officerDoc.id;
        logger.info(`--> Menyiapkan notifikasi untuk Officer UID: ${officerId}`);
        promises.push(sendNotification(officerId, title, body, dataPayload));
      });
    }
    return Promise.all(promises);
  } catch (error) {
    logger.error(`[FATAL] Gagal di sendNewRequestNotification untuk ${collectionId}/${docId}:`, error);
    return null;
  }
});

/**
 * Cloud Function yang dijadwalkan berjalan setiap jam.
 * Fungsi ini akan mencari booking yang sudah selesai dalam satu jam terakhir
 * dan mengirimkan notifikasi permintaan rating kepada pemesan.
 */
exports.sendBookingRatingNotifications = onSchedule("every 1 hours", async (event) => {
  try {
    const now = new Date();
    const oneHourAgo = new Date(now.getTime() - 60 * 60 * 1000);

    logger.log(`Menjalankan tugas terjadwal pada: ${now.toISOString()}`);
    logger.log(`Mencari booking yang selesai antara ${oneHourAgo.toISOString()} dan ${now.toISOString()}`);

    // Query untuk mencari booking yang:
    // 1. Statusnya 'approved'.
    // 2. Waktu selesainya (usageEndDate) berada di antara satu jam yang lalu dan sekarang.
    // 3. Belum memiliki rating (rating == null).
    const snapshot = await db.collection("bookings").where("status", "==", "approved").where("usageEndDate", ">=", oneHourAgo).where("usageEndDate", "<=", now).where("rating", "==", null).get();

    if (snapshot.empty) {
      logger.log("Tidak ada booking yang baru selesai dan belum diberi rating. Tugas selesai.");
      return null;
    }

    logger.log(`Ditemukan ${snapshot.docs.length} booking yang memenuhi kriteria.`);

    const promises = snapshot.docs.map((doc) => {
      const bookingData = doc.data();
      const bookingId = doc.id;
      const employeeId = bookingData.employeeId;

      if (!employeeId) {
        logger.warn(`Booking ID ${bookingId} tidak memiliki employeeId.`);
        return Promise.resolve();
      }

      const title = `Bagaimana Pengalaman Anda di Ruang "${bookingData.roomName}"?`;
      const body = `Acara "${bookingData.eventAgenda}" telah selesai. Berikan rating Anda sekarang!`;

      // Payload notifikasi dibuat sedikit berbeda agar bisa diidentifikasi
      // sebagai notifikasi permintaan rating.
      const dataPayload = {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        collection: "bookings",
        docId: bookingId,
        type: "rating_request", // Penanda khusus
      };

      logger.log(`Menyiapkan notifikasi rating untuk booking ID: ${bookingId} kepada user: ${employeeId}`);
      return sendNotification(employeeId, title, body, dataPayload);
    });

    return Promise.all(promises);
  } catch (error) {
    logger.error("Terjadi kesalahan pada sendBookingRatingNotifications:", error);
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
/**
 * Cloud Function untuk mengupdate user termasuk email oleh admin
 * ADDED: Fungsi baru untuk mendukung edit email
 */
exports.updateUserByAdmin = onCall({ region: "asia-southeast1" }, async (request) => {
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
      logger.warn(`Pengguna non-admin (UID: ${callerUid}) mencoba mengupdate user.`);
      throw new functions.https.HttpsError("permission-denied", "Hanya admin yang dapat mengupdate user.");
    }

    // 3. Ambil dan validasi parameter
    const { uid, name, email, role } = request.data;

    if (!uid || !name || !email || !role) {
      logger.error("Parameter tidak lengkap.", { data: request.data });
      throw new functions.https.HttpsError("invalid-argument", "Parameter uid, name, email, dan role harus disediakan.");
    }

    // Validasi email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      throw new functions.https.HttpsError("invalid-argument", "Format email tidak valid.");
    }

    // Validasi role
    const validRoles = ["employee", "officer", "technician", "admin"];
    if (!validRoles.includes(role)) {
      throw new functions.https.HttpsError("invalid-argument", `Role harus salah satu dari: ${validRoles.join(", ")}`);
    }

    // 4. Verifikasi bahwa target user exists
    const targetUserDoc = await db.collection("users").doc(uid).get();
    if (!targetUserDoc.exists) {
      throw new functions.https.HttpsError("not-found", "User dengan UID tersebut tidak ditemukan.");
    }

    const currentUserData = targetUserDoc.data();
    const currentEmail = currentUserData.email;
    const emailChanged = currentEmail !== email;

    logger.info(`Admin ${callerUid} updating user: ${name} (${currentEmail} -> ${email}), role: ${role}`);

    try {
      // 5. Update Firebase Auth jika email berubah
      if (emailChanged) {
        logger.info(`Updating email in Firebase Auth from ${currentEmail} to ${email}`);

        // Check if new email is already in use
        try {
          await admin.auth().getUserByEmail(email);
          // If we get here, email is already in use
          throw new functions.https.HttpsError("already-exists", "Email sudah digunakan oleh user lain.");
        } catch (authError) {
          // If user-not-found, that's good - email is available
          if (authError.code !== "auth/user-not-found") {
            throw authError;
          }
        }

        // Update email in Firebase Auth
        await admin.auth().updateUser(uid, {
          email: email,
          displayName: name,
        });

        logger.info(`✅ Email updated in Firebase Auth for UID: ${uid}`);
      } else {
        // Just update display name if email didn't change
        await admin.auth().updateUser(uid, {
          displayName: name,
        });
        logger.info(`✅ Display name updated in Firebase Auth for UID: ${uid}`);
      }
    } catch (authError) {
      logger.error(`❌ Failed to update Firebase Auth: ${authError.message}`);

      // Handle specific auth errors
      if (authError.code === "auth/user-not-found") {
        throw new functions.https.HttpsError("not-found", "User tidak ditemukan dalam sistem autentikasi.");
      } else if (authError.code === "auth/email-already-exists") {
        throw new functions.https.HttpsError("already-exists", "Email sudah digunakan oleh user lain.");
      } else if (authError.code === "auth/invalid-email") {
        throw new functions.https.HttpsError("invalid-argument", "Format email tidak valid.");
      } else {
        throw new functions.https.HttpsError("internal", `Gagal mengupdate autentikasi: ${authError.message}`);
      }
    }

    try {
      // 6. Update Firestore document
      await db.collection("users").doc(uid).update({
        name: name,
        email: email,
        role: role,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info(`✅ User document updated in Firestore for UID: ${uid}`);

      // 7. Update driver document if exists and email changed
      if (emailChanged) {
        const driverDoc = await db.collection("drivers").doc(uid).get();
        if (driverDoc.exists) {
          await db.collection("drivers").doc(uid).update({
            name: name,
            email: email,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          logger.info(`✅ Driver document email updated for UID: ${uid}`);
        }
      }
    } catch (firestoreError) {
      logger.error(`❌ Failed to update Firestore: ${firestoreError.message}`);

      // If Firestore fails, we might want to revert the Auth changes
      // But for now, we'll just report the error
      throw new functions.https.HttpsError("internal", `Gagal mengupdate database: ${firestoreError.message}`);
    }

    // 8. Log audit trail
    try {
      await db.collection("admin_actions").add({
        adminUid: callerUid,
        adminEmail: callerDoc.data().email || "",
        adminName: callerDoc.data().name || "",
        action: "update_user",
        targetUserUid: uid,
        targetUserEmail: email,
        targetUserName: name,
        targetUserRole: role,
        emailChanged: emailChanged,
        oldEmail: currentEmail,
        newEmail: email,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        success: true,
        details: emailChanged ? "User updated with email change" : "User updated without email change",
      });
    } catch (auditError) {
      logger.warn(`⚠️ Gagal mencatat audit trail: ${auditError.message}`);
      // Tidak gagalkan seluruh proses jika audit gagal
    }

    logger.info(`✅ User update completed successfully by admin ${callerUid} for user ${uid}`);

    return {
      success: true,
      message: emailChanged ? `User ${name} berhasil diupdate dengan email baru: ${email}` : `User ${name} berhasil diupdate`,
      emailChanged: emailChanged,
      oldEmail: currentEmail,
      newEmail: email,
    };
  } catch (error) {
    // Log error untuk debugging
    logger.error(`❌ Error pada updateUserByAdmin: ${error.message}`, error);

    // Jika error bukan HttpsError, wrap dalam HttpsError
    if (!(error instanceof functions.https.HttpsError)) {
      throw new functions.https.HttpsError("internal", `Terjadi kesalahan tidak terduga: ${error.message}`);
    }

    // Re-throw HttpsError
    throw error;
  }
});

/**
 * Cloud Function untuk batch update email untuk multiple users
 * ADDED: Fungsi untuk batch update (opsional)
 */
exports.batchUpdateUserEmails = onCall({ region: "asia-southeast1" }, async (request) => {
  try {
    // 1. Verifikasi admin
    if (!request.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Harus login sebagai admin");
    }

    const callerUid = request.auth.uid;
    const callerDoc = await db.collection("users").doc(callerUid).get();
    if (!callerDoc.exists || callerDoc.data().role !== "admin") {
      throw new functions.https.HttpsError("permission-denied", "Hanya admin yang dapat melakukan batch update");
    }

    // 2. Validasi parameter
    const { updates } = request.data;

    if (!Array.isArray(updates) || updates.length === 0) {
      throw new functions.https.HttpsError("invalid-argument", "Parameter 'updates' harus berupa array yang tidak kosong");
    }

    if (updates.length > 50) {
      throw new functions.https.HttpsError("invalid-argument", "Maksimal 50 updates per batch");
    }

    logger.info(`Admin ${callerUid} starting batch update for ${updates.length} users`);

    const results = [];

    // 3. Process each update
    for (let i = 0; i < updates.length; i++) {
      const update = updates[i];
      const { uid, name, email, role } = update;

      try {
        // Validate each update
        if (!uid || !name || !email || !role) {
          throw new Error("Missing required fields");
        }

        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
          throw new Error("Invalid email format");
        }

        // Update Firebase Auth
        await admin.auth().updateUser(uid, {
          email: email,
          displayName: name,
        });

        // Update Firestore
        await db.collection("users").doc(uid).update({
          name: name,
          email: email,
          role: role,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Update driver document if exists
        const driverDoc = await db.collection("drivers").doc(uid).get();
        if (driverDoc.exists) {
          await db.collection("drivers").doc(uid).update({
            name: name,
            email: email,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }

        results.push({
          uid: uid,
          success: true,
          message: `User ${name} updated successfully`,
        });

        logger.info(`✅ Batch update success for user ${uid}: ${name} (${email})`);
      } catch (error) {
        logger.error(`❌ Batch update failed for user ${uid}: ${error.message}`);

        results.push({
          uid: uid,
          success: false,
          error: error.message,
        });
      }
    }

    // 4. Log audit trail
    try {
      await db.collection("admin_actions").add({
        adminUid: callerUid,
        adminEmail: callerDoc.data().email || "",
        adminName: callerDoc.data().name || "",
        action: "batch_update_users",
        totalUpdates: updates.length,
        successCount: results.filter((r) => r.success).length,
        failureCount: results.filter((r) => !r.success).length,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        success: true,
        details: "Batch update completed",
      });
    } catch (auditError) {
      logger.warn(`⚠️ Gagal mencatat audit trail: ${auditError.message}`);
    }

    const successCount = results.filter((r) => r.success).length;
    const failureCount = results.filter((r) => !r.success).length;

    logger.info(`✅ Batch update completed: ${successCount} success, ${failureCount} failures`);

    return {
      success: true,
      message: `Batch update completed: ${successCount} success, ${failureCount} failures`,
      totalCount: updates.length,
      successCount: successCount,
      failureCount: failureCount,
      results: results,
    };
  } catch (error) {
    logger.error(`❌ Error in batchUpdateUserEmails: ${error.message}`, error);

    if (!(error instanceof functions.https.HttpsError)) {
      throw new functions.https.HttpsError("internal", `Batch update failed: ${error.message}`);
    }

    throw error;
  }
});
