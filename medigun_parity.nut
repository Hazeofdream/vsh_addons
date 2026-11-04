// OVERRIDE: The stock Medi Gun and the Kritzkrieg work the same way. The only difference left
// is what the Über gives (invulnerability vs. crits).
//
// 1. Same build rate: both get exactly sharedUberRate. Base VSH's medic_uber_rate.nut already sets 2x
//    on every medigun, and that runtime attribute replaces the Kritzkrieg's built-in +25%. This sets it
//    again on both so they stay equal even if that base trait changes.
// 2. Full duration: TF2 drains a released Über faster after the Medic switches heal targets, which
//    cuts the Über short. While an Über is running, this holds the charge to a steady drain, so it lasts
//    exactly uberDuration seconds however often the Medic switches targets.
//
// The Quick-Fix and Vaccinator aren't affected.

local sharedUberRate = 2.0;  // Multiplier on stock build rate. Matches base VSH's 2x.
local uberDuration = 8.0;    // Seconds a full Über lasts. 8 is the TF2 default for both.

local kritzkriegId = 35;
local quickFixId = 411;
local vaccinatorId = 998;

characterTraitsClasses.push(class extends CharacterTrait
{
    medigun = null;
    releaseStartTime = null;
    releaseStartLevel = 0;

    function CanApply()
    {
        if (player.GetPlayerClass() != TF_CLASS_MEDIC)
            return false;
        local weapon = player.GetWeaponBySlot(TF_WEAPONSLOTS.SECONDARY);
        if (weapon == null || weapon.GetClassname() != "tf_weapon_medigun")
            return false;
        local id = GetPropInt(weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex");
        return id != quickFixId && id != vaccinatorId; // Stock (every skin) or Kritzkrieg.
    }

    function OnApply()
    {
        medigun = player.GetWeaponBySlot(TF_WEAPONSLOTS.SECONDARY);
        medigun.AddAttribute("ubercharge rate bonus", sharedUberRate, -1);
    }

    function OnTickAlive(timeDelta)
    {
        if (medigun == null || !medigun.IsValid())
            return;

        if (!GetPropBool(medigun, "m_bChargeRelease"))
        {
            releaseStartTime = null;
            return;
        }

        if (releaseStartTime == null)
        {
            releaseStartTime = Time();
            releaseStartLevel = GetPropFloat(medigun, "m_flChargeLevel");
            return;
        }

        local expected = releaseStartLevel - (Time() - releaseStartTime) / uberDuration;
        if (expected > 0)
            SetPropFloat(medigun, "m_flChargeLevel", expected);
    }
});
