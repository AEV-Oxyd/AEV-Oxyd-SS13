/// These define the MAXIMUM height for a level (as in a standing human height is considered)
#define LEVEL_BELOW 0
#define LEVEL_TURF 0.3
#define LEVEL_LYING 0.6
#define LEVEL_LOWWALL 0.8
#define LEVEL_TABLE 1
#define LEVEL_LEGS 1
#define LEVEL_GROIN 1.1
#define LEVEL_CHEST 1.8
#define LEVEL_HEAD 2.1
#define LEVEL_ABOVE 3

// update these , using max() on defines wont give you constants
#define LEVEL_MAX 3
#define LEVEL_MIN 0

// return flags for aimingLevels ,this makes it so it uses the shooter's default aiming level , be it by their current level or def zone they are aiming at.
#define HBF_NOLEVEL -99999
#define HBF_USEMEDIAN -100000

#define PIXEL_FUDGE (1/1024)

proc/snapNum(n)
	. = n
	n = round(n,1)
	if(abs(.-n) < PIXEL_FUDGE) . = n


//  return flags for the hitboxDatum , with functionality implemented in bullet_act. passed under hitboxFlags
// these have no excuse to be general , add them for any object you want to add special functonality to with regards to where it is hit.
/// GENERAL
#define HB_AIMED 1<<1
/// mob/living/carbon/human and any subtypes
#define HB_HEAD 1<<2
#define HB_CHESTARMS 1<<3
#define HB_GROIN 1<<4
#define HB_LEGS 1<<5
// barricades and whatever object implements this
#define HB_WEAKPOINT 1<<6


