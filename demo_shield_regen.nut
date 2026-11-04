// OVERRIDE: Demoman's shield comes back after collecting 6 heads since it was destroyed.
// demo_shield.nut breaks the shield once per life (wasDestroyed) and hides the wearable.
// This resets that trait and redraws the shield, so it can block another hit.

local headsToRestoreShield = 6;

characterTraitsClasses.push(class extends CharacterTrait
{
    shieldTrait = null;
    headsAtBreak = null;

    function CanApply()
    {
        return player.GetPlayerClass() == TF_CLASS_DEMOMAN;
    }

    function OnApply()
    {
        // Pushed after the base traits, so the shield trait is already applied.
        foreach (trait in characterTraits[player])
            if ("wasDestroyed" in trait)
            {
                shieldTrait = trait;
                break;
            }
    }

    function OnTickAlive(timeDelta)
    {
        if (shieldTrait == null || !shieldTrait.wasDestroyed)
            return;

        local heads = GetPropInt(player, "m_Shared.m_iDecapitations");
        if (headsAtBreak == null)
            headsAtBreak = heads;
        if (heads - headsAtBreak < headsToRestoreShield)
            return;

        headsAtBreak = null;
        shieldTrait.wasDestroyed = false;

        local wearable = null;
        while (wearable = FindByClassname(wearable, "tf_wearable_demo*"))
            if (wearable.GetOwner() == player)
            {
                wearable.EnableDraw();
                break;
            }
    }
});
