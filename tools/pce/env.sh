# Shared settings for the tools/pce scripts (sourced).
cd /d/Compiling/BotW-Native
GAME="/d/Games/Netendo/Decrepted/Combined/BotW-Native game"
# The user folder must be explicit: an MSYS login shell started from Git Bash has no APPDATA, and the exe
# then falls back to .\BotWRecomp (no saves -> the game starts a new game).
export BOTW_USER_ROOT="C:/Users/CodeCraft/AppData/Roaming/BotWRecomp"
