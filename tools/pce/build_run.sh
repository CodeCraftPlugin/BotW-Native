# Build, and launch only if the build succeeded (a running game locks the exe: the link then fails).
. /d/Compiling/BotW-Native/tools/pce/env.sh
cmake --build build -j14 || { echo "== BUILD FAILED, not launching (is the game still open?) =="; exit 1; }
echo "== build ok, exe $(date -r build/BotWRecomp.exe +%T) =="
. tools/pce/run.sh
