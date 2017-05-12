/////////////////////////////////////////////////////////////////////////////
// Name:        TreeListCtrl.xs
// Purpose:     XS for Wx::TreeListCtrl
// Author:      Mark Wardell
// Modified by:
// Created:     08/08/2006
// RCS-ID:      $Id: TreeListCtrl.xs 3 2010-02-17 06:08:51Z mark.dootson $
// Copyright:   (c) 2006 - 2010 Mark Wardell
// Licence:     This program is free software; you can redistribute it and/or
//              modify it under the same terms as Perl itself
/////////////////////////////////////////////////////////////////////////////

#define PERL_NO_GET_CONTEXT

#ifdef __WXMSW__
#ifdef __MINGW32__
    #define _WIN32_WINNT Windows2003
    #define WINVER Windows2003
    #define _WIN32_IE IE7
#endif
#endif

#include <cpp/wxapi.h>

#undef THIS

#include <cpp/overload.h>
#include <cpp/treelistctrl.cpp>
#include <cpp/v_cback.h>
#include <cpp/ovl_const.h>
#include <cpp/ovl_const.cpp>

MODULE = Wx__TreeListCtrl

BOOT:
  INIT_PLI_HELPERS( wx_pli_helpers );

#include <cpp/wxtreelist.h>

INCLUDE: XS/TreeListCtrl.xs
INCLUDE: XS/TreeListColumnInfo.xs

#include <cpp/tl_constants.cpp>

MODULE = Wx__TreeListCtrl


