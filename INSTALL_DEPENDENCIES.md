# Installing Flutter Dependencies

## Quick Fix for StateProvider Error

If you're seeing the error:
```
The function 'StateProvider' isn't defined.
```

**Solution**: Run the following command in the project root:

```bash
cd lab_corrections/secure_ecommerce_flutter
flutter pub get
```

This will install all dependencies including `flutter_riverpod` which exports `StateProvider`.

## Verification

After running `flutter pub get`, verify the installation:

```bash
flutter pub deps
```

You should see `flutter_riverpod` in the dependency tree.

## If Error Persists

1. **Clean and reinstall**:
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Check Flutter version**:
   ```bash
   flutter --version
   ```
   Ensure you're using Flutter SDK 3.9.0 or higher.

3. **Verify pubspec.yaml**:
   Ensure `flutter_riverpod: ^3.0.3` is listed in dependencies.

4. **Restart IDE**:
   Sometimes IDEs need a restart to recognize newly installed packages.

## Code Verification

The code in `lib/core/providers/auth_providers.dart` is **correct**. The import:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
```

And usage:
```dart
final currentUserProvider = StateProvider<User?>((ref) => null);
```

Are both correct for Riverpod 3.0.3. The error is purely due to packages not being installed.

