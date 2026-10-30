// OVERRIDE: Sentry damage to Hale.
// engineer_sentry.nut scales sentry damage by 0.5 (mini-sentries 0.8).
// This rescales it so sentries deal 80% and mini-sentries deal full damage.
// Knockback scales with damage, so it follows the same values.

local vshSentryMult = 0.5;
local vshMiniSentryMult = 0.8;
local newSentryMult = 0.8;
local newMiniSentryMult = 1.0;

characterTraitsClasses.push(class extends CharacterTrait
{
    usingMiniSentry = false;

    function CanApply()
    {
        if (player.GetPlayerClass() == TF_CLASS_ENGINEER)
        {
            local melee = player.GetWeaponBySlot(TF_WEAPONSLOTS.MELEE);
            usingMiniSentry = melee && melee.GetClassname() == "tf_weapon_robot_arm";
            return true;
        }
        return false;
    }

    function OnDamageDealt(victim, params)
    {
        if (params.inflictor != null && params.inflictor.GetClassname() == "obj_sentrygun" && player != victim)
            params.damage *= usingMiniSentry ? newMiniSentryMult / vshMiniSentryMult : newSentryMult / vshSentryMult;
    }
});
