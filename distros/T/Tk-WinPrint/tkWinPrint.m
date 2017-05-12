#ifndef _TKWINPRINT_VM
#define _TKWINPRINT_VM
#include "tkWinPrint_f.h"
#ifndef NO_VTABLES
#ifndef PrintCanvasCmd
#  define PrintCanvasCmd (*TkwinprintVptr->V_PrintCanvasCmd)
#endif

#endif /* NO_VTABLES */
#endif /* _TKWINPRINT_VM */
