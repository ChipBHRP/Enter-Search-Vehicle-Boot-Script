EnterBoot: Immersive Vehicle Trunk/Boot Hiding for FiveM
EnterBoot is a lightweight, feature-rich FiveM resource designed to add an immersive layer of roleplay by allowing players to hide inside a vehicle's trunk (boot) and enabling authorized users to search and discover them. This script prioritizes server optimization, realism through animations, and highly flexible configuration using ox_lib.

🧩 Core Capabilities & Features
1. Dynamic Hiding Mechanism
Seamless Entry/Exit: Players can enter the nearest vehicle boot using a customizable keybind (F6 by default) or the /enterboot command.

Immersive Animation: The trunk physically opens and closes during entry and exit sequences, adding a visual cue to the action.

Concealment: The player model is automatically hidden and frozen inside the vehicle, simulating complete concealment.

Free-Look Camera: Once inside, the player is switched to a dedicated script camera, allowing them to freely look around their surroundings while remaining hidden. A dedicated keybind (G or Spacebar) is used to exit the trunk.

2. Sophisticated Server-Side Capacity & Locking
Vehicle Capacity System: The server dynamically calculates the maximum number of players that can hide in a vehicle based on its GTA vehicle class. The config.lua defines custom classes (small, medium, large) and maps them to GTA vehicle classes, preventing exploits and promoting realism.

Exclusion Filtering: Automatically prevents players from attempting to enter non-applicable vehicles, such as motorcycles, planes, boats, and utility vehicles.

Boot Locking: Use the /lockboot and /unlockboot commands (F7/F8) to server-sync the trunk lock state, preventing entry even if space is available.

Emergency Unlock: The /emgunlockboot command provides a configurable, progress-bar-based unlock mechanism for authorized users (e.g., Police/Mechanics) to force a locked trunk open.

3. Search & Extraction System (For Authorized RP)
Vehicle Search: Authorized players can use /searchvboot to initiate a search animation (with an ox_lib progress circle), opening the trunk to check for occupants.

Detection Prompt: If a player is found, an interactive 3D prompt appears (default key: Y) allowing the searching player to pull the occupant out of the trunk.

Forced Exit: When pulled out, the hidden player is immediately detached and forced to exit the vehicle with an appropriate animation, simulating the struggle of being discovered.

Performance
The script is built to be highly optimized:

Low Resource Usage: Uses asynchronous callbacks (lib.callback.await) for server checks and efficient main loops, ensuring minimal impact on client performance (often reported at 0.00ms idle).

Network Synchronization: All player state and boot lock changes are handled server-side and synced across the network to prevent desync or client-side exploits.
