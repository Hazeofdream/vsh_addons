# This mod has been merged into [mega_mod](https://github.com/megascatterbomb/mega_mod)

This is a vscript addon for the Versus Saxton Hale gamemode in Team Fortress 2.

To use this on your community server, simply place all the .nut files inside `/scripts/vscripts/vsh_addons`. No sourcemod required!

New Features:
- Damage logging:
  - On death: the damage dealt by the player is broadcast in chat.
    - If the dead ringer is used, a fake message is displayed to Hale only.
    - Insults the player if they do 0 damage.
  - At round end:
    - The top 3 players' damage is listed.
    - The total damage by all players is displayed.
    - Damage by other sources (e.g. Distillery grinder) is listed separately.
    - Shows a percentage of how much health RED Team managed to chip away.
- Anti-AFK measures:
  - If a player fails to send a keyboard input for 60 seconds, they are killed.
  - When this happens, Hale's health is reduced to compensate, as though the idle player was never there in the first place.
  - Chat messages are sent to the idle player to give them an opportunity to come back before the idle-death.
- Killstreaks:
  - Killstreaks now increment as the mercenaries deal damage to Hale.
  - The streak increments by 1 for every 200 damage dealt to Hale.
  - This does NOT produce any killstreak notifications, but it does enable the visual effects of Professional Killstreak items.
- Player Glows:
  - Mercs can be seen when they're the last merc standing or when Hale caps the point.
  - Hale can be seen through walls when facing the last merc or when mercs cap the point.
  - Prevents that one guy from hiding in a corner for the whole round.
  - Sniper rifle hits make Hale glow through walls (see Sniper below).
- Backstab and Market Garden announcements:
  - A chat message is shown to everyone when a player backstabs or market gardens Hale.

Changes:
- Legend:
  - $n$ is the number of RED players still alive.
  - $N$ is the number of RED players at the start of the round.
  - $H$ is the max health of Hale.
- Hale's health:
  - Changed the formula to match that used in [vsh_facility](https://steamcommunity.com/sharedfiles/filedetails/?id=3225055613), but with a lower (and cleaner) cutoff for linear scaling.

    | Mercs   (N)| Old Formula         |
    |:-----------|:--------------------|
    | 1          | $H = 1000$          |
    | 2 - 5      | $H = 40N^2 + 1300$  |
    | 6+         | $H = 40N^2 + 2000$  |

    | Mercs   (N)| New Formula                               |
    |:-----------|:------------------------------------------|
    | 1          | $H = 1000$                                |
    | 2 - 6      | $H = 41N^2 + 2350(0.3 + N/10)$ |
    | 7 - 23     | $H = 41N^2 + 2350$                        |
    | 24+        | $H = 2000(N-23) + 24000$                  |

- Brave Jump:
  - Added a 5 second cooldown. Has a supporting hud element.
- Saxton Punch:
  - Charges from damage Hale takes instead of a 30 second timer.
    - One punch for every $0.5H$ of damage taken while $H \le 10000$.
    - One punch for every $0.3H$ of damage taken while $H > 10000$.
  - Punches bank: if Hale earns a second punch before using the first, he can throw both.
  - Healing doesn't remove progress.
  - The hud shows the progress to the next punch as a percentage, or a check mark and the number of banked punches when ready.
- Stun breakout:
  - Hale breaks out of a stun after 2 seconds (was 4) or after losing 3000 health while stunned (was 1000).
- Debuff resistance:
  - Removed. Jarate and Marked for Death now last their full duration on Hale instead of half.
- Round timer:
  - Setup Time:
    - Extended for high player counts so players can spread out and/or recover from large lag spikes.
    - Old value: 16 seconds.
    - New value: $max(16, N/3)$ seconds.
      - Peaks at 33 seconds for 100 players.
  - Time before point unlocks:
    - Old value: 4 minutes (drops to 1 minute once only 5 players are alive).
    - New behaviour: Starts at $max(30, 10N)$ seconds, then clamped down to $max(60, 15n)$ seconds during the round (updated on round start and player death).
  - Stalemate 3 minutes after the point unlocks remains in place, unless the point is captured.
- Weapons:
  - Market Gardener and Backstab damage (and anything else using `CalcStabDamage()`) capped at 5000.
    - Affects very high playercounts only.
- Heavy:
  - Removed VSH's 30% damage penalty on crit-boosted minigun damage.
  - Natascha's slow on hit restored to its stock value (VSH reduced it).
- Engineer:
  - Sentries deal 80% damage to Hale (was 50%).
  - Mini-Sentries deal 100% damage to Hale (was 80%).
- Medic:
  - Ubersaw adds 50% ÜberCharge per hit (was 25%).
  - Crusader's Crossbow:
    - All shots are critical.
    - Every bolt that hits Hale adds 15% ÜberCharge. Doesn't extend an Über that is already running.
  - Medi Gun and Kritzkrieg are functionally the same, apart from the Über type:
    - Both build ÜberCharge at the same rate (VSH's 2x).
    - Both always last the full 8 seconds. Switching heal targets no longer drains the Über faster.
- Demoman:
  - The shield comes back after collecting 6 heads since it was broken.
- Sniper:
  - Headshots deal 1.8x damage to Hale (was 1.2x).
  - The Razorback blocks one hit from Hale completely.
    - It recharges when the Sniper picks up a medium or large ammo pack.
  - Sniper rifle hits make Hale glow for up to 8 seconds, scaling with damage dealt (500 damage gives the full 8 seconds). Hits stack up to the cap.
- Rock-Paper-Scissors:
  - Deals 1 million damage to Hale.
    - The default value is only 100k; not enough to cover the maximum possible Hale health.
  - Comically high knockback on Hale's ragdoll when he dies.
- Mighty Slam:
  - Fixed check to prevent low damage (<=30) hits killing low health (<=30) players.
  - No longer hits players through walls. The slam needs a clear line of sight to each target.
- Control Point:
  - Capturing the point no longer instantly ends the round:
    - If RED caps, they get guaranteed crits on all weapons and a powerful 5 second health regen.
    - If Hale caps, his abilities recharge faster: Mighty Slam every 12 seconds, Sweeping Charge every 6 seconds, and a free Saxton Punch every 60 seconds on top of the ones earned from damage.
  - On capture, the stalemate timer is disabled entirely and the point locks itself permanently.
  - The round will eventually end due to Hale's health changing over time:
    - When RED caps, Hale's health will tick down faster and faster. This guarantees his death if he doesn't manage to kill all of RED team first.
    - When Hale caps, his health will tick up faster and faster until it reaches max health, at which point Hale wins the round.
  - The health gained/lost each second starts at 1, then increases by 1 every second.
  - If RED has the point and Hale doesn't do any damage to RED for 30 seconds, an additional 1.05 multiplier is added onto the health drain *each second*.
    - For example This means a $1.05^{15} = 2.08$ multiplier to the health drain per tick after 45 seconds of not dealing damage. The multiplier resets to 1.0 once Hale deals damage.
    - The reverse is also true if Hale owns the point and the mercs don't deal damage to Hale for 30 seconds; Hale's health will regenerate faster via a similar multiplier.
    - This multiplier resets the moment the team that has the point takes damage from the other team.
  - These changes prevent either side from getting an undeserved victory, as the opponent still has a *slim* chance of winning after the capture.
  - Capturing the point produces exciting gameplay to finish a round as opposed to a sudden cutoff.