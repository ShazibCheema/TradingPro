/// Form validation utilities
class AppValidators {
  AppValidators._();

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final trimmed = value.trim().toLowerCase();

    // Basic format check
    final formatRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');
    if (!formatRegex.hasMatch(trimmed)) {
      return 'Enter a valid email address';
    }

    // Block very short local-parts (e.g. a@gmail.com)
    final localPart = trimmed.split('@').first;
    if (localPart.length < 3) {
      return 'Please enter a real email address';
    }

    // Block placeholder/dummy local-parts
    const _blockedLocalParts = {
      'dummy', 'test', 'testing', 'fake', 'fakeuser', 'noreply', 'no-reply',
      'donotreply', 'example', 'sample', 'demo', 'temp', 'temporary',
      'user', 'user1', 'user123', 'abc', 'abcd', 'abcde', 'xyz', 'foo',
      'bar', 'qwerty', 'asdf', 'admin', 'administrator', 'root',
      'null', 'undefined', 'none', 'na', 'noemail',
    };
    if (_blockedLocalParts.contains(localPart)) {
      return 'Please enter your real email address';
    }

    // Block known disposable/throwaway email domains
    final domain = trimmed.split('@').last;
    const _disposableDomains = {
      'mailinator.com', 'guerrillamail.com', 'guerrillamail.net',
      'guerrillamail.org', 'yopmail.com', 'tempmail.com', 'temp-mail.org',
      'throwaway.email', 'dispostable.com', 'trashmail.com', 'trashmail.net',
      'maildrop.cc', 'sharklasers.com', 'spam4.me', 'fakeinbox.com',
      'getairmail.com', 'filzmail.com', 'discard.email', '10minutemail.com',
      'burnermail.io', 'spamgourmet.com', 'mailnull.com', 'spamcero.com',
    };
    if (_disposableDomains.contains(domain)) {
      return 'Disposable email addresses are not allowed';
    }

    return null;
  }


  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Please enter your full name';
    }
    return null;
  }

  static String? positiveAmount(String? value, [String label = 'Amount']) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    final amount = double.tryParse(value.replaceAll(',', ''));
    if (amount == null) {
      return 'Enter a valid amount';
    }
    if (amount <= 0) {
      return '$label must be greater than 0';
    }
    return null;
  }

  static String? withdrawalAmount(
    String? value,
    double availableBalance,
    double minimumWithdrawal,
  ) {
    final baseError = positiveAmount(value);
    if (baseError != null) return baseError;

    final amount = double.parse(value!.replaceAll(',', ''));
    if (amount < minimumWithdrawal) {
      return 'Minimum withdrawal is \$${minimumWithdrawal.toStringAsFixed(2)}';
    }
    if (amount > availableBalance) {
      return 'Insufficient balance';
    }
    return null;
  }

  static String? walletAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Wallet address is required';
    }
    if (value.trim().length < 10) {
      return 'Enter a valid wallet address';
    }
    return null;
  }
}
