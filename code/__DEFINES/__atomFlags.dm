/// This ATOM gets its proper icon after update icon / new has been called . This makes path2icon instantiate it and grab it from there
#define AF_ICONGRABNEEDSINSTANTATION (1<<1)
/// This atom's layer shouldn't adjust itself
#define AF_LAYER_UPDATE_HANDLED (1<<2)
/// This atom's plane shouldn't adjust itself
#define AF_PLANE_UPDATE_HANDLED (1<<3)
/// This atom should be able to always move however it wants with no restrictions(used for bullets after they hit.) It also isn't counted for any interactions regarding crossing , etc.
#define AF_VISUAL_MOVE (1<<4)
/// Our hitbox is offset by an attachment.
#define AF_HITBOX_OFFSET_BY_ATTACHMENT (1<<5)
#define AF_IGNORE_ON_BULLETSCAN (1<<6)
/// This atom will get ignored by explosions
#define AF_EXPLOSION_IGNORANT (1<<8)
/// Uses the aiming level for shooting at the shooter instead.
#define AF_PASS_AIMING_LEVEL (1<<9)
/// This is a wall-mounted atom and should be treated as such on initialization.
#define AF_WALL_MOUNTED (1<<10)
