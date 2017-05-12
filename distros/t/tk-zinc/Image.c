/*
 * Image.c -- Image support routines.
 *
 * Authors              : Patrick LECOANET
 * Creation date        : Wed Dec  8 11:04:44 1999
 */

/*
 *  Copyright (c) 1999 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */


#include "Types.h"
#include "tkZinc.h"
#include "Image.h"
#include "WidgetInfo.h"
#include "Geo.h"
#include "Draw.h"
#include "perfos.h"

#include <memory.h>
#include <ctype.h>
#ifdef GL
#include <stdlib.h>
#endif


static const char rcsid[] = "$Id: Image.c,v 1.51 2005/10/18 09:31:01 lecoanet Exp $";
static const char compile_id[] = "$Compile: " __FILE__ " " __DATE__ " " __TIME__ " $";


static int              images_inited = 0;
static Tcl_HashTable    images;
#ifdef GL
static Tcl_HashTable    font_textures;
#endif

typedef struct _ClientStruct {
  void  (*inv_proc)(void *cd);
  void  *client_data;
  int   refcount;
} ClientStruct;

typedef struct _ImageStruct {
  union {
    Pixmap      pixmap;
#ifdef GL
    GLuint      texobj;
#endif
  } i;
  Display       *dpy;
  Screen        *screen;
  struct _ImageBits *bits;

  /* Bookkeeping */

  ZnBool        for_gl;
  int           refcount;
  ZnList        clients;
  struct _ImageStruct   *next;
} ImageStruct, *Image;


typedef struct _ImageBits {
  unsigned char *bpixels;  /* Needed for bitmaps. Set to NULL if the image
                            * is not a bitmap. */
  int           rowstride;
#ifdef GL
  ZnReal        t;         /* Texture parameters for the image. */
  ZnReal        s;
  int           t_width;   /* Texture size used for this image. */
  int           t_height;
  unsigned char *t_bits;   /* Can be NULL if texture is not used (no GL
                            * rendering active on this image). */
#endif

  /* Bookeeping */
  Display       *dpy;     /* The tkimage below comes from this display. */
  Tcl_Interp    *interp;  /* The interp that created the tkimage below. */
  Tk_Image      tkimage;  /* Keep this handle to be informed of changes */ 
  Tk_PhotoHandle tkphoto;
  TkRegion      valid_region;
  int           width;
  int           height;
  int           depth;
  Tcl_HashEntry *hash;    /* From this it is easy to get the image/bitmap
                           * name. */
  Image         images;   /* Linked list of widget/display dependant
                           * specializations of this image. If NULL, the
                           * image has no specialization and can be freed. */
} ImageBits;


char *ZnNameOfImage(ZnImage image);

#ifdef GL

static int
To2Power(int a)
{
  int result = 1;

  while (result < a) {
    result *= 2;
  }
  return result;
}
#endif
     

/*
 **********************************************************************************
 *
 * ZnGetImage --
 *
 **********************************************************************************
 */
static void
InvalidateImage(ClientData      client_data,
                int             x,
                int             y,
                int             width,
                int             height,
                int             image_width,
                int             image_height)
{
  ImageBits    *bits = (ImageBits *) client_data;
  Image        this;
  int          num_cs, count, i;
  ClientStruct *cs;
  char          *image_name;

  /*  printf("Invalidation, bits: %d, %d %d %d %d %d %d\n",
      client_data, x, y, width, height, image_width, image_height);*/
  if (ZnImageIsBitmap(bits->images)) {
    /* This is a bitmap nothing to update
     * (This should not happen) */
    return;
  }

#ifdef GL
  if (bits->t_bits) {
    ZnFree(bits->t_bits);
    bits->t_bits = NULL;
  }
#endif
  if (bits->valid_region) {
    TkDestroyRegion(bits->valid_region);
    bits->valid_region = NULL;
  }

  bits->width = image_width;
  bits->height = image_height;
  image_name = ZnNameOfImage(bits->images);

  /*
   * The photo pointer must be updated. It changes when creating an new image with
   * the same name as an old. The image is first deleted then re-instantiated.
   * As a side effect we also rely on it for telling if an image is a photo.
   */
  bits->tkphoto = Tk_FindPhoto(bits->interp, image_name);

  count = 0;
  this = bits->images;
  while (this) {
#ifdef GL
    if (this->for_gl) {
      if (this->i.texobj) {
        ZnGLContextEntry *ce;
        ce = ZnGLMakeCurrent(this->dpy, 0);
        glDeleteTextures(1, &this->i.texobj);
        ZnGLReleaseContext(ce);
        this->i.texobj = 0;
      }
    }
    else {
#endif
      if (this->i.pixmap != None) {
        Tk_FreePixmap(this->dpy, this->i.pixmap);
        this->i.pixmap = None;    
      }
#ifdef GL
    }
#endif
          
    num_cs = ZnListSize(this->clients);
    cs = ZnListArray(this->clients);
    for (i = 0; i < num_cs; i++, cs++) {
      if (cs->inv_proc) {
        (*cs->inv_proc)(cs->client_data);
      }
    }
    count += num_cs;
    this = this->next;
  }
  /*printf("Invalidate on image %s with %d clients\n",
    Tcl_GetHashKey(&images, bits->hash), count);*/
}

ZnImage
ZnGetImage(ZnWInfo      *wi,
           Tk_Uid       image_name,
           void         (*inv_proc)(void *cd),
           void         *client_data)
{
  Tcl_HashEntry *entry;
  int           new, num_cs, i;
  ImageBits     *bits;
  ZnBool        for_gl = wi->render>0;
  Image         image;
  Tk_ImageType  *type;
  ClientStruct  cs, *cs_ptr;

  /*printf("ZnGetImage: %s\n", image_name);*/
  if (!images_inited) {
    Tcl_InitHashTable(&images, TCL_STRING_KEYS);
    images_inited = 1;
  }
  image_name = Tk_GetUid(image_name);
  entry = Tcl_FindHashEntry(&images, image_name);
  if (entry != NULL) {
    /*printf("Image \"%s\" is in cache\n", image_name);*/
    bits = (ImageBits *) Tcl_GetHashValue(entry);
  }
  else {
    /*printf("New image \"%s\"\n", image_name);*/
    if (strcmp(image_name, "") == 0) {
      return ZnUnspecifiedImage;
    }

    bits = ZnMalloc(sizeof(ImageBits));
#ifdef GL
    bits->t_bits = NULL;
#endif
    bits->images = NULL;
    bits->bpixels = NULL;
    bits->valid_region = NULL;
    bits->tkimage = NULL;
    bits->tkphoto = NULL;
    bits->interp = wi->interp;
    bits->dpy = wi->dpy;

    if (!Tk_GetImageMasterData(wi->interp, image_name, &type)) {
      /*
       * This doesn't seem to be a Tk image, try to load
       * a Tk bitmap.
       */
      Pixmap    pmap;
      XImage    *mask;
      int       x, y;
      unsigned char *line;
      
      pmap = Tk_GetBitmap(wi->interp, wi->win, image_name);
      if (pmap == None) {
        ZnWarning("unknown bitmap/image \"");
        goto im_error;
      }
      
      Tk_SizeOfBitmap(wi->dpy, pmap, &bits->width, &bits->height);    
      mask = XGetImage(wi->dpy, pmap, 0, 0, (unsigned int) bits->width,
                       (unsigned int) bits->height, 1L, XYPixmap);
      bits->depth = 1;
      bits->rowstride = mask->bytes_per_line;
      bits->bpixels = ZnMalloc((unsigned int) (bits->height * bits->rowstride));
      memset(bits->bpixels, 0, (unsigned int) (bits->height * bits->rowstride));
      line = bits->bpixels;
      for (y = 0; y < bits->height; y++) {
        for (x = 0; x < bits->width; x++) {
          if (XGetPixel(mask, x, y)) {
            line[x >> 3] |= 0x80 >> (x & 7);
          }
        }
        line += bits->rowstride;
      }
      XDestroyImage(mask);
      Tk_FreeBitmap(wi->dpy, pmap);
    }
    
    else if (strcmp(type->name, "photo") == 0) {
      /* Processing will yield an image photo */
      bits->tkphoto = Tk_FindPhoto(wi->interp, image_name);
      Tk_PhotoGetSize(bits->tkphoto, &bits->width, &bits->height);
      if ((bits->width == 0) || (bits->height == 0)) {
        ZnWarning("bogus photo image \"");
        goto im_error;
      }
      bits->depth = Tk_Depth(wi->win);
      bits->tkimage = Tk_GetImage(wi->interp, wi->win, image_name,
                                  InvalidateImage, (ClientData) bits);
    }
    else { /* Other image types */
      bits->depth = Tk_Depth(wi->win);
      bits->tkimage = Tk_GetImage(wi->interp, wi->win, image_name,
                                  InvalidateImage, (ClientData) bits);
      Tk_SizeOfImage(bits->tkimage, &bits->width, &bits->height);
      if ((bits->width == 0) || (bits->height == 0)) {
        ZnWarning("bogus ");
        ZnWarning(type->name);
        ZnWarning(" image \"");
      im_error:
        ZnWarning(image_name);
        ZnWarning("\"\n");
        ZnFree(bits);
        return ZnUnspecifiedImage;      
      }
    }

    entry = Tcl_CreateHashEntry(&images, image_name, &new);
    bits->hash = entry;
    Tcl_SetHashValue(entry, (ClientData) bits);
  }

  /*
   * Try to find an image instance that fits this widget/display.
   */
  for (image = bits->images; image != NULL; image = image->next) {
    if (image->for_gl == for_gl) {
      if ((for_gl && (image->dpy == wi->dpy)) ||
          (!for_gl && (image->screen == wi->screen))) {
        if (!ZnImageIsBitmap(image)) {
          cs_ptr = ZnListArray(image->clients);
          num_cs = ZnListSize(image->clients);
          for (i = 0; i < num_cs; i++, cs_ptr++) {
            if ((cs_ptr->inv_proc == inv_proc) &&
                (cs_ptr->client_data == client_data)) {
              cs_ptr->refcount++;
              return image;
            }
          }
          /* Add a new client reference to call back.
           */
          cs.inv_proc = inv_proc;
          cs.client_data = client_data;
          cs.refcount = 1;
          ZnListAdd(image->clients, &cs, ZnListTail);
          return image;
        }
        image->refcount++;
        return image;
      }
    }
  }

  /*
   * Create a new instance for this case.
   */
  /*printf("new instance for \"%s\"\n", image_name);*/
  image = ZnMalloc(sizeof(ImageStruct));
  image->bits = bits;
  image->refcount = 0;
  image->for_gl = for_gl;
  image->dpy = wi->dpy;
  image->screen = wi->screen;

  if (!ZnImageIsBitmap(image)) {
    image->clients = ZnListNew(1, sizeof(ClientStruct));
    cs.inv_proc = inv_proc;
    cs.client_data = client_data;
    cs.refcount = 1;
    ZnListAdd(image->clients, &cs, ZnListTail);
  }
  else {
    image->refcount++;
  }

  /* Init the real resource and let the client load it
   * on demand */
  if (image->for_gl) {
#ifdef GL
    image->i.texobj = 0;
#endif
  }
  else {
    image->i.pixmap = None;
    /*    image->i.pixmap = Tk_GetBitmap(wi->interp, wi->win, image_name);
          printf("pmap: %d\n", image->i.pixmap);*/
  }
  image->next = bits->images;
  bits->images = image;

  return image;
}


/*
 **********************************************************************************
 *
 * ZnGetImageByValue --
 *
 **********************************************************************************
 */
ZnImage
ZnGetImageByValue(ZnImage       image,
                  void          (*inv_proc)(void *cd),
                  void          *client_data)
{
  Image         this = (Image) image;
  ClientStruct  cs, *cs_ptr;
  int           i, num_cs;

  /*printf("ZnGetImageByValue: %s\n", ZnNameOfImage(image));*/
  if (!ZnImageIsBitmap(image)) {
    cs_ptr = ZnListArray(this->clients);
    num_cs = ZnListSize(this->clients);
    for (i = 0; i < num_cs; i++, cs_ptr++) {
      if ((cs_ptr->inv_proc == inv_proc) &&
          (cs_ptr->client_data == client_data)) {
        cs_ptr->refcount++;
        return image;
      }
    }
    cs.inv_proc = inv_proc;
    cs.client_data = client_data;
    cs.refcount = 1;
    ZnListAdd(this->clients, &cs, ZnListTail);
  }
  else {
    this->refcount++;
  }

  return image;
}

/*
 **********************************************************************************
 *
 * ZnImageIsBitmap --
 *
 **********************************************************************************
 */
ZnBool
ZnImageIsBitmap(ZnImage image)
{
  return (((Image) image)->bits->bpixels != NULL);
}

/*
 **********************************************************************************
 *
 * ZnFreeImage --
 *
 **********************************************************************************
 */
void
ZnFreeImage(ZnImage     image,
            void        (*inv_proc)(void *cd),
            void        *client_data)
{
  Image         prev, scan, this = ((Image) image);
  ImageBits     *bits = this->bits;
  ClientStruct  *cs_ptr;
  int           i, num_cs, rm_image;

  /*printf("ZnFreeImage: %s\n", ZnNameOfImage(image));*/
  /*
   * Search the instance in the list.
   */
  for (prev=NULL, scan=bits->images; (scan!=NULL)&&(scan!=this);
       prev=scan, scan=scan->next);
  if (scan != this) {
    return; /* Not found ? */
  }

  if (!ZnImageIsBitmap(image)) {
    cs_ptr = ZnListArray(this->clients);
    num_cs = ZnListSize(this->clients);
    for (i = 0; i < num_cs; i++, cs_ptr++) {
      if ((cs_ptr->inv_proc == inv_proc) &&
          (cs_ptr->client_data == client_data)) {
        cs_ptr->refcount--;
        if (cs_ptr->refcount == 0) {
          ZnListDelete(this->clients, i);
        }
        break;
      }
    }
    rm_image = ZnListSize(this->clients)==0;
  }
  else {
    this->refcount--;
    rm_image = this->refcount==0;
  }

  if (!rm_image) {
    return;
  }

  /*
   * Unlink the deleted image instance.
   */
  if (prev == NULL) {
    bits->images = this->next;
  }
  else {
    prev->next = this->next;
  }
  if (this->for_gl) {
#ifdef GL
    if (this->i.texobj) {
      ZnGLContextEntry *ce;
      ce = ZnGLMakeCurrent(this->dpy, 0);
      /*      printf("%d Liberation de la texture %d pour l'image %s\n",
              wi, this->i.texobj, ZnNameOfImage(image));*/
      glDeleteTextures(1, &this->i.texobj);
      this->i.texobj = 0;
      ZnGLReleaseContext(ce);
    }
#endif
  }
  else if (bits->tkimage) {
    /*
     * This is an image, we need to free the instances.
     */
    if (this->i.pixmap != None) {
      Tk_FreePixmap(this->dpy, this->i.pixmap);
    }
  }
  else {
    /*
     * This is a bitmap ask Tk to free the resource.
     */
    if (this->i.pixmap != None) {
      Tk_FreeBitmap(this->dpy, this->i.pixmap);
    }
  }
  ZnFree(this);

  /*
   * No clients for this image, it can be freed.
   */
  if (bits->images == NULL) {
    /*printf("destruction complète de l'image %s\n", ZnNameOfImage(this));*/
#ifdef GL
    if (bits->t_bits) {
      ZnFree(bits->t_bits);
    }
#endif
    if (bits->bpixels) {
      ZnFree(bits->bpixels);
    }
    if (bits->tkimage) {
      Tk_FreeImage(bits->tkimage);
    }
    if (bits->valid_region) {
      TkDestroyRegion(bits->valid_region);
    }
    Tcl_DeleteHashEntry(bits->hash);
    ZnFree(bits);
  }
}


/*
 **********************************************************************************
 *
 * ZnNameOfImage --
 *
 **********************************************************************************
 */
char *
ZnNameOfImage(ZnImage   image)
{
  return Tcl_GetHashKey(&images, ((Image) image)->bits->hash);
}


/*
 **********************************************************************************
 *
 * ZnSizeOfImage --
 *
 **********************************************************************************
 */
void
ZnSizeOfImage(ZnImage   image,
              int       *width,
              int       *height)
{
  Image         this = (Image) image;

  *width = this->bits->width;
  *height = this->bits->height;
}


/*
 **********************************************************************************
 *
 * ZnImagePixmap --
 *
 **********************************************************************************
 */
Pixmap
ZnImagePixmap(ZnImage   image,
              Tk_Window win)
{
  Image         this = (Image) image;
  ImageBits     *bits = this->bits;

  /*printf("ZnImagePixmap: %s\n", ZnNameOfImage(image));*/
  if (this->for_gl) {
    fprintf(stderr,
            "Bogus use of an image, it was created for GL and used in an X11 context\n");
    return None;
  }
  
  if (this->i.pixmap == None) {
    if (ZnImageIsBitmap(image)) {
      this->i.pixmap = Tk_GetBitmap(bits->interp, win, Tk_GetUid(ZnNameOfImage(image)));
    }
    else {
      Tk_Image tkimage;
      
      /*
       * If the original image was created on the same display
       * as the required display, we can get the pixmap from it.
       * On the other hand we need first to obtain an image
       * instance on the right display.
       */
      if (bits->dpy == this->dpy) {
        tkimage = bits->tkimage;
      }
      else {
        /* Create a temporary tkimage to draw the pixmap. */
        tkimage = Tk_GetImage(bits->interp, win, ZnNameOfImage(image), NULL, NULL);
      }
      
      this->i.pixmap = Tk_GetPixmap(this->dpy, Tk_WindowId(win),
                                    bits->width, bits->height, bits->depth);
      Tk_RedrawImage(tkimage, 0, 0, bits->width, bits->height, this->i.pixmap, 0, 0);
      
      if (tkimage != bits->tkimage) {
        Tk_FreeImage(tkimage);
      }
    }
  }

  return this->i.pixmap;
}


/*
 **********************************************************************************
 *
 * ZnPointInImage --
 *
 *      Return whether the given point is inside the image.
 *
 **********************************************************************************
 */
ZnBool
ZnPointInImage(ZnImage  image,
               int      x,
               int      y)
{
  if (ZnImageIsBitmap(image)) {
    ImageBits *bits = ((Image) image)->bits;
    if ((x < 0) || (y < 0) ||
        (x >= bits->width) || (y >= bits->height)) {
      return False;
    }
    return ZnGetBitmapPixel(bits->bpixels, bits->rowstride, x, y);
  }
  else {
    return ZnPointInRegion(ZnImageRegion(image), x, y);
  }
}


/*
 **********************************************************************************
 *
 * ZnImageRegion --
 *
 *      Only defined for Tk images (including Tk images defined from bitmaps).
 *
 **********************************************************************************
 */
static void
BuildImageRegion(Display        *dpy,
                 ImageBits      *bits)
{
  Pixmap        pmap;
  int           x, y, end;
  GC            gc;
  XImage        *im1, *im2;
  XRectangle    rect;

  /*printf("BuildImageRegion: %s\n", ZnNameOfImage(bits->images));*/
  pmap = Tk_GetPixmap(dpy, DefaultRootWindow(dpy), bits->width, bits->height, bits->depth);
  gc = XCreateGC(dpy, pmap, 0, NULL);
  XSetForeground(dpy, gc, 0);
  XFillRectangle(dpy, pmap, gc, 0, 0, bits->width, bits->height);
  Tk_RedrawImage(bits->tkimage, 0, 0, bits->width, bits->height, pmap, 0, 0);
  im1 = XGetImage(dpy, pmap, 0, 0, bits->width, bits->height, ~0L, ZPixmap);
  
  XSetForeground(dpy, gc, 1);
  XFillRectangle(dpy, pmap, gc, 0, 0, bits->width, bits->height);
  Tk_RedrawImage(bits->tkimage, 0, 0, bits->width, bits->height, pmap, 0, 0);
  im2 = XGetImage(dpy, pmap, 0, 0, bits->width, bits->height, ~0L, ZPixmap);
  Tk_FreePixmap(dpy, pmap);
  XFreeGC(dpy, gc);

  bits->valid_region = TkCreateRegion();

  for (y = 0; y < bits->height; y++) {
    x = 0;
    while (x < bits->width) {
      while ((x < bits->width) &&
             (XGetPixel(im1, x, y) != XGetPixel(im2, x, y))) {
        /* Search the first non-transparent pixel */
        x++;
      }
      end = x;
      while ((end < bits->width) &&
             (XGetPixel(im1, end, y) == XGetPixel(im2, end, y))) {
        /* Search the first transparent pixel */
        end++;
      }
      if (end > x) {
        rect.x = x;
        rect.y = y;
        rect.width = end - x;
        rect.height = 1;
        TkUnionRectWithRegion(&rect, bits->valid_region, bits->valid_region);
      }
      x = end;
    }
  }
  
  XDestroyImage(im1);
  XDestroyImage(im2);
}

TkRegion
ZnImageRegion(ZnImage   image)
{
  if (ZnImageIsBitmap(image)) {
    return NULL;
  }
  else {
    Image       this = (Image) image;
    ImageBits   *bits = this->bits;
#ifdef PTK
    if (!bits->valid_region) {
      BuildImageRegion(this->dpy, bits);
    }
    return bits->valid_region;
#else
    if (bits->tkphoto) {
      return TkPhotoGetValidRegion(bits->tkphoto);
    }
    else {
      if (!bits->valid_region) {
        BuildImageRegion(this->dpy, bits);
      }
      return bits->valid_region;
    }
#endif
  }
}


Tk_Image
ZnImageTkImage(ZnImage image)
{
  return ((Image) image)->bits->tkimage;
}

Tk_PhotoHandle
ZnImageTkPhoto(ZnImage image)
{
  return ((Image) image)->bits->tkphoto;
}

/*
 **********************************************************************************
 *
 * ZnImageTex --
 *
 **********************************************************************************
 */
#ifdef GL
/*
 * Working only for 16 bits displays with 5r6g5b mask,
 * and 24/32 bits displays. Byte ordering ok on Intel
 * plateform only.
 */
static void
From5r6g5b(unsigned char *data,
           int           width,
           int           height,
           int           bytes_per_line,
           unsigned char *t_bits,
           int           t_width,
           int           t_height,
           TkRegion      valid_region)
{
  int           x, y;
  int           rowstride = t_width * 4;
  unsigned char *obptr;
  unsigned char *bptr, *bp2;
  unsigned char alpha;
  unsigned short temp;

  bptr = t_bits;
  
  for (y = 0; y < height; y++) {
    bp2 = bptr;
    obptr = data;
    for (x = 0; x < width; x++) {
      /*
       * Configure the alpha value.
       */
      alpha = ZnPointInRegion(valid_region, x, y) ? 255 : 0;

      /*
       * Dispatch the 3 color components.
       */
      temp = ((unsigned short *)obptr)[0];
      *bp2 = (temp >> 8) & 0xf8; /* r */
      bp2++;
      *bp2 = (temp >> 3) & 0xfc; /* v */
      bp2++;
      *bp2 = (temp << 3);        /* b */
      bp2++;
      *bp2 = alpha;
      bp2++;
      obptr += 2;
    }
    for (x = width; x < t_width; x++) {
      *bp2 = 0;
      bp2++;
      *bp2 = 0;
      bp2++;
      *bp2 = 0;
      bp2++;
      *bp2 = 0;
      bp2++;
    }
    bptr += rowstride;
    data += bytes_per_line;
  }
  for (y = height; y < t_height; y++) {
    memset(bptr, 0, rowstride);
    bptr += rowstride;
  }
}

static void
From8r8g8b(unsigned char *data,
           int           width,
           int           height,
           int           bytes_per_line,
           unsigned char *t_bits,
           int           t_width,
           int           t_height,
           TkRegion      valid_region)
{
  int           x, y;
  int           rowstride = t_width * 4;
  unsigned char *obptr;
  unsigned char *bptr, *bp2;
  unsigned char alpha;

  bptr = t_bits;
  
  for (y = 0; y < height; y++) {
    bp2 = bptr;
    obptr = data;
    for (x = 0; x < width; x++) {
      /*
       * Configure the alpha value.
       */
      alpha = ZnPointInRegion(valid_region, x, y) ? 255 : 0;

      /*
       * Dispatch the 3 color components.
       * Be careful the Red and Blue are swapped it works on an Intel
       * plateform but may need some more tests to be fully generic.
       */
      *bp2++ = obptr[2]; /* r */
      *bp2++ = obptr[1]; /* v */
      *bp2++ = obptr[0]; /* b */
      obptr += 4;
      *bp2++ = alpha;
    }
    for (x = width; x < t_width; x++) {
      *bp2 = 0;
      bp2++;
      *bp2 = 0;
      bp2++;
      *bp2 = 0;
      bp2++;
      *bp2 = 0;
      bp2++;
    }
    bptr += rowstride;
    data += bytes_per_line;
  }
  for (y = height; y < t_height; y++) {
    memset(bptr, 0, rowstride);
    bptr += rowstride;
  }
}

static void
GatherImageTexels(Display       *dpy,
                  ImageBits     *bits)
{
  Pixmap        pmap;
  XImage        *im;
  TkRegion      valid_region;
  int           t_size;

  /*printf("GatherImageTexels: %s\n", ZnNameOfImage(bits->images));*/
  valid_region = ZnImageRegion(bits->images);

  t_size = bits->t_width * 4 * bits->t_height;
  bits->t_bits = ZnMalloc(t_size);  

  pmap = Tk_GetPixmap(dpy, DefaultRootWindow(dpy),
                      bits->width, bits->height, bits->depth);
  Tk_RedrawImage(bits->tkimage, 0, 0, bits->width, bits->height, pmap, 0, 0);
  im = XGetImage(dpy, pmap, 0, 0, bits->width, bits->height, ~0L, ZPixmap);
  Tk_FreePixmap(dpy, pmap);

  if (bits->depth == 16) {
    From5r6g5b(im->data, bits->width, bits->height, im->bytes_per_line,
               bits->t_bits, bits->t_width, bits->t_height, valid_region);
  }
  else if ((bits->depth == 24) || (bits->depth == 32)) {
    From8r8g8b(im->data, bits->width, bits->height, im->bytes_per_line,
               bits->t_bits, bits->t_width, bits->t_height, valid_region);
  }

  XDestroyImage(im);
}

GLuint
ZnImageTex(ZnImage      image,
           ZnReal       *t,
           ZnReal       *s)
{
  Image         this = (Image) image;
  ImageBits     *bits = this->bits;
  ZnBool        is_bmap = ZnImageIsBitmap(image);
  unsigned int  t_size, width, height;

  if (!this->for_gl) {
    fprintf(stderr, "Bogus use of an image, it was created for X11 and used in a GL context\n");
    return 0;
  }
  ZnSizeOfImage(image, &width, &height);
  if (!bits->t_bits) {
    /*printf("chargement texture pour image %s\n", ZnNameOfImage(this));*/
    bits->t_width = To2Power((int) width);
    bits->t_height = To2Power((int) height);
    bits->s = width / (ZnReal) bits->t_width;
    bits->t = height / (ZnReal) bits->t_height;

    /*
     * This is a bitmap: use the pixels stored in bpixels.
     */
    if (is_bmap) {
      unsigned int  i, j;
      unsigned char *ostart, *dstart, *d, *o;

      t_size = bits->t_width * bits->t_height;
      bits->t_bits = ZnMalloc(t_size);
      memset(bits->t_bits, 0, t_size);
      ostart = bits->bpixels;
      dstart = bits->t_bits;
      for (i = 0; i < height; i++) {
        d = dstart;
        o = ostart;
        for (j = 0; j < width; j++) {
          *d++ = ZnGetBitmapPixel(bits->bpixels, bits->rowstride, j, i) ? 255 : 0;
        }
        ostart += bits->rowstride;
        dstart += bits->t_width;
      }
    }

    /*
     * This is a photo: use the photo API, it is simple.
     */
    else if (bits->tkphoto) {
      unsigned int       x, y, t_stride;
      unsigned char      *obptr, *bptr, *bp2, *pixels;
      int                green_off, blue_off, alpha_off;
      Tk_PhotoImageBlock block;

      t_stride = bits->t_width * 4;
      t_size = t_stride * bits->t_height;
      /*printf("t_width: %d(%d), t_height: %d(%d)\n", bits->t_width, width, bits->t_height, height);*/
      bits->t_bits = ZnMalloc(t_size);
      Tk_PhotoGetImage(bits->tkphoto, &block);
      green_off = block.offset[1] - block.offset[0];
      blue_off = block.offset[2] - block.offset[0];
#ifdef PTK
      alpha_off = 3;
#else
      alpha_off = block.offset[3] - block.offset[0];
#endif
      /*printf("width %d, height: %d redoff: %d, greenoff: %d, blueoff: %d, alphaoff: %d\n",
             block.width, block.height, block.offset[0], green_off,
             blue_off, alpha_off);*/
      pixels = block.pixelPtr;
      bptr = bits->t_bits;
  
      for (y = 0; y < height; y++) {
        bp2 = bptr;
        obptr = pixels;
        for (x = 0; x < width; x++) {
          *bp2++ = obptr[0];         /* r */
          *bp2++ = obptr[green_off]; /* g */
          *bp2++ = obptr[blue_off];  /* b */
          *bp2++ = obptr[alpha_off]; /* alpha */
          obptr += block.pixelSize;
        }
        /*for (x = width; x < t_width; x++) {
          *bp2 = 0; bp2++;
          *bp2 = 0; bp2++;
          *bp2 = 0; bp2++;
          *bp2 = 0; bp2++;
          }*/
        bptr += t_stride;
        pixels += block.pitch;
      }
      /*for (y = height; y < t_height; y++) {
        memset(bptr, 0, t_stride);
        bptr += t_stride;
        }*/
    }

    /*
     * This is another image format (not a photo): try to
     * guess the pixels and the transparency (on or off)
     * from a locally drawn pixmap.
     */
    else {
      GatherImageTexels(bits->dpy, bits);
    }
  }

  if (!this->i.texobj) {
    glGenTextures(1, &this->i.texobj);
    /*printf("%d creation texture %d pour image %s\n",
      bits, this->i.texobj, ZnNameOfImage(this));*/
    glBindTexture(GL_TEXTURE_2D, this->i.texobj);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glGetError();
    if (is_bmap) {
      glTexImage2D(GL_TEXTURE_2D, 0, GL_INTENSITY4,
                   this->bits->t_width, this->bits->t_height,
                   0, GL_LUMINANCE, GL_UNSIGNED_BYTE, this->bits->t_bits);
    }
    else {
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA,
                   this->bits->t_width, this->bits->t_height,
                   0, GL_RGBA, GL_UNSIGNED_BYTE, this->bits->t_bits);
    }
    if (glGetError() != GL_NO_ERROR) {
      ZnWarning("Can't allocate the texture for image ");
      ZnWarning(ZnNameOfImage(image));
     ZnWarning("\n");
    }
    glBindTexture(GL_TEXTURE_2D, 0);
  }

  *t = this->bits->t;
  *s = this->bits->s;
  return this->i.texobj;
}
#endif


#ifdef GL

#define MAX_GLYPHS_PER_GRAB 256

typedef struct _TexFontInfo {
  struct _TexFont *txf;
  GLuint        texobj;
  Display       *dpy;
  unsigned int  refcount;
  struct _TexFontInfo *next;
} TexFontInfo;

typedef struct {
  short         width;
} PerGlyphInfo, *PerGlyphInfoPtr;

typedef struct _TexFont {
  TexFontInfo   *tfi;
  Tk_Font       tkfont;
  unsigned int  tex_width;
  unsigned int  tex_height;
  int           ascent;
  int           descent;
  unsigned int  max_char_width;
  unsigned char *teximage;
  unsigned int  num_glyphs;
  PerGlyphInfo  *glyph;
  ZnTexGVI      *tgvi;
  Tcl_HashEntry *hash;
} TexFont;

typedef struct _DeferredGLGlyphs {
  ZnWInfo       *wi;
  TexFont       *txf;
} DeferredGLGlyphsStruct;

ZnList DeferredGLGlyphs;


#ifndef PTK_800
#include "CharsetUTF8.h"
#else
#include "CharsetISO8859-15.h"
#endif


static void
SuckGlyphsFromServer(ZnWInfo    *wi,
                     TexFont    *txf)
{
  Pixmap        offscreen = 0;
  XImage        *image = NULL;
  GC            xgc = 0;
  unsigned int  height, length, pixwidth;
  unsigned int  i, j, use_max_width;
  unsigned int  wgap=2, hgap=2, tex_width, tex_height;
  unsigned char *to;
  unsigned int  x, y;
  unsigned int  width=0, maxSpanLength;
  int           grabList[MAX_GLYPHS_PER_GRAB];
  unsigned int  glyphsPerGrab = MAX_GLYPHS_PER_GRAB;
  unsigned int  numToGrab, glyph;
  ZnTexGVI      *tgvip;
  Tk_FontMetrics fm;
  CONST unsigned char   *cur, *next;
#ifndef PTK_800
  Tcl_UniChar   uni_ch;
#endif
  ZnGLContextEntry *ce = ZnGetGLContext(wi->dpy);

  /*printf("loading a font \n");*/
  Tk_GetFontMetrics(txf->tkfont, &fm);
#ifndef PTK_800
  txf->num_glyphs = Tcl_NumUtfChars(ZnDefaultCharset, strlen(ZnDefaultCharset));
#else
  txf->num_glyphs = strlen(ZnDefaultCharset);
#endif
  txf->glyph = ZnMalloc(txf->num_glyphs * sizeof(PerGlyphInfo));
  if (!txf->glyph) {
    goto FreeAndReturn;
  }
  txf->tgvi = ZnMalloc(txf->num_glyphs * sizeof(ZnTexGVI));
  if (!txf->tgvi) {
    goto FreeAndReturn;
  }
  
  txf->ascent = fm.ascent;
  txf->descent = fm.descent;
  txf->max_char_width = 0;
  tex_width = tex_height = 0;
  use_max_width = 0;
  height = txf->ascent + txf->descent;
  tgvip = txf->tgvi;

  /*
   * Compute the max character size in the font. This may be
   * a bit heavy hammer style but it avoid guessing on characters
   * not available in the font.
   */
  cur = ZnDefaultCharset;
  i = 0;
  while (*cur) {
#ifndef PTK_800
    next = Tcl_UtfNext(cur);
#else
    next = cur + 1;
#endif
    Tk_MeasureChars(txf->tkfont, cur, next - cur, 0, TK_AT_LEAST_ONE, &length);
    txf->glyph[i].width = length;
    txf->max_char_width = MAX(txf->max_char_width, length);
    
    if (tex_width + length + wgap > ce->max_tex_size) {
      tex_width = 0;
      use_max_width = 1;
      tex_height += height + hgap;
      if ((tex_height > ce->max_tex_size) || (length > ce->max_tex_size)) {
        goto FreeAndReturn;
      }
    }

    tgvip->v0x = 0;
    tgvip->v0y = txf->descent - height;
    tgvip->v1x = length;
    tgvip->v1y = txf->descent;
    tgvip->t0x = (GLfloat) tex_width;
    tgvip->t0y = (GLfloat) tex_height;
    tgvip->t1x = tgvip->t0x + length;
    tgvip->t1y = tgvip->t0y + height;
    tgvip->advance = (GLfloat) length;
#ifndef PTK_800
    Tcl_UtfToUniChar(cur, &uni_ch);
    tgvip->code = uni_ch;
#else
    tgvip->code = *cur;
#endif 
    tex_width += length + wgap;

    cur = next;
    i++;
    tgvip++;
  }

  if (use_max_width) {
    tex_width = ce->max_tex_size;
  }
  tex_height += height;

  /*
   * Round the texture size to the next power of two.
   */
  tex_height = To2Power(tex_height);
  tex_width = To2Power(tex_width);
  if ((tex_height > ce->max_tex_size) || (tex_width > ce->max_tex_size)) {
    fprintf(stderr, "Font doesn't fit into a texture\n");
    goto FreeAndReturn;
  } 
  txf->tex_width = tex_width;
  txf->tex_height = tex_height;
  /*printf("(%s) Texture size is %d x %d for %d chars (max size: %d)\n",
    Tk_NameOfFont(font), txf->tex_width, txf->tex_height, txf->num_glyphs, ce->max_tex_size);*/

  /*
   * Now render the font bits into the texture.
   */
  txf->teximage = ZnMalloc(tex_height * tex_width);
  if (!txf->teximage) {
    goto FreeAndReturn;
  }
  memset(txf->teximage, 0, tex_height * tex_width);

  maxSpanLength = (txf->max_char_width + 7) / 8;
  /* Be careful determining the width of the pixmap; the X protocol allows
     pixmaps of width 2^16-1 (unsigned short size) but drawing coordinates
     max out at 2^15-1 (signed short size).  If the width is too large, we
     need to limit the glyphs per grab.  */
  if ((glyphsPerGrab * 8 * maxSpanLength) >= (1 << 15)) {
    glyphsPerGrab = (1 << 15) / (8 * maxSpanLength);
  }
  pixwidth = glyphsPerGrab * 8 * maxSpanLength;
  offscreen = Tk_GetPixmap(wi->dpy, RootWindowOfScreen(wi->screen),
                           (int) pixwidth, (int) height, 1);
  
  xgc = XCreateGC(wi->dpy, offscreen, 0, NULL);
  XSetForeground(wi->dpy, xgc, WhitePixelOfScreen(wi->screen));
  XSetBackground(wi->dpy, xgc, WhitePixelOfScreen(wi->screen));
  XFillRectangle(wi->dpy, offscreen, xgc, 0, 0, pixwidth, height);
  XSetForeground(wi->dpy, xgc, BlackPixelOfScreen(wi->screen));
  XSetFont(wi->dpy, xgc, Tk_FontId(txf->tkfont));

  numToGrab = 0;
  cur = ZnDefaultCharset;
  i = 0;

  while (*cur) {
#ifndef PTK_800
    next = Tcl_UtfNext(cur);
#else
    next = cur + 1;
#endif
    if (txf->glyph[i].width != 0) {
      Tk_DrawChars(wi->dpy, offscreen, xgc, txf->tkfont, cur, next - cur, 
                   (int) (8*maxSpanLength*numToGrab), txf->ascent);
      grabList[numToGrab] = i;    
      numToGrab++;
    }

    if ((numToGrab >= glyphsPerGrab) || (i == txf->num_glyphs - 1)) {
      image = XGetImage(wi->dpy, offscreen, 0, 0, pixwidth, height, 1, XYPixmap);

      for (j = 0; j < numToGrab; j++) {
        glyph = grabList[j];
        width = txf->glyph[glyph].width;
        tgvip = &txf->tgvi[glyph];
        to = txf->teximage + (int) (tgvip->t0y * tex_width) + (int) tgvip->t0x;
        tgvip->t0x = tgvip->t0x / (GLfloat) tex_width;
        tgvip->t0y = tgvip->t0y / (GLfloat) tex_height;
        tgvip->t1x = tgvip->t1x / (GLfloat) tex_width;
        tgvip->t1y = tgvip->t1y / (GLfloat) tex_height;
        for (y = 0; y < height; y++) {
          for (x = 0; x < width; x++, to++) {
            /* XXX The algorithm used to suck across the font ensures that
               each glyph begins on a byte boundary.  In theory this would
               make it convienent to copy the glyph into a byte oriented
               bitmap.  We actually use the XGetPixel function to extract
               each pixel from the image which is not that efficient.  We
               could either do tighter packing in the pixmap or more
               efficient extraction from the image.  Oh well.  */
            if (XGetPixel(image, (int) (j*maxSpanLength*8) + x, y) == BlackPixelOfScreen(wi->screen)) {
              *to = 255;
              }
          }
          to += tex_width - width;
        }
      }
      XDestroyImage(image);
      image = NULL;
      numToGrab = 0;
      /* do we need to clear the offscreen pixmap to get more? */
      if (i < txf->num_glyphs - 1) {
        XSetForeground(wi->dpy, xgc, WhitePixelOfScreen(wi->screen));
        XFillRectangle(wi->dpy, offscreen, xgc, 0, 0,
                       8 * maxSpanLength * glyphsPerGrab, height);
        XSetForeground(wi->dpy, xgc, BlackPixelOfScreen(wi->screen));
      }
    }
    
    cur = next;
    i++;
  }

  XFreeGC(wi->dpy, xgc);
  Tk_FreePixmap(wi->dpy, offscreen);
  return;

 FreeAndReturn:
  if (txf->glyph) {
    ZnFree(txf->glyph);
    txf->glyph = NULL;
  }
  if (txf->tgvi) {
    ZnFree(txf->tgvi);
    txf->tgvi = NULL;    
  }
  if (txf->teximage) {
    ZnFree(txf->teximage);
    txf->teximage = NULL;    
  }
  ZnWarning("Cannot load font texture for font ");
  ZnWarning(Tk_NameOfFont(txf->tkfont));
  ZnWarning("\n");
}

static void
ZnNeedToGetGLGlyphs(ZnWInfo     *wi,
                    TexFont     *txf)
{
  DeferredGLGlyphsStruct dgg, *dggp;
  int                    i, num;

  if (!DeferredGLGlyphs) {
    DeferredGLGlyphs = ZnListNew(4, sizeof(DeferredGLGlyphsStruct));
  }
  dggp = ZnListArray(DeferredGLGlyphs);
  num = ZnListSize(DeferredGLGlyphs);
  for (i = 0; i < num; i++, dggp++) {
    if (dggp->txf == txf) {
      return;
    }
  }
  
  dgg.wi = wi;
  dgg.txf = txf;
  ZnListAdd(DeferredGLGlyphs, &dgg, ZnListTail);
  /*printf("adding a font to load\n");*/
}

void
ZnGetDeferredGLGlyphs(void)
{
  DeferredGLGlyphsStruct *dggp;
  int                    i, num = ZnListSize(DeferredGLGlyphs);

  if (!num) {
    return;
  }
  dggp = ZnListArray(DeferredGLGlyphs);
  for (i = 0; i < num; i++, dggp++) {
    SuckGlyphsFromServer(dggp->wi, dggp->txf);
  }
  ZnListEmpty(DeferredGLGlyphs);
}

static void
ZnRemovedDeferredGLGlyph(TexFont        *txf)
{
  DeferredGLGlyphsStruct *dggp;
  int                    i, num;

  dggp = ZnListArray(DeferredGLGlyphs);
  num = ZnListSize(DeferredGLGlyphs);
  for (i = 0; i < num; i++, dggp++) {
    if (dggp->txf == txf) {
      ZnListDelete(DeferredGLGlyphs, i);
      return;
    }
  }
}


/*
 **********************************************************************************
 *
 * ZnGetTexFont --
 *
 **********************************************************************************
 */
ZnTexFontInfo
ZnGetTexFont(ZnWInfo    *wi,
             Tk_Font    font)
{
  TexFont       *txf;
  TexFontInfo   *tfi;
  static int    inited = 0;
  Tcl_HashEntry *entry;
  int           new;

  if (!inited) {
    Tcl_InitHashTable(&font_textures, TCL_STRING_KEYS);
    inited = 1;
  }

  /*  printf("family: %s, size: %d, weight: %d, slant: %d, underline: %d, overstrike: %d\n",
         tft->fa.family, tft->fa.size, tft->fa.weight, tft->fa.slant, tft->fa.underline,
         tft->fa.overstrike);
  */
  entry = Tcl_FindHashEntry(&font_textures, Tk_NameOfFont(font));
  if (entry != NULL) {
    /*printf("Found an already created font %s\n", Tk_NameOfFont(font));*/
    txf = (TexFont *) Tcl_GetHashValue(entry);
  }
  else {
    /*printf("Creating a new texture font for %s\n", Tk_NameOfFont(font));*/
    txf = ZnMalloc(sizeof(TexFont));
    if (txf == NULL) {
      return NULL;
    }
    txf->tfi = NULL;
    txf->tgvi = NULL;
    txf->glyph = NULL;
    txf->teximage = NULL;

    /* Get a local reference to the font, it will be deallocated
     * when no further references on this TexFont exist. */
    txf->tkfont = Tk_GetFont(wi->interp, wi->win, Tk_NameOfFont(font));

    /*printf("Scheduling glyph loading for font %s\n", ZnNameOfTexFont(tfi));*/
    ZnNeedToGetGLGlyphs(wi, txf);

    entry = Tcl_CreateHashEntry(&font_textures, Tk_NameOfFont(font), &new);
    Tcl_SetHashValue(entry, (ClientData) txf);
    txf->hash = entry;
  }
 
  /*
   * Now locate the texture obj in the texture list for this widget.
   */
  for (tfi = txf->tfi; tfi != NULL; tfi = tfi->next) {
    if (tfi->dpy == wi->dpy) {
      tfi->refcount++;
      return tfi;
    }
  }
  /*
   * Not found allocate a new texture object.
   */
  tfi = ZnMalloc(sizeof(TexFontInfo));
  if (tfi == NULL) {
    return NULL;
  }
  tfi->refcount = 1;
  tfi->dpy = wi->dpy;
  tfi->txf = txf;
  tfi->texobj = 0;
  tfi->next = txf->tfi;
  txf->tfi = tfi;

  return tfi;
}


/*
 **********************************************************************************
 *
 * ZnNameOfTexFont --
 *
 **********************************************************************************
 */
char const *
ZnNameOfTexFont(ZnTexFontInfo   tfi)
{
  return Tk_NameOfFont(((TexFontInfo *) tfi)->txf->tkfont);
}

/*
 **********************************************************************************
 *
 * ZnTexFontTex --
 *
 **********************************************************************************
 */
GLuint
ZnTexFontTex(ZnTexFontInfo      tfi)
{
  TexFontInfo   *this = (TexFontInfo *) tfi;
  TexFont       *txf = this->txf;

  if (!txf->teximage) {
    return 0;
  }
  if (!this->texobj) {
    glGenTextures(1, &this->texobj);
    /*printf("%d creation texture %d pour la fonte %s\n",
      this->dpy, this->texobj, ZnNameOfTexFont(tfi));*/
    glBindTexture(GL_TEXTURE_2D, this->texobj);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glGetError();
    /*printf("Demande texture de %d x %d\n", txf->tex_width, txf->tex_height);*/
    glTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA, txf->tex_width,
                 txf->tex_height, 0, GL_ALPHA, GL_UNSIGNED_BYTE,
                 txf->teximage);
    if (glGetError() != GL_NO_ERROR) {
      ZnWarning("Can't allocate the texture for font ");
      ZnWarning(ZnNameOfTexFont(tfi));
      ZnWarning("\n");
    }
    glBindTexture(GL_TEXTURE_2D, 0);
  }

  /*printf("%d utilisation de la texture %d\n", this->wi, this->texobj);*/
  return this->texobj;
}


/*
 **********************************************************************************
 *
 * ZnFreeTexFont --
 *
 **********************************************************************************
 */
void
ZnFreeTexFont(ZnTexFontInfo     tfi)
{
  TexFontInfo   *this = ((TexFontInfo *) tfi);
  TexFont       *txf = this->txf;
  TexFontInfo   *prev, *scan;

  for (prev=NULL, scan=this->txf->tfi; (scan!=NULL)&&(scan != this);
       prev=scan, scan=scan->next);
  if (scan != this) {
    return;
  }

  /*
   * Decrement tex font object refcount.
   */
  this->refcount--;
  if (this->refcount != 0) {
    return;
  }

  /*
   * Unlink the deleted tex font info.
   */
  if (prev == NULL) {
    txf->tfi = this->next;
  }
  else {
    prev->next = this->next;
  }
  if (this->texobj) {
    ZnGLContextEntry *ce;
    /*printf("%d Freeing texture %d from font %s\n",
      this->dpy, this->texobj, ZnNameOfTexFont(tfi));*/
    ce = ZnGLMakeCurrent(this->dpy, 0);
    if (ce) {
      glDeleteTextures(1, &this->texobj);
      ZnGLReleaseContext(ce);
    }
  }
  /*
   * Remove the font from the deferred load list
   */
  ZnRemovedDeferredGLGlyph(txf);

  /*
   * There is no more client for this font
   * deallocate the structures.
   */
  if (txf->tfi == NULL) {
    /*printf("%d Freeing txf for %s\n", this, ZnNameOfTexFont(tfi));*/
    Tk_FreeFont(txf->tkfont);
    ZnFree(txf->glyph);
    ZnFree(txf->tgvi);
    ZnFree(txf->teximage);
    Tcl_DeleteHashEntry(txf->hash);
    ZnFree(txf);
  }

  ZnFree(this);
}


/*
 **********************************************************************************
 *
 * ZnGetFontIndex --
 *
 **********************************************************************************
 */
int
ZnGetFontIndex(ZnTexFontInfo    tfi,
               int              c)
{
  TexFont       *txf;
  ZnTexGVI      *tgvi;
  int           code, min, max, mid;

  if (c < 127) {
    /*
     * It is possible to index the points below 127. Unicode
     * is the same as ascii down there.
     */
    return c - 32;
  }

  /*
   * Else, search by dichotomy in the remaining chars.
   */
  txf = ((TexFontInfo *) tfi)->txf;
  tgvi = txf->tgvi;
  if (!tgvi) {
    return -1;
  }
  min = 127 - 32;
  max = txf->num_glyphs;
  while (min < max) {
    mid = (min + max) >> 1;
    code = tgvi[mid].code;
    if (c == code) {
      return mid;
    }
    if (c < code) {
      max = mid;
    }
    else {
      min = mid + 1;
    }
  }
  //fprintf(stderr, "Tried to access unavailable texture font character %d (Unicode)\n", c);
  return -1;
}

/*
 **********************************************************************************
 *
 * ZnTexFontGVI --
 *
 **********************************************************************************
 */
ZnTexGVI *
ZnTexFontGVI(ZnTexFontInfo      tfi,
             int                c)
{
  TexFont       *txf = ((TexFontInfo *) tfi)->txf;
  ZnTexGVI      *tgvi = NULL;
  int           index;

  index = ZnGetFontIndex(tfi, c);
  if (index >= 0) {
    tgvi = &txf->tgvi[index];
  }

  return tgvi;
}

#endif
