/////////////////////////////////////////////////////////////////////////////
// Name:        tl_constants.cpp
// Purpose:     wxPerl constants
// Author:      Mark Wardell
// SVN ID:      $Id: tl_constants.cpp 3 2010-02-17 06:08:51Z mark.dootson $
// Copyright:   (c) 2006 - 2010 Mark Wardell
// Licence:     This program is free software; you can redistribute it and/or
//              modify it under the same terms as Perl itself
/////////////////////////////////////////////////////////////////////////////


#include <cpp/constants.h>

double treelist_constant( const char* name, int arg )
{
    // !package: Wx
    // !parser: sub { $_[0] =~ m<^\s*r\w*\(\s*(\w+)\s*\);\s*(?://(.*))?$> }
    // !tag: grid
#define r( n ) \
    if( strEQ( name, #n ) ) \
        return n;

    WX_PL_CONSTANT_INIT();

    switch( fl )
    {
    case 'T':
        r( wxTL_MODE_NAV_FULLTREE );
        r( wxTL_MODE_NAV_EXPANDED );
        r( wxTL_MODE_NAV_VISIBLE );
        r( wxTL_MODE_NAV_LEVEL );
        r( wxTL_MODE_FIND_EXACT );
        r( wxTL_MODE_FIND_PARTIAL );
        r( wxTL_MODE_FIND_NOCASE );
        r( wxTR_HAS_BUTTONS );
        r( wxTR_NO_LINES );
        r( wxTR_LINES_AT_ROOT );
        r( wxTR_TWIST_BUTTONS );
        r( wxTR_MULTIPLE );
        r( wxTR_EXTENDED );
        r( wxTR_HAS_VARIABLE_ROW_HEIGHT );
        r( wxTR_EDIT_LABELS );
        r( wxTR_ROW_LINES );
        r( wxTR_HIDE_ROOT );
        r( wxTR_FULL_ROW_HIGHLIGHT );
        r( wxTR_DEFAULT_STYLE );
        r( wxTR_SINGLE );
        r( wxTR_NO_BUTTONS );
        r( wxTR_VIRTUAL );
        r( wxTR_COLUMN_LINES );
        r( wxTREE_HITTEST_ONITEMCOLUMN );
        r( wxTR_SHOW_ROOT_LABEL_ONLY );
        break;
    default:
        break;
    }
#undef r

  WX_PL_CONSTANT_CLEANUP();
}

wxPlConstants treelist_module( &treelist_constant );

