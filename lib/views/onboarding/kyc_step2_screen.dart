import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/kyc_controller.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../common/app_button.dart';

class KycStep2Screen extends StatefulWidget {
  const KycStep2Screen({super.key});
  @override
  State<KycStep2Screen> createState() => _KycStep2ScreenState();
}

class _KycStep2ScreenState extends State<KycStep2Screen> {
  static const _idTypes = [
    'philsys',
    'passport',
    'drivers_license',
    'umid',
    'sss',
    'prc',
    'voters',
    'postal',
    'senior',
  ];

  String _idType = 'philsys';
  final _idNumber = TextEditingController();
  DateTime? _dateIssued;
  File? _front;
  File? _back;
  bool _termsAccepted = false;

  @override
  void dispose() {
    _idNumber.dispose();
    super.dispose();
  }

  Future<File?> _pick({required ImageSource source}) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
    );
    return picked == null ? null : File(picked.path);
  }

  Future<void> _pickFront() async {
    final f = await _pick(source: ImageSource.camera);
    if (f != null) setState(() => _front = f);
  }

  Future<void> _pickBack() async {
    final f = await _pick(source: ImageSource.camera);
    if (f != null) setState(() => _back = f);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      initialDate: _dateIssued ?? DateTime.now(),
    );
    if (d != null) setState(() => _dateIssued = d);
  }

  Future<void> _openTerms() async {
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _TermsDialog(),
    );
    if (accepted == true) {
      setState(() => _termsAccepted = true);
    }
  }

  Future<void> _submit() async {
    final missing = <String>[];
    if (_front == null) missing.add('front of ID');
    if (_back == null) missing.add('back of ID');
    if (_idNumber.text.trim().isEmpty) missing.add('ID number');
    if (_dateIssued == null) missing.add('date issued');
    if (!_termsAccepted) missing.add('terms & conditions');

    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please complete: ${missing.join(', ')}'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final ok = await context.read<KycController>().submit(
          idType: _idType,
          idNumber: _idNumber.text.trim(),
          dateIssued: _dateIssued!,
          frontPath: _front!.path,
          backPath: _back!.path,
        );

    if (!mounted) return;

    if (ok) {
      await context.read<AuthController>().refreshMe();
      if (mounted) context.go('/onboarding/pending');
    } else {
      final err = context.read<KycController>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Could not submit'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final kc = context.watch<KycController>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('ID Verification — Step 2 of 2')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Government-issued ID',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'We only use this for verification. Your ID is never shown publicly.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),

              // ID Type
              _Label('ID Type'),
              DropdownButtonFormField<String>(
                value: _idType,
                items: _idTypes
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(_prettyId(t)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _idType = v!),
                decoration: const InputDecoration(hintText: 'Select ID type'),
              ),
              const SizedBox(height: 16),

              // ID Number
              _Label('ID Number'),
              TextField(
                controller: _idNumber,
                decoration: const InputDecoration(
                  hintText: 'e.g. 1234-5678-9012',
                ),
              ),
              const SizedBox(height: 16),

              // Date Issued
              _Label('Date Issued'),
              InkWell(
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
                      Text(
                        _dateIssued == null
                            ? 'Select date'
                            : '${_dateIssued!.year}-${_dateIssued!.month.toString().padLeft(2, '0')}-${_dateIssued!.day.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 14,
                          color: _dateIssued == null
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Front image
              _Label('Front of ID'),
              _ImageSlot(
                label: 'Tap to capture front',
                file: _front,
                onTap: _pickFront,
              ),
              const SizedBox(height: 16),

              // Back image
              _Label('Back of ID'),
              _ImageSlot(
                label: 'Tap to capture back',
                file: _back,
                onTap: _pickBack,
              ),
              const SizedBox(height: 24),

              // Terms & conditions checkbox
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _termsAccepted
                        ? AppColors.primary
                        : AppColors.border,
                    width: _termsAccepted ? 1.5 : 1,
                  ),
                ),
                child: CheckboxListTile(
                  value: _termsAccepted,
                  onChanged: (v) {
                    if (v == true) {
                      _openTerms();
                    } else {
                      setState(() => _termsAccepted = false);
                    }
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.primary,
                  title: const Text(
                    'I agree to the Terms & Conditions and consent to '
                    'PasaBuy storing my ID for verification.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  subtitle: GestureDetector(
                    onTap: _openTerms,
                    child: const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Read terms & conditions',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              AppButton(
                label: 'Submit for review',
                onPressed: _submit,
                loading: kc.submitting,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String _prettyId(String t) {
    switch (t) {
      case 'philsys':
        return 'PhilSys National ID';
      case 'passport':
        return 'Passport';
      case 'drivers_license':
        return "Driver's License";
      case 'umid':
        return 'UMID';
      case 'sss':
        return 'SSS ID';
      case 'prc':
        return 'PRC ID';
      case 'voters':
        return "Voter's ID";
      case 'postal':
        return 'Postal ID';
      case 'senior':
        return 'Senior Citizen ID';
      default:
        return t;
    }
  }
}

// ---------------------------------------------------------------------------

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      );
}

class _ImageSlot extends StatelessWidget {
  final String label;
  final File? file;
  final VoidCallback onTap;
  const _ImageSlot({
    required this.label,
    required this.file,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 170,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.borderSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          image: file != null
              ? DecorationImage(image: FileImage(file!), fit: BoxFit.cover)
              : null,
        ),
        child: file == null
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        size: 32, color: AppColors.textSecondary),
                    SizedBox(height: 6),
                    Text('Tap to capture',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Terms & Conditions dialog
// ---------------------------------------------------------------------------

class _TermsDialog extends StatefulWidget {
  const _TermsDialog();
  @override
  State<_TermsDialog> createState() => _TermsDialogState();
}

class _TermsDialogState extends State<_TermsDialog> {
  bool _scrolledToBottom = false;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrolledToBottom) return;
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 20) {
      setState(() => _scrolledToBottom = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.gavel_rounded,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Terms & Conditions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context, false),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable body
            Flexible(
              child: Scrollbar(
                controller: _scroll,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.all(20),
                  child: const _TermsBody(),
                ),
              ),
            ),

            // Bottom hint
            if (!_scrolledToBottom)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: AppColors.primaryGhost,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_downward_rounded,
                        size: 14, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Scroll to read all terms',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            const Divider(height: 1),

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _scrolledToBottom
                          ? () => Navigator.pop(context, true)
                          : null,
                      child: const Text('I Accept'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsBody extends StatelessWidget {
  const _TermsBody();

  @override
  Widget build(BuildContext context) {
    const p = TextStyle(
      fontSize: 13,
      color: AppColors.textPrimary,
      height: 1.7,
    );
    const h = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
      height: 1.5,
    );
    const num = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      color: AppColors.primary,
      height: 1.5,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('1. About this agreement', style: h),
        SizedBox(height: 6),
        Text(
          'By submitting your government-issued ID and using PasaBuy Mo, '
          'Pasaya Mo ("the App"), you agree to the following terms. Please '
          'read carefully before accepting.',
          style: p,
        ),
        SizedBox(height: 18),

        Text('2. Identity Verification', style: h),
        SizedBox(height: 6),
        Text(
          'You agree to submit a valid, unaltered, and current government-issued '
          'ID (front and back). We collect your ID type, ID number, and issue '
          'date strictly for identity verification. Your ID images are stored '
          'securely and are viewable only by PasaBuy administrators for review '
          'purposes. They are never shown publicly to other users.',
          style: p,
        ),
        SizedBox(height: 18),

        Text('3. Data Privacy (RA 10173)', style: h),
        SizedBox(height: 6),
        Text(
          'In compliance with the Philippine Data Privacy Act of 2012 '
          '(Republic Act No. 10173), you have the right to access, correct, '
          'and request the deletion of your personal data. Your ID is retained '
          'for as long as your account is active and up to 30 days after '
          'account deletion, after which it is permanently removed.',
          style: p,
        ),
        SizedBox(height: 18),

        Text('4. Accuracy of Information', style: h),
        SizedBox(height: 6),
        Text(
          'You warrant that all information you provide is true, accurate, and '
          'up to date. Submitting false documents or impersonating another '
          'person is a criminal offense and will result in permanent account '
          'suspension and possible legal action.',
          style: p,
        ),
        SizedBox(height: 18),

        Text('5. Community Conduct', style: h),
        SizedBox(height: 6),
        Text(
          'You agree to transact honestly with other users, disclose any '
          'service fees before a deal is agreed, and resolve disputes in good '
          'faith. Abusive behavior, scams, and off-platform transactions '
          'arranged through the App will be reported and may result in '
          'suspension.',
          style: p,
        ),
        SizedBox(height: 18),

        Text('6. Prohibited Items', style: h),
        SizedBox(height: 6),
        Text(
          'You may not use PasaBuy to transact illegal items, weapons, drugs, '
          'live animals, counterfeit goods, or any item prohibited by customs '
          'regulations. Violating this rule voids our liability and may be '
          'reported to authorities.',
          style: p,
        ),
        SizedBox(height: 18),

        Text('7. Reviews & Reputation', style: h),
        SizedBox(height: 6),
        Text(
          'After a completed deal, both parties may leave a 1–5 star review '
          'with an optional comment. Reviews must be honest and based on the '
          'actual transaction. Fake or abusive reviews will be removed, and '
          'repeat offenders may be suspended.',
          style: p,
        ),
        SizedBox(height: 18),

        Text('8. Account Termination', style: h),
        SizedBox(height: 6),
        Text(
          'You may request account deletion at any time via Settings. '
          'PasaBuy reserves the right to suspend or terminate any account '
          'that violates these terms, without prior notice.',
          style: p,
        ),
        SizedBox(height: 18),

        Text('9. Changes to These Terms', style: h),
        SizedBox(height: 6),
        Text(
          'We may update these terms from time to time. Continued use of the '
          'App after changes means you accept the new terms. We will notify '
          'you of significant changes through the App.',
          style: p,
        ),
        SizedBox(height: 24),

        Text('By tapping "I Accept" below, you confirm that you have read, '
            'understood, and agree to be bound by these Terms & Conditions.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              height: 1.6,
            )),
        SizedBox(height: 8),
      ],
    );
  }
}