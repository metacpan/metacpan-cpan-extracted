#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xatom.h>
#include <png.h>
#include <stdlib.h>
#include <string.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

typedef struct
{
	Display *display;
	int screen_number;
	Window window;
	unsigned int display_width;
	unsigned int display_height;
	GC *gc;
	Cursor *cursor;
} viewer;

extern viewer *new      ();
extern viewer *show     (viewer *self, char *png_contents, int png_size);

struct fake_file {
	unsigned char *data;
	int size;
	int previous;
};

viewer *new() {
	char *display_name = NULL;
	unsigned long valuemask = 0;
	XGCValues values;
	Pixmap bitmap_no_data;
	Window root_window;
	XColor black;
	static char no_data[] = { 0,0,0,0,0,0,0,0 };
	XEvent ev;

	black.red = black.green = black.blue = 0;

	viewer *self = (viewer *) malloc(sizeof (viewer));
	self->display = XOpenDisplay(display_name);

	if (self->display == NULL) {
		croak("Cannot connect to X server:%s", XDisplayName(display_name));
	}
	root_window = DefaultRootWindow(self->display);

	bitmap_no_data = XCreateBitmapFromData(self->display, root_window, no_data, 8, 8);
	self->cursor = (Cursor *)malloc(sizeof (Cursor));
	*self->cursor = XCreatePixmapCursor(self->display, bitmap_no_data, bitmap_no_data, &black, &black, 0, 0);
	XDefineCursor(self->display, root_window, *self->cursor);

	self->screen_number = DefaultScreen(self->display);
	self->display_width = DisplayWidth(self->display, self->screen_number);
	self->display_height = DisplayHeight(self->display, self->screen_number);
	XSetWindowAttributes attributes;
	attributes.background_pixel = XBlackPixel(self->display, self->screen_number);
	attributes.colormap = DefaultColormap(self->display, self->screen_number);
	self->window = XCreateWindow(self->display, RootWindow(self->display, self->screen_number), 0, 0, self->display_width, self->display_height, 0, DefaultDepth(self->display, self->screen_number), InputOutput, DefaultVisual(self->display, self->screen_number), CWBackPixel | CWColormap, &attributes);
        Atom wm_state = XInternAtom (self->display, "_NET_WM_STATE", True );
        Atom wm_fullscreen = XInternAtom (self->display, "_NET_WM_STATE_FULLSCREEN", True );
	if (wm_fullscreen != None) {
		XChangeProperty(self->display, self->window, wm_state, XA_ATOM, 32, PropModeReplace, (unsigned char *)&wm_fullscreen, 1);
	}
	XSelectInput(self->display, self->window, ExposureMask);
	XMapWindow(self->display, self->window);

	self->gc = (GC *)malloc(sizeof (GC));
	*self->gc = XCreateGC(self->display, self->window, valuemask, &values);
	if (self->gc == NULL) {
		free(self->gc);
		croak("Failed to XCreateGC");
	}
	XSetBackground(self->display, *self->gc, XBlackPixel(self->display, self->screen_number));
	XSetForeground(self->display, *self->gc, XBlackPixel(self->display, self->screen_number));
	XFlush(self->display);
	XMaskEvent(self->display, ExposureMask, &ev);
	return self;
}

void cheat_and_read_png_from_memory (png_structp png, png_bytep data, png_size_t length) {
	struct fake_file *fake_png_file = png_get_io_ptr(png);
	if (fake_png_file == NULL) {
		croak("Failed to png_get_io_ptr");
	}
	bcopy(fake_png_file->data + fake_png_file->previous, data, length);
	fake_png_file->previous += length;
}

viewer *show(viewer *self, char *png_contents, int png_size) {
	struct fake_file fake_png_file;
	png_structp png = NULL;
	png_infop info = NULL;
	png_uint_32 image_width, image_height, row_bytes;
	int bit_depth = 0, color_type = 0, interlace = 0, compression = 0, filter = 0;
	int size;
	png_uint_32 clip_row_bytes;
	unsigned char *data;
	unsigned char **row_pointers = NULL;
	int start_x, start_y;
	XImage *ximage;
	Pixmap *pixmap;
	int i;

	fake_png_file.previous = 0;
	fake_png_file.size = png_size;
	fake_png_file.data = (unsigned char *) malloc (sizeof (unsigned char) * png_size);
	bcopy(png_contents, fake_png_file.data, png_size);
	png = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
	if (!png) {
		free(fake_png_file.data);
		croak("Failed to png_create_read_struct");
	}
	info = png_create_info_struct (png);
	if (!info) {
		png_destroy_write_struct(&png, (png_infopp) NULL);
		free(fake_png_file.data);
		croak("Failed to png_create_info_struct");
	}
	png_set_read_fn(png, (png_voidp)&fake_png_file, cheat_and_read_png_from_memory);
	png_read_info(png, info);
	png_get_IHDR(png, info, &image_width, &image_height, &bit_depth, &color_type, &interlace, &compression, &filter);
	if (bit_depth == 16) {
		png_set_strip_16(png);
	}
	png_set_interlace_handling(png);
	switch(color_type) {
		case PNG_COLOR_TYPE_GRAY_ALPHA:
			png_set_gray_to_rgb(png);
			png_read_update_info(png, info);
			break;
		case PNG_COLOR_TYPE_GRAY:
			if (bit_depth == 16) {
				png_set_filler(png, 0xff, PNG_FILLER_AFTER);
				png_set_bgr(png);
			} else if (bit_depth < 8) {
				png_set_expand_gray_1_2_4_to_8(png);
				bit_depth = 8;
			}
			png_set_gray_to_rgb(png);
			png_set_filler(png, 0xff, PNG_FILLER_AFTER);
			png_read_update_info(png, info);
			break;
		case PNG_COLOR_TYPE_RGB:
			if (bit_depth == 16) {
				png_set_filler(png, 0xff, PNG_FILLER_AFTER);
				png_set_bgr(png);
			} else {
				png_set_expand(png);
				png_set_filler(png, 0xff, PNG_FILLER_AFTER);
				png_set_bgr(png);
				png_read_update_info(png, info);
			}
			break;
		case PNG_COLOR_TYPE_RGBA:
			png_set_bgr(png);
			break;
		case PNG_COLOR_TYPE_PALETTE:
			png_set_palette_to_rgb(png);
			png_set_filler(png, 0xff, PNG_FILLER_AFTER);
			png_set_bgr(png);
			png_read_update_info(png, info);
			break;
	}
	row_bytes = png_get_rowbytes (png, info);
	size = image_height * row_bytes;
	clip_row_bytes = row_bytes / 32;
	if (row_bytes % 32) {
		++clip_row_bytes;
	}
	data = (unsigned char*) malloc (sizeof (png_byte) * size);
	row_pointers = (unsigned char**) malloc (image_height * sizeof (unsigned char*));
	png_bytep cursor = data;
        for (i=0; i < image_height; ++i, cursor += row_bytes) {
		row_pointers[i] = cursor;
	}
	png_read_image(png, row_pointers);
	png_read_end(png, NULL);
	png_destroy_read_struct(&png, &info, (png_infopp)0);
	free(row_pointers);
	free(fake_png_file.data);

	start_x = (self->display_width / 2) - (image_width / 2);
	start_y = (self->display_height / 2) - (image_height / 2);

	pixmap = (Pixmap *)malloc(sizeof(Pixmap));
	*pixmap = XCreatePixmap (self->display, self->window, self->display_width, self->display_height, DefaultDepth(self->display, self->screen_number));
	XFillRectangle(self->display, *pixmap, *self->gc, 0, 0, self->display_width, self->display_height);
	ximage = XCreateImage(self->display, DefaultVisual (self->display, DefaultScreen (self->display)), DefaultDepth(self->display, self->screen_number), ZPixmap, 0, (char*)data, image_width, image_height, 32, row_bytes);
	if (ximage) {
		if (XPutImage(self->display, *pixmap, *self->gc, ximage, 0, 0, start_x, start_y, self->display_width, self->display_height)) {
			XFreePixmap(self->display, *pixmap);
			free(pixmap);
			XDestroyImage(ximage);
			croak("Failed to XPutImage");
		}
		XDestroyImage(ximage);
		XCopyArea(self->display, *pixmap, self->window, *self->gc, 0, 0, self->display_width, self->display_height, 0, 0);
	} else {
		XFreePixmap(self->display, *pixmap);
		free(pixmap);
		croak("Failed to XCreateImage");
	}
	XFreePixmap(self->display, *pixmap);
	free(pixmap);
	XFlush(self->display);
	return self;
}

void DESTROY(viewer *self) {
	XFlush(self->display);
	XFreeCursor(self->display, *self->cursor);
	free(self->cursor);
	XFreeGC(self->display, *self->gc);
	XCloseDisplay(self->display);
	free(self->gc);
	free(self);
}

typedef viewer *X11__PngViewer;

MODULE = X11::PngViewer		PACKAGE = X11::PngViewer		

PROTOTYPES: ENABLE

X11::PngViewer
new(SV *class_name)
	CODE:
	RETVAL = new();
	OUTPUT:
	RETVAL

X11::PngViewer
show(self, png_contents)
	X11::PngViewer self
	SV *png_contents
	CODE:
	RETVAL = show(self, SvPV_nolen(png_contents), (int)SvLEN(png_contents));
	OUTPUT:
	RETVAL

