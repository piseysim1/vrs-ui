import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vrs_ui/app/controllers/profile_controller.dart';
import 'package:vrs_ui/app/core/utils/auth_service.dart';
import 'package:vrs_ui/app/data/models/booking_model.dart';
import 'package:vrs_ui/app/ui/pages/home/home_widget/navbar.dart';
import 'package:vrs_ui/app/ui/pages/home/home_widget/navbar_widget.dart';
import 'package:vrs_ui/app/ui/pages/profile/widget/user_avatar.dart';

class ProfilePage extends GetView<ProfileController> {
  const ProfilePage({super.key});

  static const _primary = Color(0xFF0F172A); // Deep slate blue
  static const _accent = Color(0xFF2563EB); // Modern royal blue
  static const _bg = Color(0xFFF8FAFC); // Clean neutral background
  static const _surface = Colors.white;
  static const _border = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: _bg,
      appBar: const NavbarWidget(),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator(color: _accent));
        }

        if (controller.user.value == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_circle_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Profile details not found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _primary,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: controller.load,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: narrow ? 16 : 32,
            vertical: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderBanner(context, narrow),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, c) {
                      final wide = c.maxWidth >= 850;
                      final left = _buildQuickActionsCard();
                      final right = _buildDetailsCard();

                      if (!wide) {
                        return Column(
                          children: [right, const SizedBox(height: 20), left],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: right),
                          const SizedBox(width: 24),
                          SizedBox(width: 340, child: left),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ---------------- Cover Banner + Avatar Header ----------------
  // ---------------- Cover Banner + Avatar Header ----------------
  Widget _buildHeaderBanner(BuildContext context, bool narrow) {
    final u = controller.user.value!;
    final name = '${u['fullName'] ?? u['username']}';
    final role = '${u['roleName'] ?? ''}';

    // Get current user avatar URL
    final serverUrl = u['profile']?.toString();
    final avatarUrl = (serverUrl != null && serverUrl.isNotEmpty)
        ? serverUrl
        : (AuthService.avatar.value ?? AuthService.savedAvatar);

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Cover Image Banner
          Container(
            height: 300,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Cover Image: Uses avatar URL or a sleek dark cover image
                if (avatarUrl != null && avatarUrl.isNotEmpty)
                  Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildDefaultCover(),
                  )
                else
                  _buildDefaultCover(),

                // Dark Overlay Gradient for professional contrast
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.black.withOpacity(0.1),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Profile Details Bar (Avatar + Name)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Overlaid Avatar
                Transform.translate(
                  offset: const Offset(0, -32),
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: _surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: UserAvatar(
                          url: avatarUrl,
                          name: name,
                          radius: 48,
                        ),
                      ),
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Material(
                          color: _accent,
                          shape: const CircleBorder(),
                          elevation: 3,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _pickAvatar,
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Name & Metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '@${u['username']}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          if (role.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                role.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _accent,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Fallback dark cover if no image is available
  Widget _buildDefaultCover() {
    return Container(
      color: const Color(0xFF1E293B),
      child: const Center(
        child: Icon(Icons.image_outlined, color: Colors.white24, size: 48),
      ),
    );
  }

  // ---------------- Main Form / Details Card ----------------
  Widget _buildDetailsCard() {
    return _card(
      child: Obx(() {
        final edit = controller.editing.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _primary,
                  ),
                ),
                if (!edit)
                  OutlinedButton.icon(
                    onPressed: () => controller.editing.value = true,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit Profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primary,
                      side: const BorderSide(color: _border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, c) {
                final isSingleColumn = c.maxWidth < 550;
                final fieldWidth = isSingleColumn
                    ? c.maxWidth
                    : (c.maxWidth - 16) / 2;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: fieldWidth,
                      child: _field(
                        'Full Name',
                        controller.fullName,
                        edit,
                        Icons.person_outline,
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: _field(
                        'Phone Number',
                        controller.phone,
                        edit,
                        Icons.phone_outlined,
                        type: TextInputType.phone,
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: _field(
                        'Email Address',
                        controller.email,
                        edit,
                        Icons.email_outlined,
                        type: TextInputType.emailAddress,
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: _readOnly(
                        'Username',
                        '${controller.user.value!['username']}',
                        Icons.alternate_email,
                      ),
                    ),
                  ],
                );
              },
            ),
            if (edit) ...[
              const SizedBox(height: 24),
              const Divider(color: _border),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: controller.saving.value
                        ? null
                        : controller.cancelEdit,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: controller.saving.value
                        ? null
                        : () => controller.save(),
                    icon: controller.saving.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: const Text('Save Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      }),
    );
  }

  // ---------------- Quick Actions & Stats Card ----------------
  Widget _buildQuickActionsCard() {
    return Column(
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Activity Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                ),
              ),
              const SizedBox(height: 16),
              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: _statTile(
                        '${controller.bookings.length}',
                        'Total Bookings',
                        Icons.calendar_today_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statTile(
                        '${controller.bookings.where((b) => b.approval == Approval.approved).length}',
                        'Approved',
                        Icons.check_circle_outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _card(
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Get.toNamed('/booking-history'),
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('Booking History'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: _border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: controller.logout,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Log Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: BorderSide(color: Colors.red.shade200),
                    backgroundColor: Colors.red.shade50.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- UI Helpers ----------------
  Widget _statTile(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: _accent),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _primary,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController c,
    bool edit,
    IconData icon, {
    TextInputType? type,
  }) {
    return TextField(
      controller: c,
      enabled: edit,
      keyboardType: type,
      style: const TextStyle(fontSize: 14, color: _primary),
      decoration: _dec(label, icon, filled: !edit),
    );
  }

  Widget _readOnly(String label, String value, IconData icon) => TextField(
    controller: TextEditingController(text: value),
    enabled: false,
    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
    decoration: _dec(label, icon, filled: true),
  );

  InputDecoration _dec(String label, IconData icon, {required bool filled}) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade600),
        isDense: true,
        filled: true,
        fillColor: filled ? _bg : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _border),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      );

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );

  Future<void> _pickAvatar() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (f == null) return;
    final bytes = await f.readAsBytes();

    // Max 5 MB check
    if (bytes.length > 5 * 1024 * 1024) {
      Get.snackbar('File too large', 'Maximum size is 5 MB');
      return;
    }
    await controller.uploadAvatar(bytes, f.name);
  }
}
