const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();

// 모든 함수를 서울 리전(asia-northeast3)에서 실행하도록 설정
const regionalFunctions = functions.region("asia-northeast3");

// 활동 로그를 생성하는 헬퍼 함수
const createActivityLog = async (message, context) => {
  try {
    const userEmail = context.auth?.token?.email || "알 수 없는 사용자";

    // 상세 로그를 추가하여 디버깅에 용이하도록 함
    functions.logger.info("활동 기록 생성", {
      message: message,
      userEmail: userEmail,
    });

    await db.collection("activityLogs").add({
      message: message,
      userEmail: userEmail,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    functions.logger.error("활동 기록 생성 중 오류 발생:", error);
  }
};

// --- 보호소(Shelter) 관련 활동 기록 ---

exports.onShelterCreated = regionalFunctions.firestore
  .document("shelters/{shelterId}")
  .onCreate((snap, context) => {
    const data = snap.data();
    const message = `보호소 "${data.name}"이(가) 생성되었습니다.`;
    return createActivityLog(message, context);
  });

exports.onShelterUpdated = regionalFunctions.firestore
  .document("shelters/{shelterId}")
  .onUpdate((change, context) => {
    const before = change.before.data();
    const message = `보호소 "${before.name}"의 정보가 수정되었습니다.`;
    return createActivityLog(message, context);
  });

exports.onShelterDeleted = regionalFunctions.firestore
  .document("shelters/{shelterId}")
  .onDelete((snap, context) => {
    const data = snap.data();
    const message = `보호소 "${data.name}"이(가) 삭제되었습니다.`;
    return createActivityLog(message, context);
  });

// --- 동물(Animal) 관련 활동 기록 ---

exports.onAnimalCreated = regionalFunctions.firestore
  .document("shelters/{shelterId}/animals/{animalId}")
  .onCreate((snap, context) => {
    const data = snap.data();
    const message = `동물 "${data.name}"이(가) 등록되었습니다.`;
    return createActivityLog(message, context);
  });

exports.onAnimalUpdated = regionalFunctions.firestore
  .document("shelters/{shelterId}/animals/{animalId}")
  .onUpdate((change, context) => {
    const before = change.before.data();
    const message = `동물 "${before.name}"의 정보가 수정되었습니다.`;
    return createActivityLog(message, context);
  });

exports.onAnimalDeleted = regionalFunctions.firestore
  .document("shelters/{shelterId}/animals/{animalId}")
  .onDelete((snap, context) => {
    const data = snap.data();
    const message = `동물 "${data.name}"이(가) 삭제되었습니다.`;
    return createActivityLog(message, context);
  });
