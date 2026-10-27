import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../controllers/feed_controller.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/translations.dart';
import '../../models/post.dart';
import '../../services/post_service.dart';

class _EditableItem {
  int? id;
  final title = TextEditingController();
  final description = TextEditingController();
  final slots = TextEditingController();
  final List<String> existingImages;
  final List<File> newImages = [];

  _EditableItem({
    this.id,
    String titleText = '',
    String descriptionText = '',
    String slotsText = '',
    List<String> existingImages = const [],
  }) : existingImages = List.from(existingImages) {
    title.text = titleText;
    description.text = descriptionText;
    slots.text = slotsText;
  }

  void dispose() {
    title.dispose();
    description.dispose();
    slots.dispose();
  }
}

class EditPostScreen extends StatefulWidget {
  final Post post;
  const EditPostScreen({super.key, required this.post});
  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _desc;
  late final TextEditingController _origin;
  late final TextEditingController _destination;

  late String _type;
  DateTime? _travelDate;
  final List<_EditableItem> _items = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.post;
    _title = TextEditingController(text: p.title);
    _desc = TextEditingController(text: p.description);
    _origin = TextEditingController(text: p.originLocation ?? '');
    _destination = TextEditingController(text: p.destinationLocation ?? '');
    _type = p.type;
    _travelDate = p.travelDate;

    if (p.items.isEmpty) {
      _items.add(_EditableItem());
    } else {
      for (final it in p.items) {
        _items.add(_EditableItem(
          id: it.id,
          titleText: it.title,
          descriptionText: it.description,
          slotsText: it.slots?.toString() ?? '',
          existingImages: it.images,
        ));
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _origin.dispose();
    _destination.dispose();
    for (final i in _items) {
      i.dispose();
    }
    super.dispose();
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

 Future<void> _pickItemImages(int index) async {
  final files = await ImagePicker().pickMultiImage(
    imageQuality: 75,
    maxWidth: 1600,
    maxHeight: 1600,
  );
  if (files.isEmpty) return;
  final item = _items[index];
  setState(() {
    for (final f in files.take(5 - item.newImages.length)) {
      item.newImages.add(File(f.path));
    }
  });
}

  void _addItem() => setState(() => _items.add(_EditableItem()));

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final payload = _items
          .map((it) => (
                id: it.id,
                title: it.title.text.trim(),
                description: it.description.text.trim(),
                slots: int.tryParse(it.slots.text.trim()),
                newImages: it.newImages,
              ))
          .toList();

      await context.read<PostService>().updateFull(
            postId: widget.post.id,
            title: _title.text.trim(),
            description: _desc.text.trim(),
            type: _type,
            originLocation: _origin.text.trim(),
            destinationLocation: _destination.text.trim(),
            travelDate: _travelDate,
            items: payload,
          );

      if (!mounted) return;

      // ---- Capture references BEFORE popping ----
      final messenger = ScaffoldMessenger.of(context);
      final feedCtrl  = context.read<FeedController>();
      final successMsg = T.read(context, 'post_updated');

      context.pop();

      messenger.showSnackBar(
        SnackBar(
          content: Text(successMsg),
          backgroundColor: AppColors.success,
        ),
      );
      feedCtrl.load();
    } catch (e) {
      if (!mounted) return;
      final msg = e is DioException
          ? context.read<ApiClient>().prettyError(e)
          : T.read(context, 'could_not_update');
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
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Type selector
                Row(
                  children: [
                    Expanded(
                      child: _typeBtn('offer', T.of(context, 'im_offering')),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child:
                          _typeBtn('request', T.of(context, 'im_requesting')),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Header fields — validators use T.read because
                // validate() runs inside _submit, outside build()
                TextFormField(
                  controller: _title,
                  decoration: InputDecoration(
                    labelText: T.of(context, 'title_label'),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? T.read(context, 'title_required_short')
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _desc,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: T.of(context, 'description_label'),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? T.read(context, 'description_required_short')
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
                        : '${_travelDate!.year}-'
                            '${_travelDate!.month.toString().padLeft(2, '0')}-'
                            '${_travelDate!.day.toString().padLeft(2, '0')}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _pickDate,
                ),

                const SizedBox(height: 16),

                Text(
                  'Items (${_items.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                ..._items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  return _EditableItemCard(
                    index: i,
                    item: item,
                    canDelete: _items.length > 1,
                    onDelete: () => _removeItem(i),
                    onPickImages: () => _pickItemImages(i),
                    onRemoveNewImage: (j) =>
                        setState(() => item.newImages.removeAt(j)),
                  );
                }),

                OutlinedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add another item'),
                  onPressed: _addItem,
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
                const SizedBox(height: 32),
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

// ---------------------------------------------------------------------------

class _EditableItemCard extends StatelessWidget {
  final int index;
  final _EditableItem item;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback onPickImages;
  final ValueChanged<int> onRemoveNewImage;

  const _EditableItemCard({
    required this.index,
    required this.item,
    required this.canDelete,
    required this.onDelete,
    required this.onPickImages,
    required this.onRemoveNewImage,
  });

  @override
  Widget build(BuildContext context) {
    final isNew = item.id == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Item ${index + 1}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              if (isNew) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (canDelete)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: AppColors.danger,
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 18,
                ),
            ],
          ),
          const SizedBox(height: 8),

          TextFormField(
            controller: item.title,
            decoration: const InputDecoration(
              labelText: 'Item name',
              hintText: 'e.g. Shiseido serum 50ml',
            ),
            // validators run during validate() inside _submit → use T.read
            validator: (v) => (v == null || v.trim().isEmpty)
                ? T.read(context, 'item_name_required')
                : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: item.description,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Item description',
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? T.read(context, 'item_description_required')
                : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: item.slots,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Slots (optional)',
              helperText: 'How many buyers can you accept for this item?',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              final n = int.tryParse(v.trim());
              if (n == null || n <= 0) {
                return T.read(context, 'slots_error_positive');
              }
              if (n > 999) return T.read(context, 'slots_error_max');
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Existing images (read-only)
          if (item.existingImages.isNotEmpty && item.newImages.isEmpty) ...[
            const Text(
              'Current photos',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 70,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: item.existingImages
                    .map((url) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              url,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 70,
                                height: 70,
                                color: AppColors.borderSoft,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  size: 20,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pick new photos to replace all of these.',
              style: TextStyle(
                fontSize: 10.5,
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 10),
          ],

          // New images (removable)
          if (item.newImages.isNotEmpty) ...[
            Row(
              children: [
                const Text(
                  'New photos',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${item.newImages.length})',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: item.newImages.asMap().entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
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
                            onTap: () => onRemoveNewImage(e.key),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(2),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
          ],

          if (item.newImages.length < 5)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                label: Text(
                  item.existingImages.isNotEmpty || item.newImages.isNotEmpty
                      ? 'Replace photos'
                      : 'Add photos',
                ),
                onPressed: onPickImages,
              ),
            ),
        ],
      ),
    );
  }
}