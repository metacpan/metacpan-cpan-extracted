#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "mandel.h"

MODULE = Fractal PACKAGE = Fractal 

int 
draw_mandel (filename, width, height, origin_real,origin_imag, range,depth)
        char*  filename
        int    width
        int    height
        double origin_real
        double origin_imag
        double range
        double depth


