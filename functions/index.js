const { onCall } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");
admin.initializeApp();
const db = admin.firestore();

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
