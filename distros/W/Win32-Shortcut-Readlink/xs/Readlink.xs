#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "win32sr.h"

MODULE = Win32::Shortcut::Readlink   PACKAGE = Win32::Shortcut::Readlink

maybe_string
_win32_resolve(link_name)
    maybe_string link_name
  CODE:
    RETVAL = resolve(link_name);
  OUTPUT:
    RETVAL
