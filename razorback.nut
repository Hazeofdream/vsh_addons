// NEW: Sniper's Razorback blocks one hit from Hale.
// The shield breaks on the first Hale hit, which then does no damage at all.
// Picking up a medium or large ammo pack restores it.
// Modeled on the base demo_shield.nut trait.

local razorbackMinBlockDamage = 5;      // Ignore chip damage (stun breakout AoE deals 1) so it doesn't burn the shield.
local razorbackIgnoreDamageAbove = 99998; // Losing RPS to Hale deals 99999. Don't let the shield save you from that.

PrecacheArbitrarySound("vsh_sfx.shield_break");

::FindRazorback <- function(player)
{
    local wearable = null;
    while (wearable = FindByClassname(wearable, "tf_wearable_razorback"))
        if (wearable.GetOwner() == player)
            return wearable;
    return null;
}

characterTraitsClasses.push(class extends CharacterTrait
{
    isRazorbackTrait = true;
    isBroken = false;

    function CanApply()
    {
        if (player.GetPlayerClass() != TF_CLASS_SNIPER)
            return false;
        local wearable = FindRazorback(player);
        if (wearable == null)
            return false;
        wearable.EnableDraw();
        return true;
    }

    function OnDamageTaken(attacker, params)
    {
        if (isBroken || !IsValidBoss(attacker) || player.InCond(TF_COND_INVULNERABLE))
            return;
        if (params.damage < razorbackMinBlockDamage || params.damage > razorbackIgnoreDamageAbove)
            return;

        isBroken = true;
        params.damage = 0;
        params.damage_force = Vector(0, 0, 0);
        params.early_out = true;

        local wearable = FindRazorback(player);
        if (wearable != null)
            wearable.DisableDraw();

        EmitSoundOn("vsh_sfx.shield_break", player);
    }

    function Restore()
    {
        if (!isBroken)
            return;
        isBroken = false;

        local wearable = FindRazorback(player);
        if (wearable != null)
            wearable.EnableDraw();

        EmitSoundOnClient("TFPlayer.ReCharged", player);
    }
});

// The game only fires this when a pack is actually picked up, so a Sniper with full ammo won't take one.
// "item" is the pack's name, e.g. "ammopack_medium" or "item_ammopack_full", so check by substring.
function OnGameEvent_item_pickup(params)
{
    if (IsNotValidRound())
        return;
    local player = GetPlayerFromParams(params);
    if (!IsValidPlayer(player) || !(player in characterTraits))
        return;

    local item = params.item;
    if (item.find("ammopack_medium") == null
        && item.find("ammopack_large") == null
        && item.find("ammopack_full") == null)
        return;

    foreach (trait in characterTraits[player])
        if ("isRazorbackTrait" in trait)
            trait.Restore();
}
