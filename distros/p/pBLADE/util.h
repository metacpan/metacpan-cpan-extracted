#ifndef _BLADE_PM_UTIL_H
#define _BLADE_PM_UTIL_H

void move_to_argv(SV *args_ref, int *argc, char ***argv);
void move_to_array(SV *args_ref, int argc, char **argv);

#endif /* _BLADE_PM_UTIL_H */
