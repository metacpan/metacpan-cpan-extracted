#ifndef TKWINPRINT_VT
#define TKWINPRINT_VT
typedef struct TkwinprintVtab
{
    /*  void (*V_PrintCanvasCmd) _ANSI_ARGS_((TkCanvas *canvasPtr,
					Tcl_Interp *interp,
					int argc, Arg *argv));*/
  void (*V_PrintCanvasCmd) _ANSI_ARGS_((TkCanvas *canvasPtr,
					Tcl_Interp *interp
				       ));
} TkwinprintVtab;
extern TkwinprintVtab *TkwinprintVptr;
extern TkwinprintVtab *TkwinprintVGet _ANSI_ARGS_((void));
#endif /* TKWINPRINT_VT */
