import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "الإشعارات",
          style: TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildNotificationItem(
            icon: Icons.campaign,
            title: "تحديثات الحملات الانتخابية",
            description: "قائمة المستقبل أضافت ندوة جديدة يوم الخميس القادم.",
            time: "منذ ساعتين",
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildNotificationItem(
            icon: Icons.event,
            title: "تذكير بموعد الانتخابات",
            description: "تبقى 3 أيام على بدء التصويت لاختيار ممثليك.",
            time: "منذ 5 ساعات",
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildNotificationItem(
            icon: Icons.announcement,
            title: "إعلان هام",
            description: "تم تحديث أماكن مراكز الاقتراع. يرجى مراجعة الدليل.",
            time: "الأمس",
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          _buildNotificationItem(
            icon: Icons.person_add,
            title: "مرشح جديد",
            description: "تم اعتماد ترشح الأستاذ محمود علي في الدائرة الثانية.",
            time: "الأمس",
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required String title,
    required String description,
    required String time,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
