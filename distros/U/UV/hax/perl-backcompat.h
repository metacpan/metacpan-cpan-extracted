/* vi: set ft=c */

/* needed for compatibility with perls 5.14 and older */
#ifndef newCONSTSUB_flags
#  define newCONSTSUB_flags(stash, name, len, flags, sv) newCONSTSUB((stash), (name), (sv))
#endif
