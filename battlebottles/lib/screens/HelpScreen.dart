import 'package:flutter/material.dart';
import '../BattleShipsGame.dart';

class HelpScreen extends StatelessWidget {
  final BattleShipsGame game;

  const HelpScreen({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xAA000000),
      body: Center(
        child: Container(
          width: 500,
          height: 650,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xff003366),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'HELP & RULES',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Awesome Font',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () {
                      game.overlays.remove('HelpScreen');
                    },
                  ),
                ],
              ),
              const Divider(color: Colors.white),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader("Battle Bottles"),
                      _buildText(
                          "Take command of miniature crews navigating tiny bottles across dynamic battlefields. The seas may be small, but the strategy runs deep as you outmaneuver opponents in a test of wits and luck. Will your fleet survive the storm, or will your hopes end up shattered at the bottom of the ocean?"),

                      const SizedBox(height: 15),
                      _buildHeader("How to play"),
                      _buildListItem("1. Setup the Board:", "Choose your fleet size and the dimensions of the battlefield grid. Remember, fair play is key - your opponent will face the exact same conditions."),
                      _buildListItem("2. Deploy Your Fleet:", "Drag and drop your ships to strategic positions. You can tap on a ship to rotate it or change its formation. Press Start when you are ready to lock in your strategy."),
                      _buildListItem("3. Open Fire:", "Tap on the enemy grid to launch a bomb. If you score a direct hit, you are rewarded with a bonus shot. The same rule applies to your opponent!"),
                      _buildListItem("4. Special Tactics:", "Before firing, you can activate a Power-up to turn the tide of battle. Use them wisely, as your supply is limited.\nNote: In single-player, the computer does not use power-ups, but it has the ability to randomly strike twice in a single round."),
                      _buildListItem("5. Track Progress:", "Keep an eye on the ship counter below the enemy grid. To win, you must sink every ship type in their fleet."),
                      _buildListItem("6. View Modes:", "On narrow screens (mobile portrait), only the active grid is visible to maximize detail. Rotate your device to landscape or use a wider screen to see both your fleet and the enemy's simultaneously."),
                      _buildListItem("7. After Action Report:", "Even if you lose, you can reveal the battlefield to see the enemy's formation and discover exactly where those elusive ships were hiding."),

                      const SizedBox(height: 15),
                      _buildHeader("Power-ups"),
                      _buildListItem("• Octopus:", "Unleash the beast! Select a square, and the Octopus will sink it along with 4 random points surrounding that target."),
                      _buildListItem("• Triple Shot:", "Fire three times in a single round. If you hit a ship, the standard bonus rules apply, allowing for devastating combos."),
                      _buildListItem("• Shark:", "High risk, high reward. Select a row on the enemy grid to sink it entirely. But beware - the Shark bites back, destroying the corresponding line on your own grid as well!"),

                      const SizedBox(height: 15),
                      _buildHeader("Multiplayer"),
                      _buildText("Challenge your friends to a duel! First, sign in via the 'My Account' section and add friends using their email addresses. Once connected, you can create a custom lobby where your friend can join. Customize the grid, fleet, and power-up limits to your liking, hit Play, and see who truly rules the waves!"),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.greenAccent, fontFamily: 'Awesome Font'),
      ),
    );
  }

  Widget _buildText(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, height: 1.4, color: Colors.white70),
    );
  }

  Widget _buildListItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 16, height: 1.4, color: Colors.white70),
          children: [
            TextSpan(text: "$title ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            TextSpan(text: description),
          ],
        ),
      ),
    );
  }
}