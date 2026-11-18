# Incremental build only (no hook changes).
. /d/Compiling/BotW-Native/tools/pce/env.sh
cmake --build build -j14; echo "== build exit $? =="
