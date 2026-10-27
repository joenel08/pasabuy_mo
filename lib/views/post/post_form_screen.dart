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
import '../../services/post_service.dart';
import '../../services/transaction_service.dart';

class _ItemForm {
  final title = TextEditingController();
  final description = TextEditingController();
  final slots = TextEditingController();
  final List<File> images = [];

  void dispose() {
    title.dispose();
    description.dispose();
    slots.dispose();
  }
}

class PostFormScreen extends StatefulWidget {
  final String initialType;
  const PostFormScreen({super.key, this.initialType = 'offer'});
  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _origin = TextEditingController();
  final _destination = TextEditingController();

  late String _type = widget.initialType;
  DateTime? _travelDate;
  final List<_ItemForm> _items = [_ItemForm()];
  bool _saving = false;

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

  Future<void> _pickItemImages(int index) async {
    final files = await ImagePicker().pickMultiImage(
      imageQuality: 75,
      maxWidth: 1600, // ← forces resize → re-encode to JPEG
      maxHeight: 1600, // ← same
    );
    if (files.isEmpty) return;
    setState(() {
      for (final f in files.take(5 - _items[index].images.length)) {
        _items[index].images.add(File(f.path));
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

  void _addItem() => setState(() => _items.add(_ItemForm()));

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
// Quick pre-check — fetch fees and warn early if blocked
    try {
      final fees = await context.read<TransactionService>().myFees();
      if (fees.isBlocked && mounted) {
        final go = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Account on hold'),
            content: Text(
              '${fees.blockReason ?? 'You have outstanding fees.'}\n\n'
              'Settle ₱${fees.unpaidTotal.toStringAsFixed(2)} before posting new items.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('View fees'),
              ),
            ],
          ),
        );
        if (go == true && mounted) context.push('/fees');
        return;
      }
    } catch (_) {
      // If the check fails, let the backend decide — don't block on network hiccups
    }

    setState(() => _saving = true);
    try {
      final payload = _items
          .map((it) => (
                title: it.title.text.trim(),
                description: it.description.text.trim(),
                slots: int.tryParse(it.slots.text.trim()),
                images: it.images,
              ))
          .toList();

      await context.read<PostService>().create(
            title: _title.text.trim(),
            description: _desc.text.trim(),
            type: _type,
            originLocation: _origin.text.trim(),
            destinationLocation: _destination.text.trim(),
            travelDate: _travelDate,
            items: payload,
          );

      if (!mounted) return;

      // ---- Capture references BEFORE pop ----
      final messenger = ScaffoldMessenger.of(context);
      final feedCtrl = context.read<FeedController>();
      final successMsg = T.read(context, 'post_published');

      // ---- Pop back to feed ----
      context.pop();

      // ---- Show success + refresh feed ----
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
          : T.read(context, 'failed_to_publish');
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
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Type selector
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
                    // Validators run OUTSIDE build → must use T.read
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? T.read(context, 'title_required')
                        : null,
                  ),
                ),

                _Field(
                  label: T.of(context, 'description_label'),
                  child: TextFormField(
                    controller: _desc,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: T.of(context, 'description_hint'),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? T.read(context, 'description_required')
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

                // Items section
                const SizedBox(height: 8),
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
                  return _ItemFormCard(
                    index: i,
                    item: item,
                    canDelete: _items.length > 1,
                    onDelete: () => _removeItem(i),
                    onPickImages: () => _pickItemImages(i),
                    onRemoveImage: (j) =>
                        setState(() => item.images.removeAt(j)),
                  );
                }),

                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add another item'),
                  onPressed: _addItem,
                ),

                const SizedBox(height: 16),
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

class _ItemFormCard extends StatelessWidget {
  final int index;
  final _ItemForm item;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback onPickImages;
  final ValueChanged<int> onRemoveImage;

  const _ItemFormCard({
    required this.index,
    required this.item,
    required this.canDelete,
    required this.onDelete,
    required this.onPickImages,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
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
            // Validators must use context.read → use T.read
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
              hintText: 'Details, size, color…',
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
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...item.images.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(e.value,
                                width: 80, height: 80, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () => onRemoveImage(e.key),
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
                if (item.images.length < 5)
                  GestureDetector(
                    onTap: onPickImages,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.borderSoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              color: AppColors.textSecondary, size: 18),
                          SizedBox(height: 2),
                          Text('Add',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
