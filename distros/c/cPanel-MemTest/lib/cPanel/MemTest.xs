#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/types.h>

#ifdef __cplusplus
}
#endif

MODULE = cPanel::MemTest                PACKAGE = cPanel::MemTest

PROTOTYPES: ENABLE

int
testallocate(megabytes)
    int megabytes

    PREINIT:
        int megallocated = 0;
        int *mem[1024];
        int i;
        
        CODE:
        if (megabytes > 1024 || megabytes < 1) {
            warn("Unable to allocate %d Megabytes of memory (Invalid Argument)",megabytes);
            RETVAL = 0;
        } else {
            for(i = 0;i < 1024;i++) {
                mem[i] = malloc(1024*1024);
                if (mem[i] == NULL) {
                    warn("Error while allocating memory! %d Megabytes already allocated",megallocated);
                    break;
                }
                megallocated += 1;
                if (megallocated >= megabytes) { break; } 
            }

            RETVAL = megallocated;

            for(i = 0;i < 1024;i++) {
                free(mem[i]);
                megallocated -= 1;
                if (megallocated <= 0) { break; } 
            }
        }

    OUTPUT:
        RETVAL
