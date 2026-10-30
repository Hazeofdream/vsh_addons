local saxtonPunchKillsRequired = 5;

// OVERRIDE: Saxton Punch charges from kills instead of a 30s timer.
// meter counts up from -saxtonPunchKillsRequired to 0 (ready), one per kill.

function SaxtonPunchTrait::OnApply()
{
    meter = -saxtonPunchKillsRequired;
    if (!(player in hudAbilityInstances))
        hudAbilityInstances[player] <- [];
    hudAbilityInstances[player].push(this);
}

function SaxtonPunchTrait::OnTickAlive(timeDelta)
{
    // No passive recharge.
}

function SaxtonPunchTrait::OnKill(victim, params)
{
    if (meter >= 0 || victim == player || !IsPlayerAlive(boss))
        return;
    meter++;
    if (meter >= 0)
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
    if (meter != 0)
        return false;
    meter = -saxtonPunchKillsRequired;

    vsh_vscript.Hale_SetRedArm(boss, false);

    local haleEyeVector = boss.EyeAngles().Forward();
    haleEyeVector.Norm();

    boss.RemoveCond(TF_COND_CRITBOOSTED);
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

// Update the meter to show kills remaining

function SaxtonPunchTrait::MeterAsPercentage()
{
    if (meter < 0)
        return (saxtonPunchKillsRequired + meter) * 90 / saxtonPunchKillsRequired;
    return 200;
}

function SaxtonPunchTrait::KillsDone()
{
    return saxtonPunchKillsRequired + meter;
}

// OVERRIDE: Ability HUD. Punch slot shows "kills/required" and one pip per kill, e.g. "2/5 ▰▰▱▱▱".

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
        if ("KillsDone" in ability)
        {
            local killsDone = ability.KillsDone();
            if (killsDone >= saxtonPunchKillsRequired)
                progressBarText = BigToSmallNumbers("r") + " ";
            else
                progressBarText = format("%d/%d ", killsDone, saxtonPunchKillsRequired);
            for(local i = 0; i < saxtonPunchKillsRequired; i++)
                progressBarText += i < killsDone ? "▰" : "▱";
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
