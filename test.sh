#!/bin/bash
# 冒烟测试：语法、自检、参数处理，可选实际播一句
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
BIN="$HERE/bin/voice-alert"
NO_SOUND=0
[ "${1:-}" = "--no-sound" ] && NO_SOUND=1

if [ "$(uname -s)" != "Darwin" ]; then
  echo "跳过：仅支持 macOS"
  exit 0
fi

fail=0
check() {
  if eval "${2}" >/dev/null 2>&1; then
    echo "  ✓ $1"
  else
    echo "  ✗ $1"
    fail=1
  fi
}

# 断言某个命令以指定退出码结束
expect_exit() {
  local want="$1"; shift
  "$@" >/dev/null 2>&1
  [ "$?" -eq "$want" ]
}

echo "voice-alert 冒烟测试"
check "语法检查 (bash -n)" "bash -n '$BIN'"
check "--version" "'$BIN' --version"
check "doctor 自检" "'$BIN' doctor"
check "未知参数返回 2" "expect_exit 2 '$BIN' --definitely-not-an-option"
check "无参数打印帮助" "'$BIN' | grep -q voice-alert"
check "watch 开关" "'$BIN' watch off && '$BIN' watch | grep -q 关"

if [ "$NO_SOUND" = "0" ]; then
  echo "  · 实际播放一句…"
  "$BIN" --style done "冒烟测试通过" --wait --no-banner || fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "全部通过"
else
  echo "有失败项"
fi
exit "$fail"
