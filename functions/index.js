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
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Anda harus login untuk menggunakan fungsi ini."
      );
    }

    const callerUid = request.auth.uid;
    
    // 2. Verifikasi bahwa caller adalah admin
    const callerDoc = await db.collection("users").doc(callerUid).get();
    if (!callerDoc.exists || callerDoc.data().role !== "admin") {
      logger.warn(`Pengguna non-admin (UID: ${callerUid}) mencoba membuat user baru.`);
      throw new functions.https.HttpsError(
        "permission-denied", 
        "Hanya admin yang dapat membuat user baru."
      );
    }

    // 3. Ambil dan validasi parameter
    const { email, password, name, role, isDriver } = request.data;
    
    if (!email || !password || !name || !role) {
      logger.error("Parameter tidak lengkap.", { data: request.data });
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Parameter email, password, name, dan role harus disediakan."
      );
    }

    // Validasi email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Format email tidak valid."
      );
    }

    // Validasi password
    if (password.length < 6) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Password harus minimal 6 karakter."
      );
    }

    // Validasi role
    const validRoles = ['employee', 'officer', 'technician', 'admin'];
    if (!validRoles.includes(role)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `Role harus salah satu dari: ${validRoles.join(', ')}`
      );
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
      if (authError.code === 'auth/email-already-exists') {
        throw new functions.https.HttpsError(
          "already-exists",
          "Email sudah terdaftar dalam sistem."
        );
      } else if (authError.code === 'auth/invalid-email') {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Format email tidak valid."
        );
      } else if (authError.code === 'auth/weak-password') {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Password terlalu lemah."
        );
      } else {
        throw new functions.https.HttpsError(
          "internal",
          `Gagal membuat user: ${authError.message}`
        );
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
      if (role === 'technician' && isDriver === true) {
        userData.isDriver = true;
      }

      await db.collection("users").doc(newUserUid).set(userData);
      logger.info(`✅ User document berhasil dibuat di Firestore untuk UID: ${newUserUid}`);

      // 6. Buat driver document jika diperlukan
      let isDriverCreated = false;
      if (role === 'technician') {
        // Cek apakah user harus jadi driver (berdasarkan flag atau nama/email)
        const shouldBeDriver = isDriver === true || 
                               name.toLowerCase().includes('driver') || 
                               email.toLowerCase().includes('driver');
                               
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
              status: 'active',
              uid: newUserUid,
              updatedAt: admin.firestore.FieldValue.serverTimestamp()
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
        adminEmail: callerDoc.data().email || '',
        adminName: callerDoc.data().name || '',
        action: 'create_user',
        targetUserUid: newUserUid,
        targetUserEmail: email,
        targetUserName: name,
        targetUserRole: role,
        isDriverCreated: isDriverCreated,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        success: true
      });

      logger.info(`✅ User creation completed successfully by admin ${callerUid} for ${email}`);

      return {
        success: true,
        message: `User ${name} berhasil dibuat dengan role ${role}${isDriverCreated ? ' (dengan driver capabilities)' : ''}`,
        uid: newUserUid,
        isDriverCreated: isDriverCreated
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

      throw new functions.https.HttpsError(
        "internal",
        `Gagal membuat user document: ${firestoreError.message}`
      );
    }

  } catch (error) {
    // Log error untuk debugging
    logger.error(`❌ Error pada createUserByAdmin: ${error.message}`, error);
    
    // Jika error bukan HttpsError, wrap dalam HttpsError
    if (!(error instanceof functions.https.HttpsError)) {
      throw new functions.https.HttpsError(
        "internal",
        `Terjadi kesalahan tidak terduga: ${error.message}`
      );
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
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Anda harus login untuk menggunakan fungsi ini."
      );
    }

    // Ambil parameter yang diperlukan
    const { uid, name, email } = request.data;
    
    // Validasi parameter
    if (!uid || !name || !email) {
      logger.error("Parameter tidak lengkap.", { data: request.data });
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Parameter uid, name, dan email harus disediakan."
      );
    }
    
    // Periksa apakah pengguna adalah admin atau sedang membuat dokumen untuk dirinya sendiri
    const callerUid = request.auth.uid;
    const isAdmin = await isUserAdmin(callerUid);
    
    // Validasi izin: harus admin atau diri sendiri
    if (!isAdmin && callerUid !== uid) {
      logger.warn(`Pengguna (UID: ${callerUid}) mencoba membuat driver document untuk user lain (UID: ${uid})`);
      throw new functions.https.HttpsError(
        "permission-denied",
        "Anda hanya dapat membuat driver document untuk diri sendiri, kecuali Anda adalah admin."
      );
    }
    
    // Jika membuat untuk orang lain (sebagai admin), verifikasi bahwa target user adalah teknisi
    if (callerUid !== uid) {
      const targetUserDoc = await db.collection("users").doc(uid).get();
      if (!targetUserDoc.exists || targetUserDoc.data().role !== "technician") {
        logger.warn(`Mencoba membuat driver document untuk non-teknisi: ${uid}`);
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Hanya user dengan role 'technician' yang dapat memiliki driver document."
        );
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
        status: 'active',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      return { 
        success: true, 
        message: "Driver document berhasil diperbarui",
        updated: true
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
        status: 'active',
        uid: uid,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      return { 
        success: true, 
        message: "Driver document berhasil dibuat",
        created: true
      };
    }
  } catch (error) {
    logger.error(`Error saat membuat driver document: ${error.message}`, error);
    throw new functions.https.HttpsError(
      "internal",
      `Terjadi kesalahan saat membuat driver document: ${error.message}`
    );
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
    if (userData.role === 'technician') {
      // Cek apakah user adalah driver (berdasarkan flag atau nama/email)
      const isDriverUser = 
        (userData.isDriver === true) || 
        (userData.name && userData.name.toLowerCase().includes('driver')) ||
        (userData.email && userData.email.toLowerCase().includes('driver'));
      
      if (isDriverUser) {
        logger.info(`User ${userId} adalah teknisi dan driver, membuat driver document`);
        
        // Cek apakah dokumen driver sudah ada (untuk keamanan)
        const driverDoc = await db.collection("drivers").doc(userId).get();
        
        if (!driverDoc.exists) {
          // Buat dokumen driver baru
          await db.collection("drivers").doc(userId).set({
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            currentVehicleId: null,
            currentVehicleName: null,
            email: userData.email || '',
            isAvailable: true,
            name: userData.name || '',
            status: 'active',
            uid: userId,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
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
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
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
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
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
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
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
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
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
    const driverPromises = driversSnapshot.docs.map(doc => updateDriverStats(doc.id));
    await Promise.all(driverPromises);

    // Sync semua vehicle ratings  
    const vehiclesSnapshot = await db.collection("vehicles").get();
    const vehiclePromises = vehiclesSnapshot.docs.map(doc => updateVehicleStats(doc.id));
    await Promise.all(vehiclePromises);

    logger.info(`✅ Sync completed: ${driversSnapshot.docs.length} drivers, ${vehiclesSnapshot.docs.length} vehicles`);

    return {
      success: true,
      message: `Successfully synced ratings for ${driversSnapshot.docs.length} drivers and ${vehiclesSnapshot.docs.length} vehicles`,
      driversCount: driversSnapshot.docs.length,
      vehiclesCount: vehiclesSnapshot.docs.length
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
    const ratingsSnapshot = await db.collection("driver_ratings")
      .where("driverId", "==", driverId)
      .orderBy("timestamp", "desc")
      .get();

    const reviews = [];
    let totalRating = 0;
    
    ratingsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      totalRating += data.rating;
      
      if (data.review) {
        reviews.push({
          rating: data.rating,
          review: data.review,
          timestamp: data.timestamp,
          requestId: data.requestId
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
          isAvailable: driverData.isAvailable
        },
        ratingStats: {
          averageRating: averageRating,
          totalRatings: ratingsSnapshot.docs.length,
          recentReviews: reviews.slice(0, 10) // 10 review terbaru
        }
      }
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
    const ratingsSnapshot = await db.collection("vehicle_ratings")
      .where("vehicleId", "==", vehicleId)
      .orderBy("timestamp", "desc")
      .get();

    const reviews = [];
    let totalRating = 0;
    
    ratingsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      totalRating += data.rating;
      
      if (data.review) {
        reviews.push({
          rating: data.rating,
          review: data.review,
          timestamp: data.timestamp,
          requestId: data.requestId
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
          isAvailable: vehicleData.isAvailable
        },
        ratingStats: {
          averageRating: averageRating,
          totalRatings: ratingsSnapshot.docs.length,
          recentReviews: reviews.slice(0, 10) // 10 review terbaru
        }
      }
    };

  } catch (error) {
    logger.error(`Error getting vehicle stats:`, error);
    throw new functions.https.HttpsError("internal", `Failed to get stats: ${error.message}`);
  }
});