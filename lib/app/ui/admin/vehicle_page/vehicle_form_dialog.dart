import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vrs_ui/app/controllers/admin_controller.dart';
import 'package:vrs_ui/app/core/utils/auth_service.dart';
import 'package:vrs_ui/app/core/utils/image_url.dart';
import 'package:vrs_ui/app/data/models/option_item.dart';
import 'package:vrs_ui/app/data/models/vehicle_model.dart';
import 'package:vrs_ui/app/data/providers/file_provider.dart';

class VehicleFormDialog extends StatefulWidget {
  final VehicleModel? vehicle;
  const VehicleFormDialog({super.key, this.vehicle});

  @override
  State<VehicleFormDialog> createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends State<VehicleFormDialog> {
  static const _primary = Color(0xFF003399);

  final ctrl = Get.find<AdminController>();
  final _formKey = GlobalKey<FormState>();
  final _plate = TextEditingController();
  final _model = TextEditingController();
  final _day = TextEditingController();
  final _hour = TextEditingController();
  final _modelFocus = FocusNode();

  int? brandId, locationId, colorId, statusId;
  String? imageUrl;
  Uint8List? pickedBytes;
  String? pickedName;
  bool saving = false;
  bool get isEdit => widget.vehicle != null;

  int? get _existingModelId => ctrl.models
      .firstWhereOrNull(
        (m) => m.name.toLowerCase() == _model.text.trim().toLowerCase(),
      )
      ?.id;

  bool get _isNewModel =>
      _model.text.trim().isNotEmpty && _existingModelId == null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    if (v != null) {
      _plate.text = v.licensePlate;
      _model.text = v.modelName;
      brandId = v.brandId;
      locationId = v.locationId;
      colorId = v.colorId;
      statusId = v.statusId;
      imageUrl = v.imageUrl;
      _day.text = _fmt(v.dayPrice);
      _hour.text = _fmt(v.hourPrice);
    }
  }

  @override
  void dispose() {
    _plate.dispose();
    _model.dispose();
    _day.dispose();
    _hour.dispose();
    _modelFocus.dispose();
    super.dispose();
  }

  String _fmt(double? p) => (p == null || p <= 0) ? '' : p.toStringAsFixed(2);

  void _syncRates() {
    final mid = _existingModelId;
    if (mid == null) return;
    _day.text = _fmt(ctrl.findRate(mid, kDayRateType)?.price);
    _hour.text = _fmt(ctrl.findRate(mid, kHourRateType)?.price);
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

    if (pickedBytes != null) {
      final url = await FileProvider().uploadImage(
        pickedBytes!,
        pickedName ?? 'vehicle.jpg',
      );
      if (url == null) {
        if (mounted) setState(() => saving = false);
        Get.snackbar('Error', 'Image upload failed');
        return;
      }
      imageUrl = url;
    }

    final ok = await ctrl.saveVehicle(
      id: widget.vehicle?.id,
      modelName: _model.text.trim(),
      body: {
        'licensePlate': _plate.text.trim(),
        'brandId': brandId,
        'locationId': locationId,
        'colorId': colorId ?? 0,
        'statusId': statusId,
        'imageUrl': imageUrl,
      },
      dayPrice: double.tryParse(_day.text.trim()),
      hourPrice: double.tryParse(_hour.text.trim()),
    );

    if (!mounted) return;
    setState(() => saving = false);
    if (ok) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final yes = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete vehicle?'),
        content: Text(
          '${widget.vehicle!.displayName} (${widget.vehicle!.licensePlate}) will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (yes != true) return;

    setState(() => saving = true);
    final ok = await ctrl.removeVehicle(widget.vehicle!.id!);
    if (!mounted) return;
    setState(() => saving = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 780),
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
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final wide = c.maxWidth >= 640;
                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 260, child: _imagePanel()),
                            const SizedBox(width: 28),
                            Expanded(child: _fields()),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          _imagePanel(),
                          const SizedBox(height: 24),
                          _fields(),
                        ],
                      );
                    },
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
          child: const Icon(
            Icons.directions_car_rounded,
            size: 22,
            color: _primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit Vehicle' : 'Add New Vehicle',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isEdit
                    ? '${widget.vehicle!.displayName}  •  ${widget.vehicle!.licensePlate}'
                    : 'Enter vehicle details and dynamic pricing rates',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: Get.back,
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (isEdit && AuthService.can('vehicle.delete'))
          OutlinedButton.icon(
            onPressed: saving ? null : _delete,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(color: Color(0xFFFCA5A5)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          )
        else
          const SizedBox.shrink(),
        Row(
          children: [
            TextButton(
              onPressed: saving ? null : Get.back,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
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
              label: Text(isEdit ? 'Save Changes' : 'Create Vehicle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _imagePanel() {
    final existing = resolveImageUrl(imageUrl);
    Widget img;
    if (pickedBytes != null) {
      img = Image.memory(pickedBytes!, fit: BoxFit.cover);
    } else if (existing != null) {
      img = Image.network(
        existing,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imgEmpty(),
      );
    } else {
      img = _imgEmpty();
    }

    final hasImage = pickedBytes != null || existing != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('VEHICLE IMAGE'),
        InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFCBD5E1),
                style: hasImage ? BorderStyle.solid : BorderStyle.none,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    img,
                    if (hasImage)
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Change',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (pickedName != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.attach_file,
                  size: 14,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    pickedName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _imgEmpty() => Container(
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.cloud_upload_outlined,
            size: 28,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Click to upload photo',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'PNG, JPG up to 10MB',
          style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
        ),
      ],
    ),
  );

  Widget _fields() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label('BASIC INFO'),
      _pair(
        TextFormField(
          controller: _plate,
          decoration: _dec('License Plate'),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        _dd(
          'Color',
          ctrl.colors,
          colorId,
          (v) => setState(() => colorId = v),
          required: false,
        ),
      ),
      const SizedBox(height: 14),
      _pair(
        _dd('Brand', ctrl.brands, brandId, (v) => setState(() => brandId = v)),
        _modelField(),
      ),
      const SizedBox(height: 22),
      _label('PRICING RATES'),
      _pair(
        _priceField(_day, 'Daily Rate', '/ day'),
        _priceField(_hour, 'Hourly Rate', '/ hour'),
      ),
      const Padding(
        padding: EdgeInsets.only(top: 6),
        child: Text(
          'Rates apply to every vehicle assigned to this model.',
          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ),
      const SizedBox(height: 22),
      _label('LOCATION & STATUS'),
      _pair(
        _dd(
          'Operational Status',
          ctrl.statuses,
          statusId,
          (v) => setState(() => statusId = v),
        ),
        _dd(
          'Hub Location',
          ctrl.locations,
          locationId,
          (v) => setState(() => locationId = v),
        ),
      ),
    ],
  );

  Widget _priceField(TextEditingController c, String label, String suffix) =>
      TextFormField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: _dec(label).copyWith(prefixText: '\$ ', suffixText: suffix),
        validator: (v) {
          final t = (v ?? '').trim();
          if (t.isEmpty) return null;
          return double.tryParse(t) == null ? 'Invalid price' : null;
        },
      );

  Widget _modelField() {
    return LayoutBuilder(
      builder: (context, box) {
        return RawAutocomplete<OptionItem>(
          textEditingController: _model,
          focusNode: _modelFocus,
          displayStringForOption: (o) => o.name,
          optionsBuilder: (value) {
            final q = value.text.trim().toLowerCase();
            return ctrl.models.where(
              (m) => q.isEmpty || m.name.toLowerCase().contains(q),
            );
          },
          onSelected: (_) => setState(_syncRates),
          fieldViewBuilder: (context, textCtrl, focus, onSubmit) {
            return TextFormField(
              controller: textCtrl,
              focusNode: focus,
              onChanged: (_) => setState(() {}),
              decoration: _dec('Model').copyWith(
                hintText: 'Select or type model',
                helperText: _isNewModel ? 'New model will be created' : null,
                helperStyle: const TextStyle(color: Color(0xFF10B981)),
                suffixIcon: const Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFF64748B),
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            );
          },
          optionsViewBuilder: (context, onSelected, options) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: box.maxWidth,
                  maxHeight: 200,
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, i) {
                    final o = options.elementAt(i);
                    return ListTile(
                      dense: true,
                      title: Text(o.name, style: const TextStyle(fontSize: 13)),
                      onTap: () => onSelected(o),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: Color(0xFF475569),
      ),
    ),
  );

  Widget _pair(Widget a, Widget b) => LayoutBuilder(
    builder: (context, c) {
      if (c.maxWidth < 380) {
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

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
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

  Widget _dd(
    String label,
    List<OptionItem> items,
    int? value,
    ValueChanged<int?> onChanged, {
    bool required = true,
  }) {
    final safe = items.any((e) => e.id == value) ? value : null;
    return DropdownButtonFormField<int>(
      value: safe,
      isExpanded: true,
      decoration: _dec(label),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e.id,
              child: Text(
                e.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (v) =>
          (required && items.isNotEmpty && v == null) ? 'Required' : null,
    );
  }
}
