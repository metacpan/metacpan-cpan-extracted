#include "EXTERN.h"
#include "perl.h"

void
move_to_array(SV *args_ref, int argc, char **argv) {

  AV *args;
  int i;

  if (argc > 1) {

    args = (AV*)SvRV(args_ref);
 
    for (i=1; i<argc; i++) {
      SV* tmp = sv_2mortal(newSVpv(argv[i], 0));
      av_push(args, tmp);
      free(argv[i]);
    }

    free(argv);
 }

}
    
void
move_to_argv(SV *args_ref, int *argc, char ***argv) {

  AV *args = NULL;
  int i;

  /*
   * ensure first arg is array ref
   */
  if (args_ref != &PL_sv_undef && (!SvROK(args_ref) || SvTYPE(SvRV(args_ref)) != SVt_PVAV))
    croak("move_to_argv() - first argument must be undef or array ref");

  /*
   * store number of arguments in output
   */
  *argc = 1;
  if (args_ref != &PL_sv_undef) {
    args = (AV*)SvRV(args_ref);
    *argc += av_len(args) + 1;
  }

  if (!(*argv = calloc(*argc, sizeof(char**))))
    croak("move_to_argv() - out of memory, calloc()");

  /*  (*argv)[0] = "perl"; */
  (*argv)[0] = SvPV(perl_get_sv("main::0", FALSE),PL_na);

  for (i=1; i<*argc; i++) {
    SV **tmp = av_fetch(args, i-1, 0);
    if (tmp == NULL)
      continue;

    if (!((*argv)[i] = malloc(strlen(SvPV(*tmp, PL_na))+1)))
      croak("move_to_argv() - out of memory, malloc()");

    strcpy((*argv)[i],SvPV(*tmp,PL_na));
  }

  /* clear input array */
  if (args_ref != &PL_sv_undef)
    av_clear(args);

}

