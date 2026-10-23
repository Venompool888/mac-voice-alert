# voice-alert

> 让 AI 助手用这台 Mac 的喇叭开口说话。

一台放在角落的 Mac mini，跑着 AI 编码助手。任务结束、验证码到了、出错了卡住了——它不该只丢一行你可能十分钟后才看到的文字，应该直接念出来。

`voice-alert` 就是干这个的：**一行命令，让 Mac 说中文**。

- **纯本地**：系统自带 `say` 合成，不联网、不调用云 TTS、不花一分钱
- **零依赖**：没有 pip / npm / brew，没有第三方包，没有守护进程
- **说完就走**：运行一次念一次，念完退出，不占后台
- **一分钟装好**：解压、`./install.sh`、听到一句"安装成功"

## 效果

```bash
voice-alert --style done "构建通过，已部署到测试环境"
# 🔔 玻璃音 →「完成了。构建通过，已部署到测试环境」

voice-alert --code 483921
# 🔔🔔 两声警示音 →「需要验证码。验证码是，四、八、三、九、二、一」
#              →「再说一遍，四、八、三、九、二、一」→ 20 秒后自动重播

voice-alert --style urgent "部署失败，要不要回滚"
```

## 安装

要求：macOS（本项目只支持 macOS）。

```bash
git clone https://github.com/Venompool888/mac-voice-alert.git
cd mac-voice-alert
./install.sh
```

装完会自动自检（系统版本、选中的音色、当前音量）并念一句测试音。

自定义安装位置：

```bash
./install.sh --prefix ~/bin --skill-dir ~/.dsh/skills/voice-alert --no-test
```

## 用法

```bash
voice-alert --style done "构建通过"            # 事情做完了
voice-alert --style progress "在跑测试，十分钟" # 开始长任务 / 中途进展
voice-alert --code 483921                     # 要你填验证码（逐位慢读）
voice-alert --style urgent "部署失败"          # 卡住了，要你拍板
voice-alert watch on                          # 待命模式：长任务结束也出声
voice-alert stop                              # 立刻闭嘴，停止重复
voice-alert doctor                            # 环境自检
```

| 参数 | 说明 |
| --- | --- |
| `--style` | `done` / `progress` / `code` / `urgent` / `plain`，决定提示音和语气 |
| `--code N` | 验证码专用：数字转成中文逐位慢读，念两遍 |
| `--voice NAME` | 指定音色，默认自动挑本机可用的中文音色 |
| `--rate N` | 语速，默认 185 |
| `--repeat N --interval S` | 重复次数与间隔（code 默认 2 次 / 20 秒） |
| `--no-chime` / `--no-banner` | 不要提示音 / 不要通知条 |
| `--keep-volume` | 不要动系统音量 |
| `--wait` | 前台播放并等待（默认后台立即返回） |

## 几个不太明显的设计

| 行为 | 为什么 |
| --- | --- |
| **静音/音量低时临时处理** | 检测到静音或音量低于 45，临时解除并提到 60，念完恢复原状。不然"喊了但你听不见" |
| **目录锁排队** | 同时来三条提醒不会叠在一起变成噪音；持锁进程死了会自动清理死锁 |
| **20 秒内不重复播** | 连续几次 urgent 会像卡带，除验证码外 20 秒内只响一次 |
| **验证码逐位念** | `say` 会把 483921 读成"四十八万三千九百二十一"，所以先转成"四、八、三、九、二、一" |
| **`stop` 是真的停** | 会杀掉正在念的那句和排队中的重复循环，不是只停止下一轮 |
| **待命模式 4 小时自动过期** | 免得忘了关，半夜还在说话 |

## 它是怎么工作的

没有任何魔法，就是三个系统命令：

```
say      -v Tingting "文本"     # 语音合成（本地）
afplay   /System/Library/Sounds/Glass.aiff   # 提示音
osascript -e 'set volume ...'   # 调音量 / 弹通知条
```

运行时只有这些文件：

```
~/.dsh/bin/voice-alert               # 脚本本体（9KB bash）
~/.dsh/state/voice-alert/log.tsv     # 播报历史
~/.dsh/state/voice-alert/voice       # 探测到的音色缓存
~/.dsh/state/voice-alert/lock/       # 播放锁
```

不联网、不读你的其他文件、不监听麦克风、不需要任何系统权限授权。

## 给 AI 助手用

这是它真正的用法：不是你自己敲命令，是让 AI 在恰当的时机出声。

- [AGENTS.md](AGENTS.md) —— 给 AI 看的完整说明（接口、状态机、改代码的注意事项）
- [skill/SKILL.md](skill/SKILL.md) —— 技能文件，装进 `~/.dsh/skills/` 或 `~/.claude/skills/` 后自动生效
- [docs/AGENTS-snippet.md](docs/AGENTS-snippet.md) —— 直接贴进你 `AGENTS.md` 的规则片段

## 卸载

```bash
rm -f ~/.dsh/bin/voice-alert
rm -rf ~/.dsh/skills/voice-alert ~/.dsh/state/voice-alert
```

## 常见问题

**没声音？** 先 `voice-alert doctor`。多数是输出设备被外接显示器或耳机抢走了（系统设置 → 声音 → 输出）。

**中文音色没装？** 系统设置 → 辅助功能 → 朗读内容 → 系统声音 → 管理声音，下载"婷婷"。没装也能用，会退回系统默认音色（念中文会怪一点）。

**能做 Linux/Windows 吗？** 不打算。Linux 要 espeak/festival，音质差一截；这个项目的取舍就是"Mac 上开箱即用"。

## License

MIT
