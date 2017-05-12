/////////////////////////////////////////////////////////////////////////////
// Name:        PdfDocument.xs
// Purpose:     XS for Wx::PdfDocument Module
// Author:      Mark Wardell
// Modified by:
// Created:     24/07/2006
// RCS-ID:      $Id: PdfDocument.xs,v 1.0 2006/07/24 00:00:00 netcon Exp $
// Copyright:   (c) 2006 Mark Wardell
// Licence:     This program is free software; you can redistribute it and/or
//              modify it under the same terms as Perl itself
/////////////////////////////////////////////////////////////////////////////

#define PERL_NO_GET_CONTEXT
#include "cpp/wxapi.h"
#include "cpp/constants.h"
#include "cpp/overload.h"
#undef THIS
#undef IsSet

#include <wx/pdfdoc.h>
#include <wx/pdffont.h>
#include <wx/pdfcolour.h>
#include <wx/pdflinestyle.h>
#include <wx/pdfinfo.h>
#include <wx/pdfshape.h>
#include <wx/pdflayer.h>
#include <wx/pdffontmanager.h>
#include <wx/pdfbarcode.h>
#include <wx/pdfdc.h>
#include <wx/pdfprint.h>
#include <wx/pdfcoonspatchmesh.h>

#include <cpp/ovl_const.h>
#include <cpp/ovl_const.cpp>

MODULE=Wx__PdfDocument

BOOT:
  INIT_PLI_HELPERS( wx_pli_helpers );

INCLUDE_COMMAND: $^X -I./ -MExtUtils::XSpp::Cmd -e xspp -- -t typemap.xsp XS/PdfDocument.xsp

INCLUDE_COMMAND: $^X -I./ -MExtUtils::XSpp::Cmd -e xspp -- -t typemap.xsp XS/PdfShape.xsp

INCLUDE_COMMAND: $^X -I./ -MExtUtils::XSpp::Cmd -e xspp -- -t typemap.xsp XS/PdfInfo.xsp

INCLUDE_COMMAND: $^X -I./ -MExtUtils::XSpp::Cmd -e xspp -- -t typemap.xsp XS/PdfLayer.xsp

INCLUDE_COMMAND: $^X -I./ -MExtUtils::XSpp::Cmd -e xspp -- -t typemap.xsp XS/PdfColour.xsp

INCLUDE_COMMAND: $^X -I./ -MExtUtils::XSpp::Cmd -e xspp -- -t typemap.xsp XS/PdfLineStyle.xsp

INCLUDE_COMMAND: $^X -I./ -MExtUtils::XSpp::Cmd -e xspp -- -t typemap.xsp XS/PdfDC.xsp

INCLUDE_COMMAND: $^X -I./ -MExtUtils::XSpp::Cmd -e xspp -- -t typemap.xsp XS/PdfFont.xsp

INCLUDE_COMMAND: $^X -I./ -MExtUtils::XSpp::Cmd -e xspp -- -t typemap.xsp XS/PdfFontDescription.xsp

INCLUDE_COMMAND: $^X -I./ -MExtUtils::XSpp::Cmd -e xspp -- -t typemap.xsp XS/PdfLink.xsp

INCLUDE_COMMAND: $^X -I./ -MExtUtils::XSpp::Cmd -e xspp -- -t typemap.xsp XS/PdfFontManager.xsp

INCLUDE_COMMAND: $^X -I./ -MExtUtils::XSpp::Cmd -e xspp -- -t typemap.xsp XS/PdfBarCode.xsp

INCLUDE_COMMAND: $^X -I./ -MExtUtils::XSpp::Cmd -e xspp -- -t typemap.xsp XS/PdfPrinting.xsp

INCLUDE_COMMAND: $^X -I./ -MExtUtils::XSpp::Cmd -e xspp -- -t typemap.xsp XS/PdfCoonsPatchMesh.xsp


#include "cpp/pdf_constants.cpp"

#  //FIXME//tricky
#if defined(__WXMSW__)
#undef XS
#define XS( name ) WXXS( name )
#endif

MODULE=Wx__PdfDocument
