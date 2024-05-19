/// These define the MAXIMUM height for a level (as in a standing human height is considered)
#define LEVEL_BELOW 0
#define LEVEL_TURF 0.5
#define LEVEL_LYING 0.7
#define LEVEL_LOWWALL 1
#define LEVEL_TABLE 1.2
#define LEVEL_GROIN 1.3
#define LEVEL_CHEST 1.5
#define LEVEL_STANDING 1.7
#define LEVEL_ABOVE 2

// return flags for aimingLevels ,this makes it so it uses the shooter's default aiming level , be it by their current level or def zone they are aiming at.
#define HBF_NOLEVEL -99999
#define HBF_USEMEDIAN -100000


//  return flags for the hitboxDatum , with functionality implemented in bullet_act. passed under hitboxFlags
// these have no excuse to be general , add them for any object you want to add special functonality to with regards to where it is hit.

/// mob/living/carbon/human and any subtypes
#define HB_HEAD 1<<1
#define HB_CHESTARMS 1<<2
#define HB_GROIN 1<<3
#define HB_LEGS 1<<4
