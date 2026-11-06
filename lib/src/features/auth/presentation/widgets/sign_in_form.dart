import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../application/auth_controller.dart';

/// Name + optional email form that creates the local session.
class SignInForm extends ConsumerStatefulWidget {
  const SignInForm({super.key});

  @override
  ConsumerState<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isSubmitting = false;
  String? _submitError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      await ref
          .read(authControllerProvider.notifier)
          .signIn(
            displayName: _nameController.text,
            email: _emailController.text,
          );
      // On success the AuthGate swaps the screen out; no navigation needed.
    } on AppException catch (error) {
      if (mounted) setState(() => _submitError = error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            decoration: const InputDecoration(
              labelText: 'Display name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: (value) => (value ?? '').trim().isEmpty
                ? 'Please enter a display name.'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email (optional)',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
            onFieldSubmitted: (_) => _submit(),
          ),
          if (_submitError != null) ...[
            const SizedBox(height: 14),
            Text(
              _submitError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Start chatting'),
          ),
        ],
      ),
    );
  }
}
