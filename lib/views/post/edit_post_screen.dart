import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/translations.dart';
import '../../models/post.dart';
import '../../services/post_service.dart';

class EditPostScreen extends StatefulWidget {
  final Post post;
  const EditPostScreen({super.key, required this.post});
  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _desc;
  late final TextEditingController _origin;
  late final TextEditingController _destination;
  late final TextEditingController _slots;
  late String _type;
  DateTime? _travelDate;
  final List<File> _newImages = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.post;
    _title = TextEditingController(text: p.title);
    _desc = TextEditingController(text: p.description);
    _origin = TextEditingController(text: p.originLocation ?? '');
    _destination = TextEditingController(text: p.destinationLocation ?? '');
    _slots = TextEditingController(text: p.slots?.toString() ?? '');
    _type = p.type;
    _travelDate = p.travelDate;
  }

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
    final files = await ImagePicker().pickMultiImage(imageQuality: 75);
    if (files.isEmpty) return;
    setState(() {
      for (final f in files.take(5 - _newImages.length)) {
        _newImages.add(File(f.path));
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
      await context.read<PostService>().updateFull(
            postId: widget.post.id,
            title: _title.text.trim(),
            description: _desc.text.trim(),
            type: _type,
            originLocation: _origin.text.trim(),
            destinationLocation: _destination.text.trim(),
            travelDate: _travelDate,
            slots: int.tryParse(_slots.text.trim()),
            newImages: _newImages,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(T.of(context, 'post_updated')),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      final msg = e is DioException
          ? context.read<ApiClient>().prettyError(e)
          : T.of(context, 'could_not_update');
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
      appBar: AppBar(title: Text(T.of(context, 'edit_post_title'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _typeBtn('offer', T.of(context, 'im_offering')),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _typeBtn('request', T.of(context, 'im_requesting')),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _title,
                  decoration: InputDecoration(
                    labelText: T.of(context, 'title_label'),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? T.of(context, 'title_required_short')
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _desc,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: T.of(context, 'description_label'),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? T.of(context, 'description_required_short')
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _origin,
                        decoration: InputDecoration(
                          labelText: T.of(context, 'from_label'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _destination,
                        decoration: InputDecoration(
                          labelText: T.of(context, 'to_label'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined,
                      color: AppColors.primary),
                  title: Text(
                    _travelDate == null
                        ? T.of(context, 'pick_a_date')
                        : '${_travelDate!.year}-${_travelDate!.month.toString().padLeft(2, '0')}-${_travelDate!.day.toString().padLeft(2, '0')}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _pickDate,
                ),
                TextFormField(
                  controller: _slots,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: T.of(context, 'slots_label'),
                    helperText: T.of(context, 'slots_hint'),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      T.of(context, 'replace_images'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.add_photo_alternate_outlined,
                          size: 16),
                      label: Text(T.of(context, 'add_label')),
                      onPressed: _pickImages,
                    ),
                  ],
                ),
                if (_newImages.isNotEmpty)
                  SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _newImages
                          .asMap()
                          .entries
                          .map((e) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        e.value,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: () => setState(
                                            () => _newImages.removeAt(e.key)),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(2),
                                          child: const Icon(
                                              Icons.close_rounded,
                                              size: 12,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: Colors.white),
                        )
                      : Text(T.of(context, 'save_changes')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeBtn(String value, String label) {
    final active = _type == value;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: active ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}