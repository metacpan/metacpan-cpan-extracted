/* $Id: LibRSVG.xs,v 1.3 2001/10/30 23:05:30 matt Exp $ */

#ifdef __cplusplus
extern "C" {
#endif
#include <png.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdlib.h>
#include <errno.h>
#include <popt.h>
#include <gdk-pixbuf/gdk-pixbuf.h>
#include <librsvg/rsvg.h>
#ifdef __cplusplus
}
#endif


/* The following routine is lifted wholesale from nautilus-icon-factory.c.
   It should find a permanent home somewhere else, at which point it should
   be deleted here and simply linked. -RLL
*/

/* utility routine for saving a pixbuf to a png file.
 * This was adapted from Iain Holmes' code in gnome-iconedit, and probably
 * should be in a utility library, possibly in gdk-pixbuf itself.
 * 
 * It is split up into save_pixbuf_to_file and save_pixbuf_to_file_internal
 * to work around a gcc warning about handle possibly getting clobbered by
 * longjmp. Declaring handle 'volatile FILE *' didn't work as it should have.
 */
static gboolean
save_pixbuf_to_file_internal (GdkPixbuf *pixbuf, char *filename, FILE *handle)
{
  	char *buffer;
	gboolean has_alpha;
	int width, height, depth, rowstride;
  	guchar *pixels;
  	png_structp png_ptr;
  	png_infop info_ptr;
  	png_text text[2];
  	int i;
	
	png_ptr = png_create_write_struct (PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
	if (png_ptr == NULL) {
		return FALSE;
	}

	info_ptr = png_create_info_struct (png_ptr);
	if (info_ptr == NULL) {
		png_destroy_write_struct (&png_ptr, (png_infopp)NULL);
	    	return FALSE;
	}

	if (setjmp (png_ptr->jmpbuf)) {
		png_destroy_write_struct (&png_ptr, &info_ptr);
		return FALSE;
	}

	png_init_io (png_ptr, (FILE *)handle);

        has_alpha = gdk_pixbuf_get_has_alpha (pixbuf);
	width = gdk_pixbuf_get_width (pixbuf);
	height = gdk_pixbuf_get_height (pixbuf);
	depth = gdk_pixbuf_get_bits_per_sample (pixbuf);
	pixels = gdk_pixbuf_get_pixels (pixbuf);
	rowstride = gdk_pixbuf_get_rowstride (pixbuf);

	png_set_IHDR (png_ptr, info_ptr, width, height,
			depth, PNG_COLOR_TYPE_RGB_ALPHA,
			PNG_INTERLACE_NONE,
			PNG_COMPRESSION_TYPE_DEFAULT,
			PNG_FILTER_TYPE_DEFAULT);

	/* Some text to go with the png image */
	text[0].key = "Title";
	text[0].text = filename;
	text[0].compression = PNG_TEXT_COMPRESSION_NONE;
	text[1].key = "Software";
	text[1].text = "Test-Rsvg";
	text[1].compression = PNG_TEXT_COMPRESSION_NONE;
	png_set_text (png_ptr, info_ptr, text, 2);

	/* Write header data */
	png_write_info (png_ptr, info_ptr);

	/* if there is no alpha in the data, allocate buffer to expand into */
	if (has_alpha) {
		buffer = NULL;
	} else {
		buffer = g_malloc(4 * width);
	}
	
	/* pump the raster data into libpng, one scan line at a time */	
	for (i = 0; i < height; i++) {
		if (has_alpha) {
			png_bytep row_pointer = pixels;
			png_write_row (png_ptr, row_pointer);
		} else {
			/* expand RGB to RGBA using an opaque alpha value */
			int x;
			char *buffer_ptr = buffer;
			char *source_ptr = pixels;
			for (x = 0; x < width; x++) {
				*buffer_ptr++ = *source_ptr++;
				*buffer_ptr++ = *source_ptr++;
				*buffer_ptr++ = *source_ptr++;
				*buffer_ptr++ = 255;
			}
			png_write_row (png_ptr, (png_bytep) buffer);		
		}
		pixels += rowstride;
	}
	
	png_write_end (png_ptr, info_ptr);
	png_destroy_write_struct (&png_ptr, &info_ptr);
	
	g_free (buffer);

	return TRUE;
}

void write_png_to_sv(png_structp png_ptr, png_bytep data, png_uint_32 length)
{
    SV * sv = (SV*)png_get_io_ptr(png_ptr);
    sv_catpvn(sv, data, length);
}

void flush_png_to_sv(png_structp png_ptr)
{
    /* do nothing */
}

static gboolean
save_pixbuf_to_sv_internal (GdkPixbuf *pixbuf, SV * sv)
{
  	char *buffer;
	gboolean has_alpha;
	int width, height, depth, rowstride;
  	guchar *pixels;
  	png_structp png_ptr;
  	png_infop info_ptr;
  	png_text text[2];
  	int i;
	
	png_ptr = png_create_write_struct (PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
	if (png_ptr == NULL) {
		return FALSE;
	}

	info_ptr = png_create_info_struct (png_ptr);
	if (info_ptr == NULL) {
		png_destroy_write_struct (&png_ptr, (png_infopp)NULL);
	    	return FALSE;
	}

	if (setjmp (png_ptr->jmpbuf)) {
		png_destroy_write_struct (&png_ptr, &info_ptr);
		return FALSE;
	}

        png_set_write_fn(png_ptr, (voidp)sv, (png_rw_ptr)write_png_to_sv, (png_flush_ptr)flush_png_to_sv);

        has_alpha = gdk_pixbuf_get_has_alpha (pixbuf);
	width = gdk_pixbuf_get_width (pixbuf);
	height = gdk_pixbuf_get_height (pixbuf);
	depth = gdk_pixbuf_get_bits_per_sample (pixbuf);
	pixels = gdk_pixbuf_get_pixels (pixbuf);
	rowstride = gdk_pixbuf_get_rowstride (pixbuf);

	png_set_IHDR (png_ptr, info_ptr, width, height,
			depth, PNG_COLOR_TYPE_RGB_ALPHA,
			PNG_INTERLACE_NONE,
			PNG_COMPRESSION_TYPE_DEFAULT,
			PNG_FILTER_TYPE_DEFAULT);

	/* Some text to go with the png image */
	text[0].key = "Title";
	text[0].text = "Internal Scalar";
	text[0].compression = PNG_TEXT_COMPRESSION_NONE;
	text[1].key = "Software";
	text[1].text = "Test-Rsvg";
	text[1].compression = PNG_TEXT_COMPRESSION_NONE;
	png_set_text (png_ptr, info_ptr, text, 2);

	/* Write header data */
	png_write_info (png_ptr, info_ptr);

	/* if there is no alpha in the data, allocate buffer to expand into */
	if (has_alpha) {
		buffer = NULL;
	} else {
		buffer = g_malloc(4 * width);
	}
	
	/* pump the raster data into libpng, one scan line at a time */	
	for (i = 0; i < height; i++) {
		if (has_alpha) {
			png_bytep row_pointer = pixels;
			png_write_row (png_ptr, row_pointer);
		} else {
			/* expand RGB to RGBA using an opaque alpha value */
			int x;
			char *buffer_ptr = buffer;
			char *source_ptr = pixels;
			for (x = 0; x < width; x++) {
				*buffer_ptr++ = *source_ptr++;
				*buffer_ptr++ = *source_ptr++;
				*buffer_ptr++ = *source_ptr++;
				*buffer_ptr++ = 255;
			}
			png_write_row (png_ptr, (png_bytep) buffer);		
		}
		pixels += rowstride;
	}
	
	png_write_end (png_ptr, info_ptr);
	png_destroy_write_struct (&png_ptr, &info_ptr);
	
	g_free (buffer);

	return TRUE;
}

static gboolean
save_pixbuf_to_file (GdkPixbuf *pixbuf, char *filename)
{
	FILE *handle;
	gboolean result;

	g_return_val_if_fail (pixbuf != NULL, FALSE);
	g_return_val_if_fail (filename != NULL, FALSE);
	g_return_val_if_fail (filename[0] != '\0', FALSE);

	if (!strcmp (filename, "-")) {
		handle = stdout;
	} else {
		handle = fopen (filename, "wb");
	}

        if (handle == NULL) {
        	return FALSE;
	}

	result = save_pixbuf_to_file_internal (pixbuf, filename, handle);
	if (!result || handle != stdout)
		fclose (handle);

	return result;
}

MODULE = XML::LibRSVG         PACKAGE = XML::LibRSVG

PROTOTYPES: DISABLE

void
write_png_from_file_at_zoom (self, inputf, outputf, zoom)
        SV * self
        char * inputf
        char * outputf
        double zoom
    CODE:
    {
       FILE * f;
       GdkPixbuf * pixbuf;

       f = fopen(inputf, "r");
       if (f == NULL) {
           croak("file open failed: %s", strerror(errno));
       }

       pixbuf = rsvg_render_file(f, zoom);

       fclose(f);
       
       if (pixbuf) {
           save_pixbuf_to_file(pixbuf, outputf);
       }
       else {
           croak("svg parse failed");
       }
    }

SV *
png_from_file_at_zoom (self, inputf, zoom)
        SV * self
        char * inputf
        double zoom
    CODE:
    {
        FILE * f;
        GdkPixbuf * pixbuf;
        SV * newsv = NEWSV(0, 20000); /* alloc 20k-ish */
        sv_setpvn(newsv, "", 0);
        
        f = fopen(inputf, "r");
        if (f == NULL) {
            croak("file open failed: %s", strerror(errno));
        }
 
        pixbuf = rsvg_render_file(f, zoom);
 
        fclose(f);
        
        if (pixbuf) {
            save_pixbuf_to_sv_internal(pixbuf, newsv);
            RETVAL = newsv;
        }
        else {
            croak("svg parse failed");
        }
    }
    OUTPUT:
        RETVAL


