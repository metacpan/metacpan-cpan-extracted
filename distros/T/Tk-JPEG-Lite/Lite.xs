/*
  Copyright (c) 1995 Nick Ing-Simmons. All rights reserved.
  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.
*/

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <tkGlue.def>

#include <pTk/tkPort.h>
#include <pTk/tkInt.h>
#include <pTk/tkImgPhoto.h>
#include <pTk/imgInt.h>
#include <pTk/tkVMacro.h>
#include <tkGlue.h>
#include <tkGlue.m>

extern Tk_PhotoImageFormat	imgFmtJPEG;

DECLARE_VTABLES;
TkimgphotoVtab *TkimgphotoVptr;
ImgintVtab *ImgintVptr;

MODULE = Tk::JPEG::Lite	PACKAGE = Tk::JPEG::Lite

PROTOTYPES: DISABLE

BOOT:
 {
  IMPORT_VTABLES;
  TkimgphotoVptr  =   (TkimgphotoVtab *) SvIV(FindTkVarName("TkimgphotoVtab",5));    \
  ImgintVptr  =   (ImgintVtab *) SvIV(FindTkVarName("ImgintVtab",5));    \
  Tk_CreatePhotoImageFormat(&imgFmtJPEG);
 }
