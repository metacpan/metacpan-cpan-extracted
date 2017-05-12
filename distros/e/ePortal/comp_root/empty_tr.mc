%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software.
%#
%#----------------------------------------------------------------------------
<%perl>
  my @tr_opt = ();
  my @td_opt = ();

  my $img_src = '/images/ePortal/1px-trans.gif';
  if ( $ARGS{black} ) {
    $img_src = '/images/ePortal/1px-black.gif';
    $ARGS{bgcolor} = '#000000';
  }
  $ARGS{height} ||= 1;

  foreach (qw/ bgcolor class height /) {
    push @tr_opt, qq{$_="$ARGS{$_}"} if $ARGS{$_};
  }
  foreach (qw/ colspan height bgcolor /) {
    push @td_opt, qq{$_="$ARGS{$_}"} if $ARGS{$_};
  }
</%perl>
%if ($ePortal::DEBUG) {
<!-- /empty_tr.mc -->\
%}
<tr<% join(' ', '', @tr_opt) %>><td<% join(' ', '', @td_opt) %>><img src="<% $img_src %>" height="<% $ARGS{height} %>" width="1"></td></tr>
