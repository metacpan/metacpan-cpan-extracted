/////////////////////////////////////////////////////////////////////////////
// Name:        ht_constants.cpp
// Purpose:     constants for Wx::DialUpEvent
// Author:      Mattia Barbon
// Modified by:
// Created:     21/ 3/2001
// RCS-ID:      
// Copyright:   (c) 2001 Mattia Barbon
// Licence:     This program is free software; you can redistribute it and/or
//              modify it under the same terms as Perl itself
/////////////////////////////////////////////////////////////////////////////

#include "cpp/constants.h"

double du_constant( const char* name, int arg )
{
    // !package: Wx
    // !parser: sub { $_[0] =~ m<^\s*r\w*\(\s*(\w+)\s*\);\s*(?://(.*))?$> }
    // !tag: dialupmanager
#define r( n ) \
    if( strEQ( name, #n ) ) \
        return n;

    WX_PL_CONSTANT_INIT();

    switch( fl )
    {
        case 'E':  // cause it's wx>E<VT_DIALUP..., very important
            r( wxEVT_DIALUP_CONNECTED );
            r( wxEVT_DIALUP_DISCONNECTED );
            break;
    }
#undef r

  WX_PL_CONSTANT_CLEANUP();
}

wxPlConstants dialupmanager_module( &du_constant );


