// OVERRIDE: Remove Hale's debuff resistance.
// DebuffResistanceTrait drained an extra timeDelta off Jarate and Marked for Death each tick,
// halving their duration. Those were its only conditions, so it now does nothing.

function DebuffResistanceTrait::OnTickAlive(timeDelta)
{
}
