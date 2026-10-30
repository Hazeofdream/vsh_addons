local stunBreakoutTimeThreshold = 2;
local stunBreakoutHealthThreshold = 3000;

// OVERRIDE: Hale breaks out of a stun after losing 3000 HP instead of 1000.

function StunBreakoutTrait::OnTickAlive(timeDelta)
{
    if (boss.IsControlStunned() || (Time() - holidayPunchTimeStamp <= 4 && boss.InCond(TF_COND_TAUNTING)))
    {
        stunTimer += timeDelta;

        if (stunInitHealth == 0)
            stunInitHealth = boss.GetHealth();
        else if (boss.GetHealth() < stunInitHealth - stunBreakoutHealthThreshold)
        {
            DoBreakOut();
            return;
        }
    }
    else if (stunTimer > 0)
        stunTimer -= timeDelta;
    if (stunTimer < 0)
    {
        stunTimer = 0;
        stunInitHealth = 0;
    }

    if (stunTimer >= stunBreakoutTimeThreshold)
        DoBreakOut();
}