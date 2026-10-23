# AGENTS.md

写给 AI 编码助手的说明。人类请看 [README.md](README.md)。

## 这是什么

`voice-alert` 是一个 macOS 命令行小工具：把一段文字用系统自带 TTS 念出来，可选提示音和通知条。
典型用途是让 AI 助手在**任务完成 / 需要验证码 / 卡住需要人拍板**时出声提醒用户，因为用户可能不在屏幕前。

**关键事实**

- 只支持 macOS，依赖系统自带的 `say`、`afplay`、`osascript`
- 纯 bash，单文件，零第三方依赖，无守护进程
- 默认后台播放，调用后立即返回
- 不联网、不读用户文件、不要权限

## 目录

```
bin/voice-alert          主程序（唯一需要维护的文件）
install.sh               安装脚本（自动选目录 + 自检 + 测试音）
test.sh                  冒烟测试
skill/SKILL.md           给 agent 的技能文件（何时用、怎么用）
docs/AGENTS-snippet.md   可直接粘贴的 AGENTS.md 片段
```

## 命令接口

```
voice-alert [--style done|progress|code|urgent|plain] [--no-chime] [--no-banner] "文本"
voice-alert --code 483921            # 验证码：逐位慢读，念两遍
voice-alert --voice Tingting --rate 160 "文本"
voice-alert --repeat 3 --interval 30 "文本"
voice-alert --wait "文本"             # 前台等待（默认后台）
voice-alert stop                     # 杀死当前播放 + 排队循环
voice-alert status                   # 音量 / 待命模式 / 最近 5 条
voice-alert watch on [小时] | off     # 待命模式
voice-alert doctor                   # 环境自检
voice-alert --version
```

退出码：0 正常；2 参数错误。

## 运行时状态

都在 `~/.dsh/state/voice-alert/`：

| 文件 | 作用 |
| --- | --- |
| `log.tsv` | 每次播报一行：时间、style、文本 |
| `lock/` | 播放互斥锁（mkdir 实现），内含 holder pid |
| `say.pid` | 当前 `say` 进程，供 `stop` 精确击杀 |
| `loop.pid` | 后台重复循环的 pid |
| `last_play` | 上次播报时间戳，用于 20 秒防叠播 |
| `watch` | 待命模式过期时间戳 |
| `voice` | 探测到的音色缓存 |

## 什么时候该调用它

三条硬判据，命中一条就调用：

1. **用户必须动手才能继续** —— 验证码、扫码、点授权、二选一；
2. **等了一阵才有结果的事结束了** —— 超过 2 分钟的任务、后台任务完成或失败；
3. **卡住了** —— 报错、权限不足、需要拍板。

不要调用：普通问答、一分钟内能回完的对话、任务还在跑只是刷进度（除非 10 分钟没动静）、
同一件事刚说过且状态没变、用户说过"别出声"。

用户说"待命 / 帮我盯着 / 我去吃饭" → `watch on`；说"我回来了" → `watch off`。

## 改代码时的约定

1. **只用系统自带命令**。新增依赖等于破坏这个项目最大的卖点。需要判断命令是否存在时用 `command -v`。
2. **不要在 stop 里用 `pkill -f "say"`**。那会误杀用户自己在跑的任何 `say`。用 `say.pid` 精确 kill。
3. **保持 `set -uo pipefail`**，但不要加 `set -e`：脚本里大量"允许失败"的探测（音量查询、音色探测）。
4. **任何新增的文本都要能被念出来**。路径、URL、代码不要直接念，改成人类听的描述。
5. **改完跑 `./test.sh`**，它会做语法检查、自检、并实际播一句。
6. **保留 macOS 之外的干净退出**：非 Darwin 直接报错退出，不要悄悄失败。

## 常见改动

**加一种语气**：在 `payload()` 的 `case` 里加分支，在 `--style` 的 usage 文本里同步，在 `case "$STYLE"` 默认重复次数里给它设默认值。

**换音色策略**：改 `detect_voice()` 的候选列表；探测用 `probe_voice()`，它会真的渲染一帧到临时文件，比解析 `say -v '?'` 的输出可靠（音色名里带空格和括号）。

**加手机推送**：在 `payload()` 末尾追加一次 HTTP 调用（curl 是系统自带的），失败要静默，不能让推送失败影响本机播报。凭证从环境变量读，不要写进仓库。

**支持英文播报**：目前固定用中文音色。如果要按文本自动选，注意 bash 里判断 CJK 字符需要额外工具，建议用 `LC_ALL=UTF-8` 下的 `grep -q '[一-龥]'` 并测试 BSD grep 的行为。
