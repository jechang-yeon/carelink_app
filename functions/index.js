// Cloud Functions v2 및 Firebase Admin SDK의 최신 모듈을 가져옵니다.
const {onDocumentCreated, onDocumentUpdated, onDocumentDeleted} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const logger = require("firebase-functions/logger");

// Firebase Admin SDK를 초기화합니다.
initializeApp();
const db = getFirestore();

/**
 * Firestore에 활동 기록을 생성하는 헬퍼 함수
 * @param {string} message 로그 메시지
 * @param {object} event 함수를 트리거한 이벤트 객체
 * @return {Promise} 로그가 기록될 때 완료되는 Promise
 */
const createActivityLog = (message, event) => {
  // 활동을 유발한 사용자의 이메일을 가져옵니다.
  const userEmail = event.auth?.token.email || "알 수 없는 사용자";

  // Firebase 콘솔의 Logs에서 확인할 수 있도록 로그를 남깁니다.
  logger.info(`활동 기록 by ${userEmail}: ${message}`);

  // 'activityLogs' 컬렉션에 새 문서를 추가합니다.
  return db.collection("activityLogs").add({
    message: message,
    userEmail: userEmail,
    timestamp: new Date(), // v2에서는 new Date()를 사용하는 것이 일반적입니다.
  });
};

// --- 보호소(Shelter) 관련 트리거 ---

exports.onShelterCreated = onDocumentCreated({
  document: "shelters/{shelterId}",
  region: "asia-northeast3",
}, (event) => {
  const data = event.data.data();
  const message = `보호소 "${data.name}"이(가) 생성되었습니다.`;
  return createActivityLog(message, event);
});

exports.onShelterUpdated = onDocumentUpdated({
  document: "shelters/{shelterId}",
  region: "asia-northeast3",
}, (event) => {
  const beforeData = event.data.before.data();
  const message = `보호소 "${beforeData.name}"의 정보가 수정되었습니다.`;
  return createActivityLog(message, event);
});

exports.onShelterDeleted = onDocumentDeleted({
  document: "shelters/{shelterId}",
  region: "asia-northeast3",
}, (event) => {
  const deletedData = event.data.data();
  const message = `보호소 "${deletedData.name}"이(가) 삭제되었습니다.`;
  // 참고: 실제 앱에서는 여기에 연쇄 삭제 로직을 추가해야 합니다.
  return createActivityLog(message, event);
});


// --- 동물(Animal) 관련 트리거 ---

exports.onAnimalCreated = onDocumentCreated({
  document: "shelters/{shelterId}/animals/{animalId}",
  region: "asia-northeast3",
}, (event) => {
  const data = event.data.data();
  const message = `동물 "${data.name}"이(가) 등록되었습니다.`;
  return createActivityLog(message, event);
});

exports.onAnimalUpdated = onDocumentUpdated({
  document: "shelters/{shelterId}/animals/{animalId}",
  region: "asia-northeast3",
}, (event) => {
  const beforeData = event.data.before.data();
  const message = `동물 "${beforeData.name}"의 정보가 수정되었습니다.`;
  return createActivityLog(message, event);
});

exports.onAnimalDeleted = onDocumentDeleted({
  document: "shelters/{shelterId}/animals/{animalId}",
  region: "asia-northeast3",
}, (event) => {
  const deletedData = event.data.data();
  const message = `동물 "${deletedData.name}"이(가) 삭제되었습니다.`;
  return createActivityLog(message, event);
});