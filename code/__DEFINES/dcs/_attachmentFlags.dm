
/// This denotes that we are attached to a supporting atom
#define ATFA_ATTACHED (0<<0)
/// This denotes that we are a supporting atom to the thing attached to us
#define ATFS_SUPPORTER (1<<0)

/// ATFS - Attachment flags for the supporting atom
/// DEPENDING on wheter its an attached or a supporter, the bitflags change meaning
/// If the supporter is marked for deletion/deleted , also delete the attached atoms. Default behaviour
#define ATFS_DELETE_RECURSIVE (1<<1)
/// Will detach all attached atoms and drop them on the turf
#define ATFS_DROP_ATTACHED (1<<2)
/// The supporting atom shall relay signals to all its attached atoms
#define ATFS_RELAY_SIGNALS (1<<3)
/// This will cause all attached atoms to be checked first for hitbox collisions instead of us
#define ATFS_PRIORITIZE_ATTACHED_FOR_HITS (1<<4)
/// This will make all bullets ignore the attached atom
#define ATFS_IGNORE_HITS (1<<5)

/// ATFA - Attachment flags for the attached atom
/// This denotes that we are holding onto the supporting atom.
#define ATFA_HOLDING (1<<1)
/// We can be detached from the wall(either through a interaction or verb)
#define ATFA_DETACHABLE (1<<2)
/// This is embedded into the wall , removeable using surgical clamps or pliers, and not by normal means.
#define ATFA_EMBEDDED (1<<3)
/// The player must be next to the wall to interact with the attached
#define ATFA_CLOSE_INTERACTIVE (1<<4)
/// Player has to be near the turf the attached is facing to interact with it. Default behaviour
#define ATFA_EASY_INTERACTIVE (1<<5)
/// This can only be hit if the bullets come from the direction it is facing or if they are penetrating  ,but otherwise not.
#define ATFA_DIRECTIONAL_HITTABLE_STRICT (1<<6)
/// The bullet can come from any axis that shares a direction bit-flag with ourselves
#define ATFA_DIRECTIONAL_HITTABLE (1<<7)
/// Will force any hit-checking to be relatively offset by our position compared to the supporting atom.
#define ATFA_CENTER_ON_SUPPORTER (1<<8)
