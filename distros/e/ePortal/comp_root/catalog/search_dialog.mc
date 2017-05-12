%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software
%#
%#----------------------------------------------------------------------------

<& /search_dialog.mc, title => pick_lang(rus => 'Поиск в каталоге',eng => 'Search in Catalog'),
    vertical => 1, show_all => 0, label => '',
    action => "/catalog/search.htm" &>
