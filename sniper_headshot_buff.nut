// OVERRIDE: Sniper headshots deal 1.8x damage instead of 1.2x.
// The base sniper_head_collecting.nut trait is an unnamed class, so it can't be overridden directly.
// It still applies its 1.2x (and its +1 head per headshot); this trait stacks on top to reach the new total.
// With Hale's 0.75x crit resistance, headshots end up at 1.35x a normal crit.

local baseHeadshotMultiplier = 1.2;
local newHeadshotMultiplier = 1.8;

characterTraitsClasses.push(class extends CharacterTrait
{
    function CanApply()
    {
        return player.GetPlayerClass() == TF_CLASS_SNIPER;
    }

    function OnDamageDealt(victim, params)
    {
        if (params.damage_custom == TF_DMG_CUSTOM_HEADSHOT)
            params.damage *= newHeadshotMultiplier / baseHeadshotMultiplier;
    }
});
