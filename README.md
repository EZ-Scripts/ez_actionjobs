# ez_actionjobs

Singleplayer jobs for BrightFallsRP: talk to a foreman, pick up the tool or material, work each marked spot, and go back to get paid. Comes with **Construction** (carry planks, nail them down) and **Sweeping**. Add as many jobs as you like in `shared/config.lua` by giving them `pickup.run` / `workSpot.run` functions and locations.

Built on jo_libs like the other ez scripts: jo menu, jo prompts, jo notifications, jo callbacks.

## How a shift works

1. Talk to the foreman (G), choose **Start working**. The menu shows your experience, the pay for a full shift and the number of spots.
2. Pick up at the marked spot, carry it to the next work spot and do the minigame. While carrying a plank, running, jumping, mounting (E) or cover (Q) drops it.
3. Back at the foreman, **Finish working**. You're paid for the share of spots done. A failed minigame or dropped plank takes `Config.quality.penalty` % off. Do more than half the spots (`Config.minimumWork`) to get paid. Finish them all to gain 1 experience.

Pay steps are per job (`pay = { [experience] = pay }`).

## Hammer minigame (construction)

`Config.hammerMinigame.provider`:

- `"ez"` (default): built in. A ring closes on the nail. Left click the nail as it meets the dashed circle. Good strikes drive it in, perfect ones count double. Early strikes bend the nail, and so does letting the ring close. Too many mistakes fail the plank. ESC gives up. Tune it in `Config.hammerMinigame.ez` (nails, strikes, speed, timing windows, mistakes, time limit, wood colour, volume).
- `"bcc"`: bcc-minigames' hammertime (the old one).
- `"skillbar"`: ez_skillbar bars.

From any job function: `PlayHammerMinigame({ nails = 6 })` overrides options for that call. Sweeping uses `PlaySkillbar(rounds, gap)` (ez_skillbar, via its syn_minigame export).

## Security

The server keeps its own count of the shift and pays from it (`server/main.lua`). Clients can't send the amount, the number of spots or the quality any more. Each "spot done" report must come from near that spot (`Config.security.taskDistance`) and at least `minTaskInterval` seconds after the last one (`server/config.lua`).

## Install

1. Needs `jo_libs`, `oxmysql` and `vorp_core`. `vorp_menu`, `ghmattimysql` and `bcc-minigames` aren't needed any more (bcc only for `provider = "bcc"`). Sweeping needs `ez_skillbar`.
2. Experience is kept in the `trust` JSON column of `characters`, the same column as before, so nothing is lost. It's added on start if missing.
