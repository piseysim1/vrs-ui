import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vrs_ui/app/controllers/customer_controller.dart';
import 'package:vrs_ui/app/core/utils/image_url.dart';
import 'package:vrs_ui/app/data/models/customer_model.dart';
import 'package:vrs_ui/app/data/providers/file_provider.dart';

class CustomerFormDialog extends StatefulWidget {
  final CustomerModel? customer;
  const CustomerFormDialog({super.key, this.customer});

  @override
  State<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<CustomerFormDialog> {
  static const _primary = Color(0xFF003399);

  final c = Get.find<CustomerController>();
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  Uint8List? pickedBytes;
  String? pickedName;
  bool hidePassword = true;
  bool saving = false;
  bool get isEdit => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final u = widget.customer;
    if (u != null) {
      _fullName.text = u.fullName;
      _username.text = u.username;
      _phone.text = u.phone;
      _email.text = u.email;
    }
  }

  @override
  void dispose() {
    _fullName.dispose();
    _username.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (f == null) return;
    final bytes = await f.readAsBytes();
    setState(() {
      pickedBytes = bytes;
      pickedName = f.name;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => saving = true);

    String? profileUrl = widget.customer?.profile; // keep the old photo
    if (pickedBytes != null) {
      profileUrl = await FileProvider().uploadImage(
        pickedBytes!,
        pickedName ?? 'profile.jpg',
      );
      if (profileUrl == null) {
        if (mounted) setState(() => saving = false);
        Get.snackbar('Error', 'Image upload failed');
        return;
      }
    }

    final ok = await c.saveCustomer(
      id: widget.customer?.id,
      roleId: widget.customer?.roleId,
      fullName: _fullName.text,
      username: _username.text,
      phone: _phone.text,
      email: _email.text,
      password: _password.text,
      profile: profileUrl,
    );

    if (!mounted) return;
    setState(() => saving = false);
    if (ok) Navigator.of(context).pop();
  }

  InputDecoration _dec(String label, {Widget? suffix}) => InputDecoration(
    labelText: label,
    suffixIcon: suffix,
    labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _primary, width: 1.5),
    ),
  );

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  Widget _pair(Widget a, Widget b) => LayoutBuilder(
    builder: (context, box) {
      if (box.maxWidth < 380) {
        return Column(children: [a, const SizedBox(height: 14), b]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: a),
          const SizedBox(width: 14),
          Expanded(child: b),
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _header(),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _avatarPicker(),
                      const SizedBox(height: 20),
                      _pair(
                        TextFormField(
                          controller: _fullName,
                          decoration: _dec('Full name'),
                          validator: _required,
                        ),
                        TextFormField(
                          controller: _username,
                          decoration: _dec('Username'),
                          validator: (v) {
                            final t = (v ?? '').trim();
                            if (t.isEmpty) return 'Required';
                            if (c.usernameExists(t, exceptId: widget.customer?.id)) {
                              return 'Username already taken';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      _pair(
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: _dec('Phone'),
                          validator: _required,
                        ),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _dec('Email'),
                          validator: (v) {
                            final t = (v ?? '').trim();
                            if (t.isEmpty) return 'Required';
                            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(t)) {
                              return 'Invalid email';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      _pair(
                        TextFormField(
                          controller: _password,
                          obscureText: hidePassword,
                          decoration: _dec(
                            isEdit ? 'New password (optional)' : 'Password',
                            suffix: IconButton(
                              icon: Icon(
                                hidePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 18,
                              ),
                              onPressed: () =>
                                  setState(() => hidePassword = !hidePassword),
                            ),
                          ),
                          validator: (v) {
                            final t = v ?? '';
                            if (isEdit && t.isEmpty) return null;
                            return t.length < 6
                                ? 'At least 6 characters'
                                : null;
                          },
                        ),
                        TextFormField(
                          controller: _confirm,
                          obscureText: hidePassword,
                          decoration: _dec('Confirm password'),
                          validator: (v) => v != _password.text
                              ? 'Passwords do not match'
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarPicker() {
    final existing = resolveImageUrl(widget.customer?.profile);
    final hasImage = pickedBytes != null || existing != null;
    return _avatarRow(existing, hasImage);
  }

  Widget _avatarRow(String? existing, bool hasImage) => Row(
    children: [
      InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(40),
        child: CircleAvatar(
          radius: 36,
          backgroundColor: const Color(0xFFEFF6FF),
          backgroundImage: pickedBytes != null
              ? MemoryImage(pickedBytes!)
              : (existing != null ? NetworkImage(existing) : null),
          child: !hasImage
              ? const Icon(Icons.person_add_alt_1_outlined, color: _primary)
              : null,
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile photo (optional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              pickedName ??
                  (hasImage
                      ? 'Click the photo to change it'
                      : 'Click the circle to upload a photo'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 20, 16, 18),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.people_outline, size: 22, color: _primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit customer' : 'Add new customer',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isEdit
                    ? '${widget.customer!.fullName}  •  @${widget.customer!.username}'
                    : 'Create a customer account',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Color(0xFF64748B)),
          splashRadius: 20,
        ),
      ],
    ),
  );

  Widget _footer() => Container(
    color: const Color(0xFFF8FAFC),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: saving ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF64748B),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: saving ? null : _save,
          icon: saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_rounded, size: 18),
          label: Text(isEdit ? 'Save changes' : 'Create customer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    ),
  );
}