import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/AudioManager.dart';
import 'FriendsScreen.dart';
import '../services/AuthService.dart';
import '../BattleShipsGame.dart';
import '../services/StatsService.dart';

class DropdownOption extends PositionComponent with TapCallbacks {
  final String text;
  final VoidCallback onTapAction;
  final bool isLast;

  DropdownOption(this.text, this.onTapAction, {this.isLast = false})
      : super(size: Vector2(140, 35));

  final _bgPaint = Paint()..color = const Color(0xFF004488);
  final _hoverPaint = Paint()..color = const Color(0xFF0055AA);
  final bool _isHovered = false;

  @override
  void render(Canvas canvas) {
    Paint paint = _isHovered ? _hoverPaint : _bgPaint;

    if (isLast) {
      RRect rrect = RRect.fromRectAndCorners(
        size.toRect(),
        bottomLeft: const Radius.circular(10),
        bottomRight: const Radius.circular(10),
      );
      canvas.drawRRect(rrect, paint);
    } else {
      canvas.drawRect(size.toRect(), paint);
    }

    TextPaint(
      style: const TextStyle(
          fontSize: 14,
          color: Color(0xFFFFFFFF),
          fontFamily: 'Awesome Font',
          fontWeight: FontWeight.bold
      ),
    ).render(canvas, text, Vector2(size.x / 2, size.y / 2), anchor: Anchor.center);
  }

  @override
  void onTapDown(TapDownEvent event) {
    AudioManager.playClick();
    onTapAction();
    event.handled = true;
  }
}

class AccountDropdown extends PositionComponent with HasGameReference<BattleShipsGame>, TapCallbacks {

  bool _isExpanded = false;
  late TextComponent _label;
  final AuthService _auth = AuthService();

  AccountDropdown() : super(size: Vector2(140, 40));

  final _bgPaint = Paint()..color = const Color(0xFF003366);
  final _borderPaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1;

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
        style: const TextStyle(fontSize: 14, color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold, fontFamily: 'Awesome Font'),
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
    RRect rrect = RRect.fromRectAndCorners(
      size.toRect(),
      topLeft: const Radius.circular(10),
      topRight: const Radius.circular(10),
      bottomLeft: _isExpanded ? Radius.zero : const Radius.circular(10),
      bottomRight: _isExpanded ? Radius.zero : const Radius.circular(10),
    );

    canvas.drawRRect(rrect, _bgPaint);
    canvas.drawRRect(rrect, _borderPaint);
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
      double optionHeight = 35;
      double startY = size.y;

      add(DropdownOption('Stats', () async {
        _toggleMenu();
        if (game.buildContext != null) {
          final stats = await StatsService().getStats();
          if (game.buildContext != null) {
            showAnimatedDialog(game.buildContext!, StatsDialog(stats: stats));
          }
        }
      }, isLast: false)..position = Vector2(0, startY));

      double currentY = startY + optionHeight;

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
        }, isLast: false)..position = Vector2(0, currentY));

        currentY += optionHeight;

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
        }, isLast: true)..position = Vector2(0, currentY));

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
        }, isLast: false)..position = Vector2(0, currentY));

        currentY += optionHeight;

        add(DropdownOption('Logout', () {
          _auth.logout();
          _toggleMenu();
        }, isLast: true)..position = Vector2(0, currentY));
      }
    }

    if (!contains(_label)) add(_label);
  }
}

void showAuthDialog({
  required BuildContext context,
  required bool isRegister,
  String? initialEmail,
  required Function(String email, String pass, String? username) onSubmit,
}) {
  final emailController = TextEditingController(text: initialEmail ?? '');
  final passController = TextEditingController();
  final userController = TextEditingController();

  showAnimatedDialog(
    context,
    StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          backgroundColor: const Color(0xff003366),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: const BorderSide(color: Colors.white, width: 2)
          ),
          title: Text(
            isRegister ? 'Register' : 'Login',
            style: const TextStyle(color: Colors.white, fontFamily: 'Awesome Font'),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isRegister)
                TextField(
                  controller: userController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  ),
                ),
              TextField(
                controller: emailController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                ),
              ),
              TextField(
                controller: passController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () {
                onSubmit(
                  emailController.text,
                  passController.text,
                  isRegister ? userController.text : null,
                );
                Navigator.of(context).pop();
              },
              child: Text(isRegister ? 'Register' : 'Login', style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ),
  );
}

class StatsDialog extends StatelessWidget {
  final Map<String, dynamic> stats;

  const StatsDialog({Key? key, required this.stats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int wins = (stats['wins'] as num?)?.toInt() ?? 0;
    int losses = (stats['losses'] as num?)?.toInt() ?? 0;
    int totalGames = wins + losses;
    double winRate = totalGames > 0 ? (wins / totalGames * 100) : 0;
    int sinkedEnemy = (stats['sinked_enemy_ships'] as num?)?.toInt() ?? 0;
    int sinkedSelf = (stats['sinked_ships'] as num?)?.toInt() ?? 0;
    int singleGames = (stats['games_single'] as num?)?.toInt() ?? 0;
    int multiGames = (stats['games_multi'] as num?)?.toInt() ?? 0;

    int puTotal = (stats['pu_total'] as num?)?.toInt() ?? 0;
    int puOctopus = (stats['pu_octopus'] as num?)?.toInt() ?? 0;
    int puTriple = (stats['pu_triple'] as num?)?.toInt() ?? 0;
    int puShark = (stats['pu_shark'] as num?)?.toInt() ?? 0;

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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("CLOSE", style: TextStyle(color: Colors.white)),
        ),
      ],
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
}

void showAnimatedDialog(BuildContext context, Widget dialog) {
  showGeneralDialog(
    context: context,
    pageBuilder: (ctx, a1, a2) => dialog,
    transitionBuilder: (ctx, a1, a2, child) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: a1, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: a1, child: child),
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black54,
  );
}