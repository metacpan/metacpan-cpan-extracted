%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software.
%#
%#----------------------------------------------------------------------------
<%perl>
  return if exists $ARGS{skip_if} and $ARGS{skip_if};

  my @td_opt = ();

  my $img_src = '/images/ePortal/1px-trans.gif';
  if ( $ARGS{black} ) {
    $img_src = '/images/ePortal/1px-black.gif';
    $ARGS{bgcolor} = '#000000';
  }
  $ARGS{height} ||= 1;
  $ARGS{width}  ||= 1;

  foreach (qw/ bgcolor colspan width height class /) {
    push @td_opt, qq{$_="$ARGS{$_}"} if $ARGS{$_};
  }
</%perl>
%if ($ePortal::DEBUG) {
<!-- /empty_td.mc -->\
%}
<td<% join(' ', '', @td_opt) %>><img src="<% $img_src %>" height="<% $ARGS{height} %>" width="<% $ARGS{width} %>"></td>
