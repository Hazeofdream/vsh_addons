// OVERRIDE: Undo VSH's Heavy minigun nerfs.
//  - heavy_minigun_nerf.nut: crit-boosted primary damage *0.7
//  - heavy_natasha_nerf.nut: Natascha slow on hit reduced to 0.15
// Pushed after the base traits, so OnApply runs after theirs.

local minigunCritNerf = 0.3;

characterTraitsClasses.push(class extends CharacterTrait
{
    primary = null;
    function CanApply()
    {
        return player.GetPlayerClass() == TF_CLASS_HEAVY;
    }

    function OnApply()
    {
        primary = player.GetWeaponBySlot(TF_WEAPONSLOTS.PRIMARY);
        // Removing the runtime override restores Natascha's stock slow.
        if (WeaponIs(primary, "natasha"))
            primary.RemoveAttribute("slow enemy on hit");
    }

    function OnDamageDealt(victim, params)
    {
        if (params.weapon == primary && player.IsCritBoosted())
            params.damage /= minigunCritNerf;
    }
});
