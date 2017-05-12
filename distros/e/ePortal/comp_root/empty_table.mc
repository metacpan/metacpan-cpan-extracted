%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software.
%#
%#----------------------------------------------------------------------------
<%perl>
  my @table_opt = (
    q{border="0"},
    q{cellspacing="0"},
    q{cellpadding="0"}
  );
  my $img_src = '/images/ePortal/1px-trans.gif';

  if ( $ARGS{black} ) {
    $img_src = '/images/ePortal/1px-black.gif';
    $ARGS{bgcolor} = '#000000';
  }
  $ARGS{width}  ||= '100%';
  $ARGS{height} ||= 1;

  foreach (qw/ bgcolor class width /) {
    push @table_opt, qq{$_="$ARGS{$_}"} if $ARGS{$_};
  }
</%perl>
%if ($ePortal::DEBUG) {
<!-- /empty_table.mc -->\
%}
<table <% join(' ', @table_opt) %>><tr><td><img src="<% $img_src %>" height="<% $ARGS{height} %>" width="1"></td></tr></table>
