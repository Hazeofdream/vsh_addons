// NEW: Sniper rifle hits make Hale glow (the same team-colored outline as player_glows.nut / the payload cart).
// Each hit adds glow time based on the damage it actually dealt, capped at maxGlowSeconds remaining.
// Only sniper rifles count (Sniper Rifle, Bazaar Bargain, Classic, Machina, Sleeper, etc.), not the Huntsman or SMG.
// Must be included after player_glows.nut, since it overrides BossGlowOnMercBuffTrait.

local maxGlowSeconds = 8.0;
local damageForMaxGlow = 500.0; // Damage that gives the full 8s in one hit. Smaller hits give proportionally less.

::sniperGlowEndTime <- {}; // boss -> Time() when the glow runs out

characterTraitsClasses.push(class extends CharacterTrait
{
    function CanApply()
    {
        return player.GetPlayerClass() == TF_CLASS_SNIPER;
    }

    function OnHurtDealtEvent(victim, params)
    {
        if (!IsValidBoss(victim) || params.damageamount <= 0)
            return;
        // Rifles are hitscan, so the active weapon is the one that dealt the damage.
        local weapon = player.GetActiveWeapon();
        if (weapon == null || weapon.GetClassname().find("tf_weapon_sniperrifle") != 0)
            return;

        local now = Time();
        local endTime = victim in sniperGlowEndTime ? sniperGlowEndTime[victim] : now;
        if (endTime < now)
            endTime = now;
        endTime += maxGlowSeconds * params.damageamount / damageForMaxGlow;
        if (endTime > now + maxGlowSeconds)
            endTime = now + maxGlowSeconds;
        sniperGlowEndTime[victim] <- endTime;
    }
});

// OVERRIDE: Same rules as player_glows.nut, plus the sniper glow timer.
function BossGlowOnMercBuffTrait::OnTickAlive(timeDelta)
{
    local currentGlow = GetPropBool(player, "m_bGlowEnabled");
    local sniperGlow = player in sniperGlowEndTime && sniperGlowEndTime[player] > Time();
    local shouldGlow = IsAnyBossAlive() && (GetAliveMercCount() == 1 || mercBuff || sniperGlow);
    if (shouldGlow != currentGlow)
        SetPropBool(player, "m_bGlowEnabled", shouldGlow);
}

AddListener("round_end", 5, function (winnerTeam)
{
    sniperGlowEndTime.clear();
});
