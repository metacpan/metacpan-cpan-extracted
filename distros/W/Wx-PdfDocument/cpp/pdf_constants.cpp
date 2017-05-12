/////////////////////////////////////////////////////////////////////////////
// Name:        cpp/pdf_constants.cpp
// Purpose:     constants for Wx::PdfDocument
// Author:      Mark Wardell
// Created:     31/01/2006
// RCS-ID:      $Id: pdf_constants.cpp,v 1.0 2005/05/03 20:44:37 netcon Exp $
// Copyright:   (c) 2006, 2012 Mark Wardell
// Licence:     This program is free software; you can redistribute it and/or
//              modify it under the same terms as Perl itself
/////////////////////////////////////////////////////////////////////////////

#include "cpp/constants.h"

double pdfdocument_constant( const char* name, int arg )
{
    // !package: Wx
    // !parser: sub { $_[0] =~ m<^\s*r\w*\(\s*(\w+)\s*\);\s*(?://(.*))?$> }
    // !tag: pdfdocument
#define r( n ) \
    if( strEQ( name, #n ) ) \
        return n;

    WX_PL_CONSTANT_INIT();

    switch( fl )
    {
      case 'P':
         r( wxPDF_BORDER_NONE );
         r( wxPDF_BORDER_LEFT );
         r( wxPDF_BORDER_RIGHT );
         r( wxPDF_BORDER_TOP );
         r( wxPDF_BORDER_BOTTOM );
         r( wxPDF_BORDER_FRAME );
         r( wxPDF_CORNER_NONE );
         r( wxPDF_CORNER_TOP_LEFT );
         r( wxPDF_CORNER_TOP_RIGHT );
         r( wxPDF_CORNER_BOTTOM_LEFT );
         r( wxPDF_CORNER_BOTTOM_RIGHT );
         r( wxPDF_CORNER_ALL );
         r( wxPDF_STYLE_NOOP );
         r( wxPDF_STYLE_DRAW );
         r( wxPDF_STYLE_FILL  );
         r( wxPDF_STYLE_FILLDRAW );
         r( wxPDF_STYLE_DRAWCLOSE  );
         r( wxPDF_STYLE_MASK );
         r( wxPDF_TEXT_RENDER_FILL );
         r( wxPDF_TEXT_RENDER_STROKE );
         r( wxPDF_TEXT_RENDER_FILLSTROKE );
         r( wxPDF_TEXT_RENDER_INVISIBLE );
         r( wxPDF_FONTSTYLE_REGULAR );
         r( wxPDF_FONTSTYLE_ITALIC );
         r( wxPDF_FONTSTYLE_BOLD );
         r( wxPDF_FONTSTYLE_BOLDITALIC );
         r( wxPDF_FONTSTYLE_UNDERLINE );
         r( wxPDF_FONTSTYLE_OVERLINE );
         r( wxPDF_FONTSTYLE_STRIKEOUT );
         r( wxPDF_FONTSTYLE_DECORATION_MASK );
         r( wxPDF_FONTSTYLE_MASK );
         r( wxPDF_PERMISSION_NONE );
         r( wxPDF_PERMISSION_PRINT );
         r( wxPDF_PERMISSION_MODIFY );
         r( wxPDF_PERMISSION_COPY );
         r( wxPDF_PERMISSION_ANNOT );
         r( wxPDF_PERMISSION_FILLFORM );
         r( wxPDF_PERMISSION_EXTRACT );
         r( wxPDF_PERMISSION_ASSEMBLE );
         r( wxPDF_PERMISSION_HLPRINT );
         r( wxPDF_PERMISSION_ALL );
         r( wxPDF_ENCRYPTION_RC4V1 );
         r( wxPDF_ENCRYPTION_RC4V2 );
         r( wxPDF_ENCRYPTION_AESV2 );
         r( wxPDF_PAGEBOX_MEDIABOX );
         r( wxPDF_PAGEBOX_CROPBOX );
         r( wxPDF_PAGEBOX_BLEEDBOX );
         r( wxPDF_PAGEBOX_TRIMBOX );
         r( wxPDF_PAGEBOX_ARTBOX );
         r( wxPDF_BORDER_SOLID );
         r( wxPDF_BORDER_DASHED );
         r( wxPDF_BORDER_BEVELED );
         r( wxPDF_BORDER_INSET );
         r( wxPDF_BORDER_UNDERLINE );
         r( wxPDF_ALIGN_LEFT );
         r( wxPDF_ALIGN_CENTER );
         r( wxPDF_ALIGN_RIGHT );
         r( wxPDF_ALIGN_JUSTIFY );
         r( wxPDF_ALIGN_TOP );
         r( wxPDF_ALIGN_MIDDLE );
         r( wxPDF_ALIGN_BOTTOM );
         r( wxPDF_ZOOM_FULLPAGE );
         r( wxPDF_ZOOM_FULLWIDTH );
         r( wxPDF_ZOOM_REAL );
         r( wxPDF_ZOOM_DEFAULT );
         r( wxPDF_ZOOM_FACTOR );
         r( wxPDF_LAYOUT_CONTINUOUS );
         r( wxPDF_LAYOUT_SINGLE );
         r( wxPDF_LAYOUT_TWO );
         r( wxPDF_LAYOUT_DEFAULT );
         r( wxPDF_VIEWER_HIDETOOLBAR );
         r( wxPDF_VIEWER_HIDEMENUBAR );
         r( wxPDF_VIEWER_HIDEWINDOWUI );
         r( wxPDF_VIEWER_FITWINDOW );
         r( wxPDF_VIEWER_CENTERWINDOW );
         r( wxPDF_VIEWER_DISPLAYDOCTITLE );
         r( wxPDF_MARKER_CIRCLE );
         r( wxPDF_MARKER_SQUARE );
         r( wxPDF_MARKER_TRIANGLE_UP );
         r( wxPDF_MARKER_TRIANGLE_DOWN );
         r( wxPDF_MARKER_TRIANGLE_LEFT );
         r( wxPDF_MARKER_TRIANGLE_RIGHT );
         r( wxPDF_MARKER_DIAMOND );
         r( wxPDF_MARKER_PENTAGON_UP );
         r( wxPDF_MARKER_PENTAGON_DOWN );
         r( wxPDF_MARKER_PENTAGON_LEFT );
         r( wxPDF_MARKER_PENTAGON_RIGHT );
         r( wxPDF_MARKER_STAR );
         r( wxPDF_MARKER_STAR4 );
         r( wxPDF_MARKER_PLUS );
         r( wxPDF_MARKER_CROSS );
         r( wxPDF_MARKER_SUN );
         r( wxPDF_MARKER_BOWTIE_HORIZONTAL );
         r( wxPDF_MARKER_BOWTIE_VERTICAL );
         r( wxPDF_MARKER_ASTERISK );
         r( wxPDF_MARKER_LAST );
         r( wxPDF_LINEAR_GRADIENT_HORIZONTAL );
         r( wxPDF_LINEAR_GRADIENT_VERTICAL );
         r( wxPDF_LINEAR_GRADIENT_MIDHORIZONTAL );
         r( wxPDF_LINEAR_GRADIENT_MIDVERTICAL );
         r( wxPDF_LINEAR_GRADIENT_REFLECTION_LEFT );
         r( wxPDF_LINEAR_GRADIENT_REFLECTION_RIGHT );
         r( wxPDF_LINEAR_GRADIENT_REFLECTION_TOP );
         r( wxPDF_LINEAR_GRADIENT_REFLECTION_BOTTOM );
         r( wxPDF_BLENDMODE_NORMAL );
         r( wxPDF_BLENDMODE_MULTIPLY );
         r( wxPDF_BLENDMODE_SCREEN );
         r( wxPDF_BLENDMODE_OVERLAY );
         r( wxPDF_BLENDMODE_DARKEN );
         r( wxPDF_BLENDMODE_LIGHTEN );
         r( wxPDF_BLENDMODE_COLORDODGE );
         r( wxPDF_BLENDMODE_COLORBURN );
         r( wxPDF_BLENDMODE_HARDLIGHT );
         r( wxPDF_BLENDMODE_SOFTLIGHT );
         r( wxPDF_BLENDMODE_DIFFERENCE );
         r( wxPDF_BLENDMODE_EXCLUSION );
         r( wxPDF_BLENDMODE_HUE );
         r( wxPDF_BLENDMODE_SATURATION );
         r( wxPDF_BLENDMODE_COLOR );
         r( wxPDF_BLENDMODE_LUMINOSITY );
         r( wxPDF_SHAPEDTEXTMODE_ONETIME );
         r( wxPDF_SHAPEDTEXTMODE_STRETCHTOFIT );
         r( wxPDF_SHAPEDTEXTMODE_REPEAT );
         r( wxPDF_PDFXNONE );
         r( wxPDF_PDFX1A2001 );
         r( wxPDF_PDFX32002 );
         r( wxPDF_PDFA1A );
         r( wxPDF_PDFA1B );
         r( wxPDF_RUN_DIRECTION_DEFAULT );
         r( wxPDF_RUN_DIRECTION_NO_BIDI );
         r( wxPDF_RUN_DIRECTION_LTR );
         r( wxPDF_RUN_DIRECTION_RTL );
         r( wxPDF_COLOURTYPE_UNKNOWN );
         r( wxPDF_COLOURTYPE_GRAY );
         r( wxPDF_COLOURTYPE_RGB );
         r( wxPDF_COLOURTYPE_CMYK );
         r( wxPDF_COLOURTYPE_SPOT );
         r( wxPDF_COLOURTYPE_PATTERN );
         r( wxPDF_LINECAP_NONE );
         r( wxPDF_LINECAP_BUTT );
         r( wxPDF_LINECAP_ROUND );
         r( wxPDF_LINECAP_SQUARE );
         r( wxPDF_LINEJOIN_NONE );
         r( wxPDF_LINEJOIN_MITER );
         r( wxPDF_LINEJOIN_ROUND );
         r( wxPDF_LINEJOIN_BEVEL );
         r( wxPDF_SEG_UNDEFINED );
         r( wxPDF_SEG_MOVETO );
         r( wxPDF_SEG_LINETO );
         r( wxPDF_SEG_CURVETO );
         r( wxPDF_SEG_CLOSE );
         r( wxPDF_OCG_TYPE_UNKNOWN );
         r( wxPDF_OCG_TYPE_LAYER );
         r( wxPDF_OCG_TYPE_TITLE );
         r( wxPDF_OCG_TYPE_MEMBERSHIP );
         r( wxPDF_OCG_INTENT_DEFAULT );
         r( wxPDF_OCG_INTENT_VIEW );
         r( wxPDF_OCG_INTENT_DESIGN );
         r( wxPDF_OCG_POLICY_ALLON );
         r( wxPDF_OCG_POLICY_ANYON );
         r( wxPDF_OCG_POLICY_ANYOFF );
         r( wxPDF_OCG_POLICY_ALLOFF );
         r( wxPDF_PRINTDIALOG_ALLOWNONE );
         r( wxPDF_PRINTDIALOG_ALLOWALL );
         r( wxPDF_PRINTDIALOG_FILEPATH );
         r( wxPDF_PRINTDIALOG_PROPERTIES );
         r( wxPDF_PRINTDIALOG_PROTECTION );
         r( wxPDF_PRINTDIALOG_OPENDOC );
         r( wxPDF_MAPMODESTYLE_STANDARD );
         r( wxPDF_MAPMODESTYLE_MSW );
         r( wxPDF_MAPMODESTYLE_GTK );
         r( wxPDF_MAPMODESTYLE_MAC );
         r( wxPDF_MAPMODESTYLE_PDF );
    }
#undef r

  WX_PL_CONSTANT_CLEANUP();
}

wxPlConstants pdfdocument_module( &pdfdocument_constant );

