#include <math.h>
#include <stdio.h>
#include <gd.h>
typedef struct {
    double r, i;
} complex;


int 
draw_mandel (char *filename,
              int    width, int height,
              double origin_real,
              double origin_imag,
              double range,
              double max_iterations)
{
    complex origin;
    int colors[100], color, white, x, y, i;
    FILE *out;
    gdImagePtr im_out;

    origin.r = origin_real;  /* Measured from top-left */
    origin.i = origin_imag;  
    if (!(out = fopen(filename, "wb"))) {
        fprintf(stderr, "File %s could not be opened\n");
            return 1;
    }
        
    im_out = gdImageCreate(width, height);
    /* Start from black, and increment r,g,b values to get different
       values of gray. */
    for (i = 0; i < 50; i++) {
            color = i * 4;
            colors[i] = gdImageColorAllocate(im_out, color,color,color);
    }
    white =        gdImageColorAllocate(im_out, 255,255,255);

    for (y = 0; y < height; y++) {
        for (x = 0; x < width; x++) {
            complex z, c ;
            int  iter;

           /* Convert every point on the canvas to an equivalent
            *  complex number, given the origin and the range. The
            *  range acts like an inverse zoom factor.*/
            c.r = origin.r + (double) x / (double) width * range;
            c.i = origin.i - (double) y / (double) height * range;

           /* Examine each point calculated above to see if 
            * repeated substitutions into an equation like
            * z(next) = z**z + z remains within a definite boundary.
            * If after a <max_iterations> iterations it still hasn't gone
            * beyond the white area, it belongs to the Mandelbrot set.
            * But if it does, we assign it a color depending on how
            * quickly it quit. So the points that don't belong to
            * the Mandelbrot set are the ones that give it its infinitely
            * recursive beauty. */
            color = white;
            z.r = z.i = 0.0; /* Starting point */
            for (iter = 0; iter < max_iterations; iter++) {
                double dist, new_real, new_imag;
                /*calculate  z = z^2 + c */
                /* If z = a + bi, z^2 => a^2 - b^2 + 2abi; */
                new_real = z.r * z.r - z.i * z.i + c.r;
                new_imag = 2 * z.r * z.i + c.i;
                z.r = new_real; z.i = new_imag;
                /* Pythagorean distance from 0,0 */
                dist = new_real * new_real + new_imag * new_imag; 
                if (dist >= 4) {
                    /* No point on the mandelbrot set is more than
                       2 units away from the origin. If it quits
                       the boundary, give that 'c' an interesting 
                       color, depending on how far the series wants
                       to jump out of its bounds */
                    color = colors[(int) dist % i];
                    break;
                }
            }
            gdImageSetPixel(im_out, x,y, color);

        }
    }
    gdImageGif(im_out,out);
    fclose(out);
    return 0;
}

#ifdef TESTING
main(int  argc, char **argv) {
        
        draw_fractal ("fractal.gif",       /* Good values     */
                                  atoi(argv[1]),           /* Width          = 300  */          
                                  atoi(argv[2]),           /* Height         = 300  */
                                  atof(argv[3]),           /* Origin.r       = -1.4 */
                                  atof(argv[4]),           /* Origin.i       = 1.0  */
                                  atof(argv[5]),           /* Range          = 2.0  */
                                  atof(argv[6]));           /* Max Iterations = 1.0  */
 
}

#endif
