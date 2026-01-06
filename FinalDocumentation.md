# Battle Bottles - Final Documentation
## Project description
_Battle Bottles_ is a cross-platform mobile and web game built with Flutter and the Flame engine. It's inspired by the classic battleships game, where players take command of miniature crews navigating tiny bottles across dynamic battlefields. Players can compete against the computer or challenge friends in multiplayer mode. They can use various power-ups and customize their game.

## Integrations
- Flame Engine - used for the main game loop, rendering sprites, handling user input, and managing the coordinate system for game entities (ships, grid, animations).
- Firebase Authentication - handles secure user sign-up and sign-in processes.
- Cloud Firestore - serves as the realtime backend database for syncing multiplayer game states (moves, turns) and storing user statistics/friend lists.
- Flame Audio - manages background music and sound effects (explosions, splashes).

## Optional requirements
- Support for Android and Web platforms
- Custom-made explicit animations for UI (menus, dialogs) and hand-crafted sprite animations for game actions
- Unit and widget tests for business logic and UI components isolated from the game engine
- User authentication integrated with Firebase Auth
- GitHub Actions workflow for automated code analysis and testing, automated deployment pipeline
- Native audio playback support using platform channel packages
- Custom graphics for most of the game elements and game grid drawn directly on Canvas
- Offline-first architecture for player statistics, automatically syncing with the cloud when online

## Instruction
Additional in-game help is available under '?' button in the upper left corner.
1. Log in via the 'My Account' menu to track statistics and add friends.
2. Select Singleplayer or Multiplayer. Customize the grid size and fleet composition.
3. Drag and drop ships onto your grid. Tap a ship to rotate it. Press **Start** when ready.
4. Gameplay:
    - Tap a coordinate on the enemy grid to fire. A hit grants a bonus turn.
    - Select a power-up icon before firing to activate it:
        - Octopus - hits a target and 4 surrounding points.
        - Triple Shot - allows 3 shots in one turn.
        - Shark - sinks an entire row but destroys your corresponding row as well.
5. On mobile devices, rotate to landscape mode to view both grids simultaneously.
6. Sink all enemy ships to win. After a loss see which ships you've missed.

## Firebase schema
The applications uses two main collections:
1. users - which stores profiles and stats
	- createdAt - timestamp
	- email - string
	- games_multi - number
	- games_single - number
	- losses - number
	- powerups_octopus - number
	- powerups_shark - number
	- powerups_total - number
	- powerups_triple_shot - number
	- sinked_enemy_ships - number
	- sinked_ships - number
	- uid (Document ID) - string
	- username - string
	- wins - number
	- friends - another collection
		- addedAt - timestamp
		- email - string
		- username - string
2. battles - which manages active multiplayer sessions
	- createdAt - timestamp
	- currentTurn - string
	- fleetCounts - map of numbers
	- gridSize - number
	- lastSpecialAttack - map
		- attacker - string
		- id - string
		- target - number
		- type - string
	- player1Name, player2Name - strings
	- player1Ready, player2Ready - booleans
	- player1Id, player2Id - strings
	- ships_p1, ships_p2 - arrays of maps
	- shots_p1, shots_p2 - arrays of numbers
	- status - string
## CI/CD description
The project utilizes GitHub Actions for Continuous Integration and Deployment. The workflow is triggered on every push to the `main` branch:
1. Configures the Ubuntu environment and installs the Flutter SDK.
2. Runs `flutter pub get` and `flutter analyze` to check for linter errors.
3. Executes `flutter test` to run unit and widget tests.
4. Builds the web and android versions of the app.

---
**Author: Martyna Sadowska**
GitHub repository: [BattleBottles](https://github.com/Martyna-265/BattleBottles)