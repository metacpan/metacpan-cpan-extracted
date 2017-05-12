%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2003 Sergey Rusakov.  All rights reserved.
%# This program is free software; you can redistribute it
%# and/or modify it under the same terms as Perl itself.
%#
%#
%#----------------------------------------------------------------------------
% if ($m->request_comp->attr('Layout') eq 'Normal') {
  <& navigator.mc &>
% }
<% $m->call_next %>

%#=== @metags attr =========================================================
<%attr>
Title => "Squid accounting application"
</%attr>

%#=== @METAGS onStartRequest ====================================================
<%method onStartRequest><%perl>
  my $app = $ePortal->Application('SquidAcnt');

  my $list_action = $m->comp('/list.mc:list_action', id => 'Ld');
  if ( $list_action eq 'delete' ) {
    foreach ( $m->comp('/list.mc:checkboxes', id => 'Ld') ) {
      $app->dbh->do("DELETE FROM SAtraf where domain=?", undef, $_);
    }  

  } elsif ($list_action =~ /^\d+$/) {
    my @domains = $m->comp('/list.mc:checkboxes', id => 'Ld');

    my $group = new ePortal::App::SquidAcnt::SAurl_group;
    my $url = new ePortal::App::SquidAcnt::SAurl;

    if ( $group->restore($list_action )) {
      foreach my $dom (@domains) {
        $url->restore_where(Title => $dom);
        if ( $url->restore_next ) {
          $session{ErrorMessage} .= pick_lang(rus => "$dom уже включен в группу блокировок ", eng => "$dom already exists in blocking group") . <br>;
        } else {
          $url->clear;
          $url->Title( $dom);
          $url->url_type('domain_string');
          $url->url_group_id( $group->id );
          $url->insert;
          $session{GoodMessage} .= pick_lang(rus => "Домен $dom добавлен в группу ", eng => "Domain $dom added to group ") . $group->Title . <br>;
        }
      }
    }

  }  
</%perl></%method>



%#=== @METAGS domain_operations ====================================================
<%method domain_operations><%perl>
  # list.mc:action_bar parameters hash for
  # operations with domains
  # 
  my ($bg_values, $bg_labels);
  my $dummy = new ePortal::App::SquidAcnt::SAurl_group;
  ($bg_values, $bg_labels) = $dummy->restore_all_hash;
  foreach (@{$bg_values}) {
    $bg_labels->{$_} = substr($bg_labels->{$_}, 0, 15) . '...' if length($bg_labels->{$_}) > 15;
    $bg_labels->{$_} = '+ ' . $bg_labels->{$_};
  }
  unshift @{$bg_values}, 'delete';
  $bg_labels->{delete} = pick_lang(rus => "- Удалить", eng => "- Delete");
  return ($bg_values, $bg_labels);
</%perl></%method>
