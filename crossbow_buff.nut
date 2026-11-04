// NEW: Crusader's Crossbow (and Festive) shots are always critical,
// and every bolt that hits Hale adds ÜberCharge to the Medic's medigun.

local crossbowUberOnHit = 0.15; // 0.15 = 15% per hit on Hale

characterTraitsClasses.push(class extends CharacterTrait
{
    function CanApply()
    {
        return player.GetPlayerClass() == TF_CLASS_MEDIC;
    }

    function IsCrossbow(weapon)
    {
        return weapon != null && weapon.GetClassname() == "tf_weapon_crossbow";
    }

    // Crit-boost while the crossbow is out, the same way melee_buffs.nut crit-boosts melee.
    // Bolts fired during the boost fly as crits, with the crit glow and sound.
    function OnTickAlive(timeDelta)
    {
        if (IsCrossbow(player.GetActiveWeapon()))
            player.AddCondEx(TF_COND_CRITBOOSTED_ON_KILL, 0.13, null);
    }

    function OnDamageDealt(victim, params)
    {
        if (!IsBoss(victim) || !IsCrossbow(params.weapon))
            return;

        // Also crit any bolt that was fired just before the boost applied.
        params.crit_type = 2;

        local medigun = player.GetWeaponBySlot(TF_WEAPONSLOTS.SECONDARY);
        if (medigun == null || medigun.GetClassname() != "tf_weapon_medigun")
            return;
        // Don't extend an Über that is already running.
        if (GetPropBool(medigun, "m_bChargeRelease"))
            return;

        local charge = GetPropFloat(medigun, "m_flChargeLevel") + crossbowUberOnHit;
        SetPropFloat(medigun, "m_flChargeLevel", charge > 1.0 ? 1.0 : charge);
    }
});
