import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:shared_preferences/shared_preferences.dart';
import 'FriendsScreen.dart'; //
import '../services/AuthService.dart';
import '../BattleShipsGame.dart';
import '../services/StatsService.dart';

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

      add(DropdownOption('Stats', () async {
        _toggleMenu();
        if (game.buildContext != null) {
          final stats = await StatsService().getStats();
          if (game.buildContext != null) {
            _showStatsDialog(game.buildContext!, stats);
          }
        }
      })..position = Vector2(0, 30));

      double currentY = 60;

      if (user == null) {
        // NOT LOGGED IN

        add(DropdownOption('Login', () async {
          _toggleMenu();
          if (game.buildContext != null) {
            final prefs = await SharedPreferences.getInstance();
            final lastEmail = prefs.getString('last_email');

            if (game.buildContext != null) {
              showAuthDialog(
                  context: game.buildContext!,
                  isRegister: false,
                  initialEmail: lastEmail,
                  onSubmit: (email, pass, username) async {
                    await _auth.login(email, pass);
                    await prefs.setString('last_email', email);
                  }
              );
            }
          }
        })..position = Vector2(0, currentY));

        currentY += 30;

        // --- OPCJA REGISTER ---
        add(DropdownOption('Register', () {
          _toggleMenu();
          if (game.buildContext != null) {
            showAuthDialog(
                context: game.buildContext!,
                isRegister: true,
                onSubmit: (email, pass, username) async {
                  await _auth.register(email, pass, username ?? 'Player');

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('last_email', email);

                  final updatedUser = _auth.currentUser;
                  if (updatedUser != null) {
                    String labelText = updatedUser.displayName ?? updatedUser.email ?? 'User';
                    _updateLabel(labelText);
                  }
                }
            );
          }
        })..position = Vector2(0, currentY));

      } else {
        // LOGGED IN
        add(DropdownOption('Friends', () {
          _toggleMenu();
          if (game.buildContext != null) {
            showDialog(
              context: game.buildContext!,
              builder: (context) => FriendsScreen(
                onClose: () => Navigator.of(context).pop(),
              ),
            );
          }
        })..position = Vector2(0, currentY));

        currentY += 30;

        add(DropdownOption('Logout', () {
          _auth.logout();
          _toggleMenu();
        })..position = Vector2(0, currentY));
      }
    }

    if (!contains(_label)) add(_label);
  }
}

void _showStatsDialog(BuildContext context, Map<String, int> stats) {
  showDialog(
    context: context,
    builder: (ctx) {
      int wins = stats['wins'] ?? 0;
      int losses = stats['losses'] ?? 0;
      int totalGames = wins + losses;
      double winRate = totalGames > 0 ? (wins / totalGames * 100) : 0;
      int sinkedEnemy = stats['sinked_enemy_ships'] ?? 0;
      int sinkedSelf = stats['sinked_ships'] ?? 0;
      int singleGames = stats['games_single'] ?? 0;
      int multiGames = stats['games_multi'] ?? 0;

      int puTotal = stats['pu_total'] ?? 0;
      int puOctopus = stats['pu_octopus'] ?? 0;
      int puTriple = stats['pu_triple'] ?? 0;
      int puShark = stats['pu_shark'] ?? 0;

      return AlertDialog(
        backgroundColor: const Color(0xFF003366),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "Captain's Log",
          style: TextStyle(color: Colors.white, fontFamily: 'Awesome Font', fontSize: 24),
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(color: Colors.white54),

                _buildStatRow(Icons.emoji_events, "Victories", "$wins", Colors.greenAccent),
                _buildStatRow(Icons.dangerous, "Defeats", "$losses", Colors.redAccent),

                const SizedBox(height: 10),
                _buildStatRow(Icons.my_location, "Sunk Enemies", "$sinkedEnemy", Colors.cyanAccent),
                _buildStatRow(Icons.warning, "Lost Ships", "$sinkedSelf", Colors.orangeAccent),

                const Divider(color: Colors.white54),
                _buildStatRow(Icons.analytics, "Total Games", "$totalGames", Colors.white),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, left: 40.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Single: $singleGames | Multi: $multiGames",
                        style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  ),
                ),
                _buildStatRow(Icons.percent, "Win Rate", "${winRate.toStringAsFixed(1)}%", Colors.orangeAccent),

                const Divider(color: Colors.white54),
                _buildStatRow(Icons.flash_on, "Power-ups Used", "$puTotal", Colors.yellowAccent),
                Padding(
                  padding: const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0),
                  child: Column(
                    children: [
                      _buildMiniStatRow("Octopus", "$puOctopus"),
                      _buildMiniStatRow("Triple Shot", "$puTriple"),
                      _buildMiniStatRow("Shark", "$puShark"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("CLOSE", style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}

Widget _buildStatRow(IconData icon, String label, String value, Color color) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 15),
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 18)),
        ),
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

Widget _buildMiniStatRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

Future<void> showAuthDialog({
  required BuildContext context,
  required bool isRegister,
  String? initialEmail,
  required Future<void> Function(String email, String password, String? username) onSubmit,
}) {
  // Jeśli podano initialEmail, wpisujemy go od razu do kontrolera
  final emailController = TextEditingController(text: initialEmail ?? '');
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
            backgroundColor: const Color(0xFF003366),
            title: Text(
                isRegister ? 'Register' : 'Login',
                style: const TextStyle(color: Colors.white)
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  if (isRegister)
                    _buildTextField(usernameController, 'Username', false),

                  _buildTextField(emailController, 'Email', false),
                  _buildTextField(passwordController, 'Password', true),

                  if (isRegister)
                    _buildTextField(confirmPasswordController, 'Confirm Password', true),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
                    if (context.mounted) {
                      setState(() {
                        isLoading = false;
                        errorMessage = e.toString();
                      });
                    }
                  }
                },
                child: isLoading
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                )
                    : Text(isRegister ? 'Register' : 'Login', style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _buildTextField(TextEditingController controller, String label, bool obscure) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10.0),
    child: TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
      ),
    ),
  );
}