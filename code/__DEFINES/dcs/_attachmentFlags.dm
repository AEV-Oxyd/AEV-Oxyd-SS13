/// ATFS - Attachment flags for the supporting atom
/// This denotes that we are a supporting atom to the thing attached to us
#define ATFS_SUPPORTER (1<<0)
/// If the supporter is marked for deletion/deleted , also delete the attached atoms. Default behaviour
#define ATFS_DELETE_RECURSIVE (1<<1)
/// Will detach all attached atoms and drop them on the turf
#define ATFS_DROP_ATTACHED (1<<2)
/// The supporting atom shall relay signals to all its attached atoms
#define ATFS_RELAY_SIGNALS (1<<3)

/// ATFA - Attachment flags for the attached atom
/// This denotes that we are holding onto the supporting atom.
#define ATFA_HOLDING (1<<4)
/// We can be detached from the wall(either through a interaction or verb)
#define ATFA_DETACHABLE (1<<5)
/// This is embedded into the wall , removeable using surgical clamps or pliers, and not by normal means.
#define ATFA_EMBEDDED (1<<6)
/// The player must be next to the wall to interact with the attached
#define ATFA_CLOSE_INTERACTIVE (1<<7)
/// Player has to be near the turf the attached is facing to interact with it. Default behaviour
#define ATFA_EASY_INTERACTIVE (1<<8)
/// This can only be hit if the bullets come from the direction it is facing or if they are penetrating  ,but otherwise not.
#define ATFA_DIRECTIONAL_HITTABLE (1<<9)
