const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

// ============================================
// 1. Send push notification to all voters
//    when a new notification is added
// ============================================
exports.sendNotification = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const data = event.data.data();
    const title = data.title || "DigiVote";
    const message = data.message || "";

    const votersSnapshot = await getFirestore()
      .collection("voters")
      .where("fcm_token", "!=", "")
      .get();

    const tokens = [];
    votersSnapshot.forEach((doc) => {
      const token = doc.data().fcm_token;
      if (token) tokens.push(token);
    });

    if (tokens.length === 0) {
      console.log("No tokens found");
      return null;
    }

    const response = await getMessaging().sendEachForMulticast({
      tokens: tokens,
      notification: {
        title: title,
        body: message,
      },
      data: {
        title: title,
        body: message,
      },
    });

    console.log("Sent to " + response.successCount + " devices");
    return null;
  },
);

// ============================================
// 2. Election reminder - runs daily at 9 AM
//    sends reminders 3, 2, 1, 0 days before
// ============================================
exports.electionReminder = onSchedule("every day 09:00", async (event) => {
  const electionDoc = await getFirestore()
    .collection("elections_info")
    .doc("current_election")
    .get();

  if (!electionDoc.exists) return null;

  const data = electionDoc.data();
  const electionDate = new Date(
    data.election_date + "T" + (data.start_time || "08:00"),
  );
  const now = new Date();

  const diffTime = electionDate.getTime() - now.getTime();
  const daysLeft = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

  let title = "";
  let message = "";

  if (daysLeft === 3) {
    title = "باقي 3 أيام على الانتخابات!";
    message = "استعدوا للتصويت. تأكدوا من معرفة مركز الاقتراع الأقرب إليكم.";
  } else if (daysLeft === 2) {
    title = "باقي يومين على الانتخابات!";
    message = "لا تنسوا التصويت. صوتكم مهم لمستقبل بلدكم.";
  } else if (daysLeft === 1) {
    title = "غداً يوم الانتخابات!";
    message = "غداً هو اليوم الموعود. جهزوا أنفسكم للتصويت.";

    await getFirestore()
      .collection("notifications")
      .add({
        title: "تعليمات يوم الانتخابات 📋",
        message:
          "أعزاءنا الناخبين، إليكم تعليمات يوم الانتخابات:\n\n" +
          "١. توجهوا إلى مركز الاقتراع الأقرب إليكم المحدد في التطبيق.\n" +
          "٢. أحضروا بطاقة الهوية الشخصية معكم.\n" +
          "٣. عند الوصول، توجهوا إلى بوث التصويت الذكي.\n" +
          "٤. سيتم التعرف على وجهكم تلقائياً عبر الكاميرا.\n" +
          "٥. بعد التحقق، سيُفتح باب البوث لكم تلقائياً.\n" +
          "٦. اختاروا المرشح الذي ترغبون بالتصويت له.\n" +
          "٧. اضغطوا زر التأكيد الأخضر لتأكيد صوتكم.\n" +
          "٨. انتظروا حتى يُفتح باب الخروج.\n\n" +
          "ساعات التصويت: من الساعة ٨ صباحاً حتى ٧ مساءً.\n" +
          "تصويتكم سري وآمن بالكامل.\n" +
          "استخدموا خاصية أقرب مركز في التطبيق لتحديد موقعكم.\n\n" +
          "صوتكم أمانة — استخدموه بحكمة!",
        timestamp: new Date(),
        auto: true,
      });
  } else if (daysLeft === 0) {
    title = "اليوم يوم الانتخابات!";
    message = "أبواب مراكز الاقتراع مفتوحة. توجهوا الآن للتصويت!";
  } else {
    return null;
  }

  await getFirestore().collection("notifications").add({
    title: title,
    message: message,
    timestamp: new Date(),
    auto: true,
  });

  console.log("Reminder sent: " + title);
  return null;
});

// ============================================
// 3. New candidate notification
// ============================================
exports.onNewCandidate = onDocumentCreated(
  "candidates/{candidateId}",
  async (event) => {
    const data = event.data.data();
    const name = data.name || "مرشح جديد";

    await getFirestore()
      .collection("notifications")
      .add({
        title: "مرشح جديد!",
        message:
          "تمت إضافة المرشح " +
          name +
          " — تصفح ملفه الشخصي وبرنامجه الانتخابي الآن.",
        timestamp: new Date(),
        auto: true,
      });

    console.log("New candidate notification: " + name);
    return null;
  },
);

// ============================================
// 4. New voting center notification
// ============================================
exports.onNewVotingCenter = onDocumentCreated(
  "voting_center/{centerId}",
  async (event) => {
    const data = event.data.data();
    const centerName = data.center_name || "مركز جديد";
    const city = data.city || "";

    await getFirestore()
      .collection("notifications")
      .add({
        title: "مركز اقتراع جديد!",
        message:
          "تمت إضافة مركز " +
          centerName +
          (city ? " في " + city : "") +
          " — اكتشف موقعه على الخريطة.",
        timestamp: new Date(),
        auto: true,
      });

    console.log("New voting center notification: " + centerName);
    return null;
  },
);
