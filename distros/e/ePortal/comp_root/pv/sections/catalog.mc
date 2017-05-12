%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software
%#
%#
%#----------------------------------------------------------------------------
<%perl>
  my $section = $ARGS{section};
  my $setupinfo = $section->setupinfo_hash;

  my $catalog = new ePortal::Catalog;
  $catalog->restore_where(parent_id => undef, recordtype => 'group', hidden => 0, limit_rows => 20);
</%perl>

<table border=0 cellspacing=0 cellpadding=0 width="98%">
% while ($catalog->restore_next) {
  <tr><td class="sidemenu" nowrap>
   <a href="<% '/catalog/' . $catalog->id %>/"><% $catalog->Title %></a>
  </td></tr>
% }
</table>





%#=== @metags attr =========================================================
<%attr>
def_title => { eng => 'Resources catalogue', rus => 'Каталог ресурсов'},
def_width => 'N',
def_url => '/catalog/index.htm',
</%attr>
