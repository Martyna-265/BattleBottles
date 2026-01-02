import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart' hide Image;
import '../../screens/FriendsScreen.dart';
import '../../services/AuthService.dart';
import '../../screens/BattleShipsGame.dart';

class DropdownOption extends PositionComponent with TapCallbacks {
  final String text;
  final VoidCallback onTapAction;

  DropdownOption(this.text, this.onTapAction)
      : super(size: Vector2(120, 30));

  final _bgPaint = Paint()..color = const Color(0xFF004488);
  final _hoverPaint = Paint()..color = const Color(0xFF0055AA);
  final bool _isHovered = false;

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _isHovered ? _hoverPaint : _bgPaint);
    TextPaint(
      style: const TextStyle(fontSize: 14, color: Color(0xFFFFFFFF)),
    ).render(canvas, text, Vector2(size.x / 2, size.y / 2), anchor: Anchor.center);
  }

  @override
  void onTapDown(TapDownEvent event) {
    onTapAction();
    event.handled = true;
  }
}

class AccountDropdown extends PositionComponent with HasGameReference<BattleShipsGame>, TapCallbacks {

  bool _isExpanded = false;
  late TextComponent _label;
  final AuthService _auth = AuthService();

  AccountDropdown() : super(size: Vector2(120, 30));

  final _bgPaint = Paint()..color = const Color(0xFF003366);

  @override
  Future<void> onLoad() async {
    _auth.authStateChanges.listen((user) {
      String labelText = 'My Account';
      if (user != null) {
        labelText = user.displayName != null && user.displayName!.isNotEmpty
            ? user.displayName!
            : (user.email ?? 'User');
      }

      _updateLabel(labelText);

      if (_isExpanded) _toggleMenu();
    });

    _label = TextComponent(
      text: 'Sign in',
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 12, color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold),
      ),
    )
      ..anchor = Anchor.center
      ..position = size / 2;

    add(_label);
  }

  void _updateLabel(String text) {
    if (text.length > 15) text = '${text.substring(0, 12)}...';
    _label.text = text;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _bgPaint);
  }

  @override
  void onTapDown(TapDownEvent event) {
    _toggleMenu();
    event.handled = true;
  }

  void _toggleMenu() {
    _isExpanded = !_isExpanded;
    removeAll(children.whereType<DropdownOption>());

    if (_isExpanded) {
      final user = _auth.currentUser;

      if (user == null) {
        // NOT LOGGED IN
        add(DropdownOption('Login', () {
          _toggleMenu();
          if (game.buildContext != null) {
            showAuthDialog(
                context: game.buildContext!,
                isRegister: false,
                onSubmit: (email, pass, username) async {
                  await _auth.login(email, pass);
                }
            );
          }
        })..position = Vector2(0, 30));

        // REGISTER Option
        add(DropdownOption('Register', () {
          _toggleMenu();
          if (game.buildContext != null) {
            showAuthDialog(
                context: game.buildContext!,
                isRegister: true,
                onSubmit: (email, pass, username) async {
                  await _auth.register(email, pass, username ?? 'Player');

                  final updatedUser = _auth.currentUser;
                  if (updatedUser != null) {
                    String labelText = updatedUser.displayName ?? updatedUser.email ?? 'User';
                    _updateLabel(labelText);
                  }
                }
            );
          }
        })..position = Vector2(0, 60));

      } else {
        // LOGGED IN
        add(DropdownOption('Friends', () {
          _toggleMenu(); // Zamknij dropdown
          if (game.buildContext != null) {
            // Pokaż FriendsScreen jako Dialog/Overlay
            showDialog(
              context: game.buildContext!,
              builder: (context) => FriendsScreen(
                onClose: () => Navigator.of(context).pop(),
              ),
            );
          }
        })..position = Vector2(0, 30));
        add(DropdownOption('Logout', () {
          _auth.logout();
          _toggleMenu();
        })..position = Vector2(0, 60));
      }
    }

    if (!contains(_label)) add(_label);
  }
}

Future<void> showAuthDialog({
  required BuildContext context,
  required bool isRegister,
  required Future<void> Function(String email, String password, String? username) onSubmit,
}) {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final usernameController = TextEditingController();

  return showDialog(
    context: context,
    builder: (context) {
      String? errorMessage;
      bool isLoading = false;

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isRegister ? 'Register' : 'Login'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  if (isRegister)
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                    ),

                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),

                  if (isRegister)
                    TextField(
                      controller: confirmPasswordController,
                      decoration: const InputDecoration(labelText: 'Confirm Password'),
                      obscureText: true,
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : () async {

                  setState(() {
                    isLoading = true;
                    errorMessage = null;
                  });

                  if (isRegister) {
                    if (passwordController.text != confirmPasswordController.text) {
                      setState(() {
                        isLoading = false;
                        errorMessage = "Passwords do not match.";
                      });
                      return;
                    }
                  }

                  try {
                    await onSubmit(
                        emailController.text,
                        passwordController.text,
                        isRegister ? usernameController.text : null
                    );

                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                    setState(() {
                      isLoading = false;
                      errorMessage = e.toString();
                    });
                  }
                },
                child: isLoading
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)
                )
                    : Text(isRegister ? 'Register' : 'Login'),
              ),
            ],
          );
        },
      );
    },
  );
}