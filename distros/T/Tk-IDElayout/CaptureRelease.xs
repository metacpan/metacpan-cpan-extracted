
#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "tkGlue.def"

#include "pTk/tkPort.h"
#include "WmCaptureRelease.h"
#include "pTk/tkInt.h"
#include "pTk/tixPort.h"
#include "pTk/tixInt.h"
#include "tkGlue.h"
#include "tkGlue.m"
#include "pTk/tkVMacro.h"


DECLARE_VTABLES;



MODULE = Tk::CaptureRelease	PACKAGE = Tk::CaptureRelease

PROTOTYPES: DISABLE

BOOT:
 {
  IMPORT_VTABLES;
  /* Initialize the display item types */
  Lang_TkSubCommand("_wm",WmCaptureReleaseCmd);
 }
