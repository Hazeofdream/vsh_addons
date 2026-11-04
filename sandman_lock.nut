// NEW: Sandman balls lock Hale's abilities. The lock length scales with how far the ball flew,
// up to maxLockSeconds for a moon shot (moonShotDistance or farther).
// Locks Mighty Slam, Sweeping Charge, Saxton Punch and (optionally) Brave Jump.
// A new hit extends the lock only if it's longer than what's left.

local maxLockSeconds = 8.0;
local moonShotDistance = 2000.0;  // Distance (Hammer units) from throw to hit that counts as a moon shot.
local minDistanceRatio = 0.1;     // Hits under 10% of moonShotDistance (point blank) don't lock anything.
local lockBraveJump = true;

::haleAbilityLockEnd <- {}; // boss -> Time() when the lock runs out

::LockHaleAbilities <- function(boss, seconds)
{
    local endTime = Time() + seconds;
    if (!(boss in haleAbilityLockEnd) || haleAbilityLockEnd[boss] < endTime)
        haleAbilityLockEnd[boss] <- endTime;
}

::GetHaleAbilityLockRemaining <- function(boss)
{
    if (!(boss in haleAbilityLockEnd))
        return 0;
    local remaining = haleAbilityLockEnd[boss] - Time();
    return remaining > 0 ? remaining : 0;
}

// Scout side: remember where each Sandman ball was thrown from, then lock Hale on hit.
characterTraitsClasses.push(class extends CharacterTrait
{
    function CanApply()
    {
        return player.GetPlayerClass() == TF_CLASS_SCOUT;
    }

    function OnFrameTickAlive()
    {
        local ball = null;
        while (ball = FindByClassname(ball, "tf_projectile_stun_ball"))
        {
            if (ball.GetOwner() != player && GetPropEntity(ball, "m_hThrower") != player)
                continue;
            ball.ValidateScriptScope();
            local scope = ball.GetScriptScope();
            if (!("vshLaunchPos" in scope))
                scope.vshLaunchPos <- ball.GetOrigin();
        }
    }

    function OnDamageDealt(victim, params)
    {
        if (!IsValidBoss(victim) || params.inflictor == null
            || params.inflictor.GetClassname() != "tf_projectile_stun_ball")
            return;

        local launchPos = player.GetOrigin();
        local scope = params.inflictor.GetScriptScope();
        if (scope != null && "vshLaunchPos" in scope)
            launchPos = scope.vshLaunchPos;

        local ratio = (victim.GetOrigin() - launchPos).Length() / moonShotDistance;
        if (ratio < minDistanceRatio)
            return;
        if (ratio > 1)
            ratio = 1;

        local seconds = maxLockSeconds * ratio;
        LockHaleAbilities(victim, seconds);

        ClientPrint(victim, 4, format("Abilities locked for %.1f seconds!", seconds));
        if (ratio >= 1)
        {
            local name = GetPropString(player, "m_szNetname");
            local color = player.GetTeam() == 2 ? "\x07FF3F3F" : "\x0799CCFF";
            ClientPrint(null, 3, color + name + " \x07FCD303moon shot \x01Hale! His abilities are locked for " + maxLockSeconds.tointeger() + " seconds.");
        }
    }
});

// Hale side: hold every ability's cooldown at the time left on the lock.
class SandmanLockTrait extends BossTrait
{
    function OnTickAlive(timeDelta)
    {
        local remaining = GetHaleAbilityLockRemaining(boss);
        if (remaining <= 0 || !(boss in characterTraits))
            return;

        foreach (trait in characterTraits[boss])
        {
            if ("lastFrameDownVelocity" in trait) // Mighty Slam
            {
                if (trait.meter > -remaining)
                    trait.meter = -remaining;
            }
            else if ("isCurrentlyDashing" in trait) // Sweeping Charge
            {
                if (trait.isCurrentlyDashing)
                    continue; // Let a dash already underway finish. Its cooldown is clamped next tick.
                if (trait.meter > 0)
                {
                    // Cancel a wind-up in progress.
                    DoEntFire("windup_vfx", "Kill", "", 0, null, null);
                    SetItemId(boss.GetActiveWeapon(), 5);
                    boss.RemoveCond(TF_COND_AIMING);
                    vsh_vscript.Hale_SetBlueArm(boss, false);
                    BossPlayViewModelAnim(boss, "f_idle");
                    trait.voiceTime = 0;
                    trait.midAirWindUpOverload = 0;
                }
                if (trait.meter > -remaining)
                    trait.meter = -remaining;
            }
            else if ("lockedUntil" in trait) // Saxton Punch (saxton_punch_kills.nut)
            {
                trait.lockedUntil = haleAbilityLockEnd[boss];
            }
        }
    }

    function OnFrameTickAlive()
    {
        if (!lockBraveJump || GetHaleAbilityLockRemaining(boss) <= 0 || !(boss in characterTraits))
            return;
        // Marking the current jump as already double-jumped stops Brave Jump from triggering.
        foreach (trait in characterTraits[boss])
            if ("jumpStatus" in trait && trait.jumpStatus == BOSS_JUMP_STATUS.CAN_DOUBLE_JUMP)
                trait.jumpStatus = BOSS_JUMP_STATUS.DOUBLE_JUMPED;
    }
}

AddBossTrait("saxton_hale", SandmanLockTrait);

AddListener("round_end", 5, function (winnerTeam)
{
    haleAbilityLockEnd.clear();
});
