#################################################################################
# Name:        XS/TreeListColumnInfo.xs
# Purpose:     XS for Wx::TreeListColumnInfo
# Author:      Mark Wardell
# Modified by:
# Created:     08/08/2006
# RCS-ID:      $Id: TreeListColumnInfo.xs 17 2011-06-21 14:21:11Z mark.dootson $
# Copyright:   (c) 2006 - 2011 Mark Wardell
# Licence:     This program is free software; you can redistribute it and/or
#              modify it under the same terms as Perl itself
##################################################################################

MODULE=Wx__TreeListCtrl PACKAGE=Wx::TreeListColumnInfo

#include <cpp/helpers.h>


# DECLARE_OVERLOAD( wtlc, Wx::TreeListColumnInfo )


void
new( ... )
  PPCODE:
    BEGIN_OVERLOAD()
        MATCH_REDISP( wxPliOvl_wtlc, newCopy )
        MATCH_ANY_REDISP( newFull )
    END_OVERLOAD( "Wx::TreeListColumnInfo::new" )


wxTreeListColumnInfo*
newCopy( CLASS, other )
    PlClassName CLASS
	wxTreeListColumnInfo* other
  CODE:
    RETVAL = new wxTreeListColumnInfo( *other );
  OUTPUT:
    RETVAL


wxTreeListColumnInfo*
newFull( CLASS, text, width = DEFAULT_COL_WIDTH, flag = wxALIGN_LEFT, image = -1, shown = true, edit = false )
    PlClassName CLASS
    wxString text
    int width
    int flag
    int image
    bool shown
    bool edit
  CODE:
    RETVAL = new wxTreeListColumnInfo( text, width, flag, image, shown, edit );
  OUTPUT:
    RETVAL

static void
wxTreeListColumnInfo::CLONE()
  CODE:
    wxPli_thread_sv_clone( aTHX_ CLASS, (wxPliCloneSV)wxPli_detach_object );

void
wxTreeListColumnInfo::DESTROY()
  CODE:
    wxPli_thread_sv_unregister( aTHX_ wxPli_get_class( aTHX_ ST(0) ), THIS, ST(0) );
    delete THIS;

wxString
wxTreeListColumnInfo::GetText()

void
wxTreeListColumnInfo::SetText( text )
    wxString text

int
wxTreeListColumnInfo::GetWidth()

void
wxTreeListColumnInfo::SetWidth( width )
    int width

int
wxTreeListColumnInfo::GetAlignment()

void
wxTreeListColumnInfo::SetAlignment( flag )
    int flag

int
wxTreeListColumnInfo::GetImage()

void
wxTreeListColumnInfo::SetImage( image )
    int image

int
wxTreeListColumnInfo::GetSelectedImage()

void
wxTreeListColumnInfo::SetSelectedImage( image )
    int image

bool
wxTreeListColumnInfo::IsEditable()

void
wxTreeListColumnInfo::SetEditable( edit )
    bool edit

bool
wxTreeListColumnInfo::IsShown()

void
wxTreeListColumnInfo::SetShown( shown )
    bool shown

MODULE=Wx__TreeListCtrl
