import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/translations.dart';
import '../../services/post_service.dart';

class PostFormScreen extends StatefulWidget {
  final String initialType;
  const PostFormScreen({super.key, this.initialType = 'offer'});
  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _origin = TextEditingController();
  final _destination = TextEditingController();
  final _slots = TextEditingController();

  late String _type = widget.initialType;
  DateTime? _travelDate;
  final List<File> _images = [];
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _origin.dispose();
    _destination.dispose();
    _slots.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 75);
    if (files.isEmpty) return;
    setState(() {
      for (final f in files.take(5 - _images.length)) {
        _images.add(File(f.path));
      }
    });
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _travelDate ?? DateTime.now().add(const Duration(days: 7)),
    );
    if (d != null) setState(() => _travelDate = d);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final service = context.read<PostService>();
      await service.create(
        title: _title.text.trim(),
        description: _desc.text.trim(),
        type: _type,
        originLocation: _origin.text.trim(),
        destinationLocation: _destination.text.trim(),
        travelDate: _travelDate,
        slots: int.tryParse(_slots.text.trim()),
        images: _images,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(T.of(context, 'post_published')),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      String msg = T.of(context, 'failed_to_publish');
      if (e is DioException) {
        msg = context.read<ApiClient>().prettyError(e);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(T.of(context, 'new_pasabuy')),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ---- Type selector ----
                Row(
                  children: [
                    Expanded(
                      child: _TypeChip(
                        label: T.of(context, 'im_offering'),
                        sub: T.of(context, 'im_offering_sub'),
                        icon: Icons.flight_takeoff_rounded,
                        selected: _type == 'offer',
                        color: AppColors.primary,
                        onTap: () => setState(() => _type = 'offer'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TypeChip(
                        label: T.of(context, 'im_requesting'),
                        sub: T.of(context, 'im_requesting_sub'),
                        icon: Icons.shopping_cart_outlined,
                        selected: _type == 'request',
                        color: AppColors.accent,
                        onTap: () => setState(() => _type = 'request'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _Field(
                  label: T.of(context, 'title_label'),
                  child: TextFormField(
                    controller: _title,
                    maxLength: 80,
                    decoration: InputDecoration(
                      hintText: T.of(context, 'title_hint'),
                      counterText: '',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? T.of(context, 'title_required')
                        : null,
                  ),
                ),

                _Field(
                  label: T.of(context, 'description_label'),
                  child: TextFormField(
                    controller: _desc,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: T.of(context, 'description_hint'),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? T.of(context, 'description_required')
                        : null,
                  ),
                ),

                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        label: T.of(context, 'from_label'),
                        child: TextFormField(
                          controller: _origin,
                          decoration: InputDecoration(
                            hintText: T.of(context, 'from_hint'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Field(
                        label: T.of(context, 'to_label'),
                        child: TextFormField(
                          controller: _destination,
                          decoration: InputDecoration(
                            hintText: T.of(context, 'to_hint'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // ---- Travel date picker ----
                _Field(
                  label: T.of(context, 'travel_deadline_label'),
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 15),
                      decoration: BoxDecoration(
                        color: AppColors.borderSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _travelDate == null
                                  ? T.of(context, 'pick_date')
                                  : '${_travelDate!.year}-${_travelDate!.month.toString().padLeft(2, '0')}-${_travelDate!.day.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 14,
                                color: _travelDate == null
                                    ? AppColors.textMuted
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ---- Slots ----
                _Field(
                  label: T.of(context, 'slots_label'),
                  child: TextFormField(
                    controller: _slots,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: T.of(context, 'slots_hint'),
                      helperText: T.of(context, 'slots_helper'),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final n = int.tryParse(v.trim());
                      if (n == null || n <= 0) {
                        return T.of(context, 'slots_error_positive');
                      }
                      if (n > 999) return T.of(context, 'slots_error_max');
                      return null;
                    },
                  ),
                ),

                // ---- Photos ----
                _Field(
                  label: T.of(context, 'photos_label'),
                  child: SizedBox(
                    height: 90,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ..._images.asMap().entries.map((e) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      e.value,
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: GestureDetector(
                                      onTap: () => setState(
                                          () => _images.removeAt(e.key)),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(3),
                                        child: const Icon(Icons.close_rounded,
                                            size: 12, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        if (_images.length < 5)
                          GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: AppColors.borderSoft,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                      Icons.add_photo_alternate_outlined,
                                      color: AppColors.textSecondary),
                                  const SizedBox(height: 4),
                                  Text(
                                    T.of(context, 'add_photo'),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
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

                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: Colors.white),
                        )
                      : Text(T.of(context, 'publish_pasabuy')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _TypeChip extends StatelessWidget {
  final String label;
  final String sub;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _TypeChip({
    required this.label,
    required this.sub,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: selected ? color : AppColors.textMuted),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? color : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final Widget child;
  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}