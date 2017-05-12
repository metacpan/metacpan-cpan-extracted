#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <unistd.h>
#include <sys/types.h>

#ifdef HAS_SYSMKDEV
#include <sys/mkdev.h>
#endif

#ifdef __cplusplus
}
#endif

MODULE = Unix::Mknod	PACKAGE = Unix::Mknod

dev_t
major(dev_t dev)
	PROTOTYPE: $

dev_t
minor(dev_t dev)
	PROTOTYPE: $

dev_t
makedev(dev_t major, dev_t minor)
	PROTOTYPE: $;$

int
mknod(filename, mode, dev)
     char *         filename
     mode_t         mode
     dev_t          dev
    CODE:
     TAINT_PROPER("mknod");
     RETVAL = mknod(filename, mode, dev);
    OUTPUT:
     RETVAL
