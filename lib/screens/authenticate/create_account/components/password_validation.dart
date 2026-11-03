import 'package:agq_app/content/app_content.dart';
import 'package:flutter/material.dart';

/// Widget to display password validation checks.
class PasswordValidation extends StatelessWidget {
  final String password;

  const PasswordValidation({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildValidationRow(
          AppContent.text(
              'text.screens.authenticate.create_account.components.password_validation.at_least_8_characters_1fe494'),
          password.length >= 8,
        ),
        const SizedBox(height: 16.0),
        _buildValidationRow(
          AppContent.text(
              'text.screens.authenticate.create_account.components.password_validation.1_digit_c2daba'),
          password.contains(RegExp(r'\d')),
        ),
        const SizedBox(height: 16.0),
        _buildValidationRow(
          AppContent.text(
              'text.screens.authenticate.create_account.components.password_validation.1_uppercase_character_e4e706'),
          password.contains(RegExp(r'[A-Z]')),
        ),
        const SizedBox(height: 16.0),
        _buildValidationRow(
          AppContent.text(
              'text.screens.authenticate.create_account.components.password_validation.1_lowercase_character_ea1254'),
          password.contains(RegExp(r'[a-z]')),
        ),
      ],
    );
  }

  /// Builds a validation row with an icon and text.
  Widget _buildValidationRow(String text, bool isValid) => Container(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            Icon(
              isValid ? Icons.check_rounded : Icons.circle_outlined,
              size: 30,
              color: isValid
                  ? const Color.fromARGB(255, 61, 130, 63)
                  : const Color.fromARGB(255, 100, 116, 139),
            ),
            const SizedBox(width: 10.0),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontFamily: 'Titillium Web',
              ),
            ),
          ],
        ),
      );
}
