/// ATFS - Attachment flags for the supporting atom
/// If the supporter is marked for deletion/deleted , also delete the attached atoms. Default behaviour
#define ATFS_DELETE_RECURSIVE (1<<0)
/// Will detach all attached atoms and drop them on the turf
#define ATFS_DROP_ATTACHED (1<<1)

/// ATFA - Attachment flags for the attached atom
/// We can be detached from the wall(either through a interaction or verb)
#define ATFA_DETACHABLE (1<<0)
/// This is embedded into the wall , removeable using surgical clamps or pliers, and not by normal means.
#define ATFA_EMBEDDED (1<<1)
/// The player must be next to the wall to interact with the attached
#define ATFA_CLOSE_INTERACTIVE (1<<2)
/// Player has to be near the turf the attached is facing to interact with it. Default behaviour
#define ATFA_EASY_INTERACTIVE (1<<3)


