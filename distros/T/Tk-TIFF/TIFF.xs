/*
  Copyright (c) 1998 Slaven Rezic. All rights reserved.
  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.
*/

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <tkGlue.def>

#include "pTk/tkPort.h"
#include "pTk/tkInt.h"
#include "pTk/tkImgPhoto.h"
#include "pTk/imgInt.h"
#include "pTk/tkVMacro.h"
#include "tkGlue.h"
#include "tkGlue.m"

extern int contrast_enhance;

extern Tk_PhotoImageFormat      imgFmtTIFF;
TkimgphotoVtab *TkimgphotoVptr;
ImgintVtab *ImgintVptr;

DECLARE_VTABLES;

MODULE = Tk::TIFF	PACKAGE = Tk::TIFF

int
getContrastEnhance()
  CODE:
      RETVAL = contrast_enhance;
  OUTPUT:
      RETVAL

int
setContrastEnhance(x)
      int x;
  CODE:
      RETVAL = (contrast_enhance = x);
  OUTPUT:
      RETVAL

PROTOTYPES: DISABLE

BOOT:
 {
  IMPORT_VTABLES;
  TkimgphotoVptr = (TkimgphotoVtab *) SvIV(FindTkVarName("TkimgphotoVtab",5));
  ImgintVptr     = (ImgintVtab *) SvIV(FindTkVarName("ImgintVtab",5));
  Tk_CreatePhotoImageFormat(&imgFmtTIFF);
 }
