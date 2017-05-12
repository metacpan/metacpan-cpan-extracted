#include "tkWinPrint.h"
#include "tkWinPrint_f.h"
static TkwinprintVtab TkwinprintVtable =
{
  PrintCanvasCmd
};
TkwinprintVtab *TkwinprintVptr;
TkwinprintVtab *TkwinprintVGet() { return TkwinprintVptr = &TkwinprintVtable;}
