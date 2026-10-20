import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../common/app_button.dart';
import '../common/app_textfield.dart';
import '../../controllers/feed_controller.dart';

class ProfileStep1Screen extends StatefulWidget {
  final bool editMode;
  const ProfileStep1Screen({super.key, this.editMode = false});
  @override
  State<ProfileStep1Screen> createState() => _ProfileStep1ScreenState();
}

class _ProfileStep1ScreenState extends State<ProfileStep1Screen> {
  final _form = GlobalKey<FormState>();
  final c = {
    'lastname': TextEditingController(),
    'firstname': TextEditingController(),
    'middlename': TextEditingController(),
    'extname': TextEditingController(),
    'street_purok': TextEditingController(),
    'barangay': TextEditingController(),
    'city_municipality': TextEditingController(),
    'province': TextEditingController(),
    'country': TextEditingController(text: 'Philippines'),
    'zip_code': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();

    if (widget.editMode) {
      // Pre-populate from the existing profile after the first frame,
      // so we can safely read Provider state.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final pc = context.read<ProfileController>();
        // Make sure profile is loaded
        if (pc.profile == null) {
          pc.load().then((_) {
            if (!mounted) return;
            _prefill(pc.profile);
          });
        } else {
          _prefill(pc.profile);
        }
      });
    }
  }

  void _prefill(dynamic p) {
    if (p == null) return;
    setState(() {
      c['lastname']!.text = p.lastname ?? '';
      c['firstname']!.text = p.firstname ?? '';
      c['middlename']!.text = p.middlename ?? '';
      c['extname']!.text = p.extname ?? '';
      c['street_purok']!.text = p.streetPurok ?? '';
      c['barangay']!.text = p.barangay ?? '';
      c['city_municipality']!.text = p.cityMunicipality ?? '';
      c['province']!.text = p.province ?? '';
      c['country']!.text =
          (p.country ?? '').isEmpty ? 'Philippines' : p.country!;
      c['zip_code']!.text = p.zipCode ?? '';
    });
  }

  @override
  void dispose() {
    for (final ctl in c.values) {
      ctl.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final data = c.map((k, v) => MapEntry(k, v.text.trim()));
    final ok = await context.read<ProfileController>().submit(data);
    if (!mounted) return;

    if (ok) {
      await context.read<AuthController>().refreshMe();
      if (!mounted) return;

      // Reload feeds and topbar data
      context.read<FeedController>().load();
      context.read<ProfileController>().load();

      if (widget.editMode) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else {
        context.go('/onboarding/kyc');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(context.read<ProfileController>().error ?? 'Could not save'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pc = context.watch<ProfileController>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(widget.editMode ? 'Edit profile' : 'Profile — Step 1 of 2'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              children: [
                AppTextField(
                  label: 'Last name',
                  controller: c['lastname'],
                  validator: (v) => Validators.required(v, 'Last name'),
                ),
                AppTextField(
                  label: 'First name',
                  controller: c['firstname'],
                  validator: (v) => Validators.required(v, 'First name'),
                ),
                AppTextField(
                  label: 'Middle name (optional)',
                  controller: c['middlename'],
                ),
                AppTextField(
                  label: 'Ext. name (Jr., III — optional)',
                  controller: c['extname'],
                ),
                const Divider(height: 32),
                AppTextField(
                  label: 'Street / Purok',
                  controller: c['street_purok'],
                  validator: (v) => Validators.required(v, 'Street'),
                ),
                AppTextField(
                  label: 'Barangay',
                  controller: c['barangay'],
                  validator: (v) => Validators.required(v, 'Barangay'),
                ),
                AppTextField(
                  label: 'City / Municipality',
                  controller: c['city_municipality'],
                  validator: (v) => Validators.required(v, 'City'),
                ),
                AppTextField(
                  label: 'Province',
                  controller: c['province'],
                  validator: (v) => Validators.required(v, 'Province'),
                ),
                AppTextField(
                  label: 'Country',
                  controller: c['country'],
                  validator: (v) => Validators.required(v, 'Country'),
                ),
                AppTextField(
                  label: 'Zip code',
                  controller: c['zip_code'],
                  keyboardType: TextInputType.number,
                  validator: Validators.zip,
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: widget.editMode ? 'Save changes' : 'Continue',
                  onPressed: _submit,
                  loading: pc.submitting,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
