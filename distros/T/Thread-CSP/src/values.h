SV* S_clone_value(pTHX_ SV* original);
#define clone_value(original) S_clone_value(aTHX_ original)

#define mark_clonable_stash(stash) (SvFLAGS(stash) |= SVphv_CLONEABLE)
#define mark_clonable_pvs(classname) mark_clonable_stash(gv_stashpvs(classname, GV_ADD))
