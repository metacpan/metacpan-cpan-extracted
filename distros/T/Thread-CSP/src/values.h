SV* S_clone_value(pTHX_ SV* original, PerlInterpreter* other);
#define clone_value(original, other) S_clone_value(aTHX_ original, other)

#define mark_clonable_stash(stash) (SvFLAGS(stash) |= SVphv_CLONEABLE)
#define mark_clonable_pvs(classname) mark_clonable_stash(gv_stashpvs(classname, GV_ADD))
