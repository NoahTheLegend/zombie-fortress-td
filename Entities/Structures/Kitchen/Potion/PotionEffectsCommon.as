
const u8 potion_types = 7;
const string[] pool_crafts = {
    "0_slowness",
    "0_poison",
    "0_speed",
    "0_regen",
    "0_resistance",
    "0_weakness",
    "0_sickness",

    "1_slowness",
    "1_poison",
    "1_speed",
    "1_regen",
    "1_resistance",
    "1_weakness",
    "1_sickness",

    "2_slowness",
    "2_poison",
    "2_speed",
    "2_regen",
    "2_resistance",
    "2_weakness",
    "2_sickness"
};

const u8 potion_size = 3;
const string[] pool_components = {
    "wheatbunch",
    "nut",
    "grass",
    "bone"
};

s8 getEffectIndex(string effect)
{
    switch(effect.getHash())
    {
        case -1187361757:
        {
            return 0;
        }
        case -823974991:
        {
            return 1;
        }
        case 2072037248:
        {
            return 2;
        }
        case 16724762:
        {
            return 3;
        }
        case 364324608:
        {
            return 4;
        }
        case 13051022:
        {
            return 5;
        }
        case 1727513464:
        {
            return 6;
        }
    }

    return -1;
}