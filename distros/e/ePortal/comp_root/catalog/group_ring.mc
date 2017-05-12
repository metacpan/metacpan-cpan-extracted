%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software
%#
%# Parameters:
%#  group - starting group ID
%#
%#----------------------------------------------------------------------------
<%perl>
  my $current_group = $ARGS{group};
  my $HTML;
  my $G = new ePortal::Catalog;
  my $group_memo = undef;
  my @ring = ();

  while( $current_group and $G->restore($current_group) ) {
    if ( $current_group == $ARGS{group} ) { # First group object. Last (rightmost) item in the ring
      unshift @ring, { title => $G->Title, href => "/catalog/" . $G->id . '/' };
      $group_memo = $G->Memo;

    } else {                                # second or more item
      unshift @ring, { title => $G->Title, href => "/catalog/" . $G->id . '/' };
    }

    last if $current_group == $G->parent_id;
    $current_group = $G->parent_id;
  }

  if ($ARGS{group}) {  # if some subgroups present
    unshift @ring, { title => pick_lang(rus => "Начало каталога", eng => "Top of Catalogue"), href => "/catalog/index.htm" };
  } else {
    unshift @ring, { title => pick_lang(rus => "Разделы каталога",eng => "Catalog groups") };
  }

  # output HTML
</%perl>
<& /navigatorbar.mc, items => \@ring, bold_last => 1 &>
% if ($group_memo) {
  <& /htmlify.mc, content => $group_memo, class => 'memo' &>
% }
