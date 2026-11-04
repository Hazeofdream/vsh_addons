local punchIntervalLowHealth = 0.5;   // Fraction of max HP Hale must lose per punch, while max HP is at or under the threshold.
local punchIntervalHighHealth = 0.3;  // Fraction of max HP per punch once max HP is above the threshold.
local highHealthThreshold = 10000;
local haleCapPunchCooldown = 60;       // Once Hale captures the point, he also gets a punch every this many seconds.

// OVERRIDE: Saxton Punch charges from damage Hale takes instead of a 30s timer.
// Every punchInterval of max HP lost earns one punch. Punches bank: if Hale earns two before using
// one, he can throw both. Healing doesn't take progress away.
// After Hale captures the point (haleBuff), he also gets a free punch every haleCapPunchCooldown seconds.
// meter stays 0 while a punch is ready and -1 otherwise, so base code that checks meter still works.

SaxtonPunchTrait.damageTaken <- 0;
SaxtonPunchTrait.lastHealth <- 0;
SaxtonPunchTrait.punchesUsed <- 0;
SaxtonPunchTrait.capTimer <- 0;
SaxtonPunchTrait.lockedUntil <- 0; // Set by sandman_lock.nut. Banked punches are kept while locked.

function SaxtonPunchTrait::IsLocked()
{
    return Time() < lockedUntil;
}

function SaxtonPunchTrait::OnApply()
{
    meter = -1;
    lockedUntil = 0;
    damageTaken = 0;
    lastHealth = 0;
    punchesUsed = 0;
    capTimer = -haleCapPunchCooldown;
    if (!(player in hudAbilityInstances))
        hudAbilityInstances[player] <- [];
    hudAbilityInstances[player].push(this);
}

function SaxtonPunchTrait::PunchInterval()
{
    local maxHp = boss.GetMaxHealth();
    return maxHp * (maxHp > highHealthThreshold ? punchIntervalHighHealth : punchIntervalLowHealth);
}

function SaxtonPunchTrait::PunchesAvailable()
{
    return floor(damageTaken / PunchInterval()).tointeger() - punchesUsed;
}

// Progress toward the next punch, 0.0 to 1.0.
function SaxtonPunchTrait::PunchProgress()
{
    local interval = PunchInterval();
    return (damageTaken - floor(damageTaken / interval) * interval) / interval;
}

function SaxtonPunchTrait::CapPunchReady()
{
    return haleBuff && capTimer >= 0;
}

// Total punches ready right now, from damage and from the post-capture timer.
function SaxtonPunchTrait::PunchesReady()
{
    return PunchesAvailable() + (CapPunchReady() ? 1 : 0);
}

// Progress toward whichever punch source fills first, 0.0 to 1.0.
function SaxtonPunchTrait::NextPunchProgress()
{
    local progress = PunchProgress();
    if (haleBuff)
    {
        local capProgress = 1.0 + capTimer / haleCapPunchCooldown;
        if (capProgress > progress)
            progress = capProgress;
    }
    return progress;
}

function SaxtonPunchTrait::OnTickAlive(timeDelta)
{
    local health = boss.GetHealth();
    if (IsRoundSetup())
    {
        lastHealth = health;
        return;
    }
    if (lastHealth > 0 && health < lastHealth)
        damageTaken += lastHealth - health;
    lastHealth = health;

    if (haleBuff && capTimer < 0)
        capTimer += timeDelta;

    if (IsLocked())
    {
        if (meter == 0)
        {
            meter = -1;
            vsh_vscript.Hale_SetRedArm(boss, false);
            boss.RemoveCond(TF_COND_CRITBOOSTED);
        }
        return;
    }

    if (meter < 0 && PunchesReady() > 0)
    {
        meter = 0;
        vsh_vscript.Hale_SetRedArm(boss, true);
        EmitPlayerVO(boss, "saxton_punch_ready");
        BossPlayViewModelAnim(boss, "vsh_megapunch_ready");
        boss.AddCond(TF_COND_CRITBOOSTED);
    }
}

function SaxtonPunchTrait::Perform(victim)
{
    if (IsLocked())
        return false;

    // Spend the timer punch first so damage-earned punches stay banked.
    if (CapPunchReady())
        capTimer = -haleCapPunchCooldown;
    else if (PunchesAvailable() > 0)
        punchesUsed++;
    else
        return false;

    // Keep the red arm and crits if another punch is still banked.
    if (PunchesReady() <= 0)
    {
        meter = -1;
        vsh_vscript.Hale_SetRedArm(boss, false);
        boss.RemoveCond(TF_COND_CRITBOOSTED);
    }

    local haleEyeVector = boss.EyeAngles().Forward();
    haleEyeVector.Norm();

    EmitSoundOn("TFPlayer.CritHit", boss);
    EmitSoundOn("vsh_sfx.saxton_punch", boss);
    if (GetAliveMercCount() > 1)
        EmitPlayerVO(boss, "saxton_punch");
    DispatchParticleEffect("vsh_megapunch_shockwave", victim.EyePosition(), QAngle(0,boss.EyeAngles().Yaw(),0).Forward());
    ScreenShake(boss.GetCenter(), 10, 2.5, 1, 1000, 0, true);

    CreateAoE(boss.GetCenter(), 600,
        function (target, deltaVector, distance) {
            local dot = haleEyeVector.Dot(deltaVector);
            if (dot < 0.6)
                return;
            local damage = target.GetMaxHealth() * (0.7 - distance / 2000);
            if (!target.IsPlayer())
                damage *= 2;
            custom_dmg_saxton_punch_aoe.SetAbsOrigin(boss.GetOrigin());
            target.TakeDamageEx(
                custom_dmg_saxton_punch_aoe,
                boss,
                boss.GetActiveWeapon(),
                deltaVector * 1250,
                boss.GetOrigin(),
                damage,
                DMG_BLAST);
        }
        function (target, deltaVector, distance) {
            local dot = haleEyeVector.Dot(deltaVector);
            if (dot < 0.6)
                return;
            local pushForce = distance < 100 ? 10 : 10 / sqrt(distance);
            deltaVector.x = deltaVector.x * 1250 * pushForce;
            deltaVector.y = deltaVector.y * 1250 * pushForce;
            deltaVector.z = 750 * pushForce;
            target.Yeet(deltaVector);
        });
    return true;
}

function SaxtonPunchTrait::MeterAsPercentage()
{
    if (IsLocked())
        return 0;
    if (PunchesReady() > 0)
        return 200;
    return NextPunchProgress() * 90;
}

// OVERRIDE: Ability HUD. Punch slot shows % progress to the next punch, e.g. "₃₇ ▰▰▱▱▱▱▱",
// or a check mark plus the banked count when ready, e.g. "✔ ₂ ▰▰▰▰▰▰▰".

function AbilityHudTrait::OnTickAlive(timeDelta)
{
    if (!(player in hudAbilityInstances))
        return;

    local progressBarTexts = [];
    local overlay = "";
    foreach(ability in hudAbilityInstances[player])
    {
        local percentage = ability.MeterAsPercentage();
        local progressBarText;
        // SaxtonPunchTrait isn't visible from inside class methods at runtime, so detect it by its method.
        if ("PunchProgress" in ability)
        {
            local available = ability.PunchesReady();
            local filled;
            if (ability.IsLocked())
            {
                // Locked by a Sandman ball: show seconds left on the lock and an empty bar.
                local secondsLeft = ceil(ability.lockedUntil - Time()).tointeger();
                progressBarText = BigToSmallNumbers(secondsLeft.tostring()) + " ";
                filled = 0;
            }
            else if (available > 0)
            {
                progressBarText = BigToSmallNumbers("r") + (available > 1 ? " " + BigToSmallNumbers(available.tostring()) : "") + " ";
                filled = 7;
            }
            else
            {
                local progress = ability.NextPunchProgress();
                progressBarText = BigToSmallNumbers((progress * 100).tointeger().tostring()) + " ";
                filled = (progress * 7).tointeger();
            }
            for(local i = 0; i < 7; i++)
                progressBarText += i < filled ? "▰" : "▱";
        }
        else
        {
            progressBarText = BigToSmallNumbers(ability.MeterAsNumber())+" ";
            local i = 13;
            for(; i < clampCeiling(100, percentage); i+=13)
                progressBarText += "▰";
            for(; i <= 100; i+=13)
                progressBarText += "▱";
        }
        progressBarTexts.push(progressBarText);
        if (percentage >= 100)
            overlay += "1";
        else
            overlay += "0";
    }
    if (braveJumpCharges >= 2)
        overlay += "0";
    else
        overlay += cos(Time() * 12) < 0 ? "1" : "2";

    SetPropString(game_text_charge, "m_iszMessage", progressBarTexts[0]);
    game_text_charge.AcceptInput("Display", "", boss, boss);

    SetPropString(game_text_punch, "m_iszMessage", progressBarTexts[1]);
    game_text_punch.AcceptInput("Display", "", boss, boss);

    SetPropString(game_text_slam, "m_iszMessage", progressBarTexts[2]);
    game_text_slam.AcceptInput("Display", "", boss, boss);

    player.SetScriptOverlayMaterial(API_GetString("ability_hud_folder") + "/" + overlay);
}
