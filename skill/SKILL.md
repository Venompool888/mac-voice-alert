---
name: voice-alert
description: Speak an audible alert on the user's Mac when they may be away from the screen — task finished, phase started/finished, or a verification code / captcha needs their input. Uses ~/.dsh/bin/voice-alert (macOS say + notification banner). Not for routine chat replies.
allowed-tools: Bash(~/.dsh/bin/voice-alert:*)
---

# Voice alerts（语音提醒）

用户可能不在电脑旁（待命中）。需要他注意时，**开口说出来**，不要只发一条消息。

## 什么时候该出声（判断标准）

先过三条硬判据，命中任意一条就播报：

1. **要你动手才能往下走** —— 验证码、扫码、点授权、二选一、审批弹窗。
2. **等了一阵才有结果的事结束了** —— 单个任务超过 2 分钟，或后台任务（构建、跑测试、部署、下载）完成或失败。
3. **卡住了，我自己解决不了** —— 报错、权限不够、需要你拍板。

**不要出声的情况**：

- 一问一答、一分钟内能回完的普通对话；
- 任务还在跑，只是中间刷进度（除非超过 10 分钟没动静，报一次）；
- 同一件事刚喊过、状态没变；
- 你说过「别出声 / 我在开会 / 晚点再说」。

## 待命模式

第 2 条要不要喊，取决于你在不在：

| 你说 | 我做 | 效果 |
| --- | --- | --- |
| 「我去吃饭了」「待命」「帮我盯着」 | `voice-alert watch on`（默认 4 小时） | 三条判据全喊 |
| 「我回来了」「不用喊了」 | `voice-alert watch off` | 只喊第 1、3 条 |
| 没说 | 保持现状 | 待命没开时，第 2 条只回消息 |

## 对照表

| 情况 | 怎么喊 |
| --- | --- |
| 长任务开工 | `--style progress "在跑全量测试，约十分钟"` |
| 长任务结束 | `--style done "测试跑完，全部通过"` |
| 要验证码 | `--code 483921`（逐位慢读，别塞进句子） |
| 卡住/要拍板 | `--style urgent "部署失败，要不要回滚"` |

默认后台播放、立刻返回，不会卡住工具调用。`--wait` 才阻塞。

## 规矩

1. **别刷屏**：同一件事只说一次；一句话里把上下文带全（在做什么 + 结果 + 下一步）。
2. **短**：念出来 1～2 句，20 字以内最佳。代码、路径、URL 不要念，改成「配置已改好，等你看」。
3. **验证码必须逐位慢读**：用 `--code`，不要塞进普通句子（会念成数字串）。
4. 用户回话/确认后不再重复：`~/.dsh/bin/voice-alert stop`。
5. 静音或音量太低时脚本会自动临时解除并恢复原状（`--keep-volume` 可关闭）。
6. 用户明确说「别出声」「静音」「我在开会」时，改用文字，别调用。

## 其它

- 换声音：`--voice Meijia` / `Sinji` / `Eddy (Chinese (China mainland))`
- 重复 n 次、间隔：`--repeat 3 --interval 30`（code 默认 2 次/20s，urgent 默认 3 次）
- 查状态与历史：`~/.dsh/bin/voice-alert status`；日志 `~/.dsh/state/voice-alert/log.tsv`
- 没声音先查：`~/.dsh/bin/voice-alert doctor`；再查系统设置 > 声音 > 输出设备。
- 装到别的位置时，把上面命令里的 `~/.dsh/bin/` 换成实际路径。
