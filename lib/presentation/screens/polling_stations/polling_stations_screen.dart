import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/auth/auth_state.dart';
import '../admin/add_voting_center_screen.dart';

class PollingStationsScreen extends StatelessWidget {
  const PollingStationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthStateWidget.of(context);
    final bool isAdmin = auth.isLoggedIn && auth.currentUser?.role == 'admin';
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "مراكز الاقتراع",
          style: TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      // Admin-only FAB — navigates to the Add Polling Station form
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddVotingCenterScreen()),
              ),
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text('إضافة مركز',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // Informational Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryContainer.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "خريطة مراكز الاقتراع الوطنية",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "ابحث عن أقرب مركز اقتراع لك وتوجه إليه في يوم الانتخابات للمشاركة.",
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Admin info banner
          if (isAdmin)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withOpacity(0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.primaryContainer.withOpacity(0.25),
                    width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.admin_panel_settings,
                      color: AppColors.primaryContainer, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'وضع المشرف — يمكنك إضافة مراكز اقتراع جديدة عبر زر الإضافة.',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryContainer,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

          const Text(
            "المراكز المتاحة في منطقتك",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
          ),
          const SizedBox(height: 16),

          _buildPollingStationCard(
            context,
            name: "مدرسة طارق بن زياد الوطنية",
            address: "شارع الملك فهد، حي الرياض",
            distance: "تبعد 2.4 كم",
            status: "مفتوح - وقت الانتظار قصير",
            statusColor: Colors.green,
            imagePath: "https://images.unsplash.com/photo-1577968897966-3d4325b36b61?auto=format&fit=crop&q=80&w=400",
          ),
          const SizedBox(height: 16),
          _buildPollingStationCard(
            context,
            name: "مركز الشباب والرياضة",
            address: "طريق الأمير سلطان، المنطقة المركزية",
            distance: "تبعد 4.1 كم",
            status: "مفتوح - وقت الانتظار متوسط",
            statusColor: Colors.orange,
            imagePath: "https://images.unsplash.com/photo-1541829070764-84a7d30dd3f3?auto=format&fit=crop&q=80&w=400",
          ),
          const SizedBox(height: 16),
          _buildPollingStationCard(
            context,
            name: "قاعة المؤتمرات الكبرى",
            address: "الحي الدبلوماسي، بجوار الوزارات",
            distance: "تبعد 6.8 كم",
            status: "مغلق حالياً - يفتح 8:00 صباحاً",
            statusColor: Colors.red,
            imagePath: "https://images.unsplash.com/photo-1517457373958-b7bdd4587205?auto=format&fit=crop&q=80&w=400",
          ),
          const SizedBox(height: 100), // Padding
        ],
      ),
    );
  }

  Widget _buildPollingStationCard(BuildContext context, {
    required String name,
    required String address,
    required String distance,
    required String status,
    required Color statusColor,
    required String imagePath,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map/Location Preview
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              image: DecorationImage(
                image: NetworkImage(imagePath),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                ),
              ),
              padding: const EdgeInsets.all(16),
              alignment: Alignment.bottomRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions_walk, size: 14, color: AppColors.primaryContainer),
                    const SizedBox(width: 4),
                    Text(distance, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF001F3F)),
                      ),
                    ),
                    Icon(Icons.map, color: Colors.grey[400]),
                  ],
                ),
                const SizedBox(height: 8),
                Text(address, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
                    ),
                    const SizedBox(width: 8),
                    Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.navigation, size: 16),
                      label: const Text("الملاحة GPS"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
