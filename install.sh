#!/bin/bash
# voice-alert 一键安装（macOS）
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PREFIX=""
SKILL_DIR=""
DO_TEST=1

usage() { cat <<'EOF'
用法: ./install.sh [--prefix DIR] [--skill-dir DIR] [--no-test]

  --prefix DIR     脚本安装目录（默认 ~/.dsh/bin；没有 .dsh 时用 ~/bin）
  --skill-dir DIR  技能目录（默认 ~/.dsh/skills/voice-alert 或 ~/.claude/skills/voice-alert）
  --no-test        装完不播放测试音
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --prefix) PREFIX="$2"; shift 2 ;;
    --skill-dir) SKILL_DIR="$2"; shift 2 ;;
    --no-test) DO_TEST=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "未知参数: $1"; usage; exit 2 ;;
  esac
done

[ "$(uname -s)" = "Darwin" ] || { echo "只支持 macOS（依赖自带的 say / afplay / osascript）"; exit 1; }
command -v say >/dev/null || { echo "找不到 say，系统环境异常"; exit 1; }

if [ -z "$PREFIX" ]; then
  if [ -d "$HOME/.dsh" ]; then PREFIX="$HOME/.dsh/bin"; else PREFIX="$HOME/bin"; fi
fi
mkdir -p "$PREFIX"
install -m 755 "$HERE/bin/voice-alert" "$PREFIX/voice-alert"
echo "✓ 脚本 → $PREFIX/voice-alert"

if [ -z "$SKILL_DIR" ]; then
  if [ -d "$HOME/.dsh" ]; then SKILL_DIR="$HOME/.dsh/skills/voice-alert"
  elif [ -d "$HOME/.claude" ]; then SKILL_DIR="$HOME/.claude/skills/voice-alert"
  fi
fi
if [ -n "$SKILL_DIR" ]; then
  mkdir -p "$SKILL_DIR"
  install -m 644 "$HERE/skill/SKILL.md" "$SKILL_DIR/SKILL.md"
  echo "✓ 技能 → $SKILL_DIR/SKILL.md"
else
  echo "! 没找到 ~/.dsh 或 ~/.claude，技能文件请手动复制 skill/SKILL.md"
fi

case ":$PATH:" in
  *":$PREFIX:"*) ;;
  *) echo "! $PREFIX 不在 PATH 里，用全路径调用即可" ;;
esac

echo
"$PREFIX/voice-alert" doctor
echo

if [ "$DO_TEST" = "1" ]; then
  echo "播放测试音…"
  "$PREFIX/voice-alert" --style done "语音提醒安装成功" --wait --no-banner
fi

cat <<EOF

装好了。常用命令：
  $PREFIX/voice-alert --style done "任务完成"
  $PREFIX/voice-alert --code 483921
  $PREFIX/voice-alert watch on        # 待命模式

想让 AI 自动在这些时机出声：把 docs/AGENTS-snippet.md 贴到
~/.dsh/AGENTS.md（或 CLAUDE.md）末尾。
EOF
