#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "hook.h"
#include "send_string.h"

MODULE = Win32::Shortkeys::Kbh               PACKAGE = Win32::Shortkeys::Kbh

PROTOTYPES: DISABLE

void
msg_loop()

void
register_hook()

void
unregister_hook()

void
quit()

void
send_string(s)
     const wchar_t * s

void
send_cmd(howmutch, vkcode)
    int howmutch
    byte vkcode

void
paste_from_clpb(dk)
    int dk


