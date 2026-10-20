class Validators {
  static String? email(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    final ok = RegExp(r'^[\w\.\-]+@[\w\-]+(\.[\w\-]+)+$').hasMatch(v);
    return ok ? null : 'Enter a valid email';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'At least 8 characters';
    return null;
  }

  static String? required(String? v, [String label = 'This field']) =>
      (v == null || v.trim().isEmpty) ? '$label is required' : null;

  static String? zip(String? v) {
    if (v == null || v.isEmpty) return 'Zip code is required';
    return RegExp(r'^\d{3,10}$').hasMatch(v) ? null : 'Invalid zip code';
  }
}