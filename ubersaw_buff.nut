// OVERRIDE: Ubersaw (and Festive Ubersaw) adds 50% ÜberCharge per hit instead of 25%.

local ubersawUberOnHit = 0.5;

characterTraitsClasses.push(class extends CharacterTrait
{
    function CanApply()
    {
        return player.GetPlayerClass() == TF_CLASS_MEDIC;
    }

    function OnApply()
    {
        local melee = player.GetWeaponBySlot(TF_WEAPONSLOTS.MELEE);
        if (WeaponIs(melee, "ubersaw") || WeaponIs(melee, "ubersaw_xmas"))
            melee.AddAttribute("add uber charge on hit", ubersawUberOnHit, -1);
    }
});
