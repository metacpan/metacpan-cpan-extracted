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
<ul>
<%perl>
  # ----------------------------------------------------------------------
  # Global variables
  #
  my $app = $ePortal->Application('SquidAcnt');
  my $www_server = $ePortal->www_server;
  $www_server .= '/' if $www_server !~ m|/$|;     # add trailing slash

  my $total_alerts_sent = 0;


  # List of alerts sent
  my %alerts_sent = %{ $app->Config('alerts_sent') || {} };

  # Get user statistics
  my $u = $app->SAuser_extended;
  $u->restore_all;
  while($u->restore_next) {
    # --------------------------------------------------------------------
    # check daily_limit
    #
    if ( $u->daily_traf > $u->daily_alert and $u->daily_alert > 0) {
      if ( ! $alerts_sent{$u->id} ) {
        $m->comp('SELF:user_info', user=>$u, info => pick_lang(
              rus => "Превышено пороговое значение дневного трафика",
              eng => "Daily traffic threshold exceed"));

        $alerts_sent{$u->id} = 1;
        $total_alerts_sent ++;
      }
    } else {
      delete $alerts_sent{$u->id};
    }

    # --------------------------------------------------------------------
    # check traffic overdraft
    #
    my $user = new ePortal::App::SquidAcnt::SAuser;
    $user->restore_or_throw($u->id);
    my $block_this_user = 0;

    $block_this_user = 1 if $u->daily_traf  >= $u->daily_limit;
    $block_this_user = 0 if $u->daily_limit == 0;
    $block_this_user = 1 if $u->weekly_traf >= $u->weekly_limit;
    $block_this_user = 0 if $u->weekly_limit == 0;
    $block_this_user = 1 if $u->mon_traf    >= $u->mon_limit;
    $block_this_user = 0 if $u->mon_limit == 0;
    $block_this_user = 1 if $u->account_expired;

    if ( $block_this_user ) {
      if ( ! $u->blocked ) {     # block the user
        $user->blocked(1);
        $user->update;
        $total_alerts_sent ++;
        $m->comp('SELF:user_info', user=>$u, info => pick_lang(
              rus => "Превышен лимит трафика либо срок действия. Пользователь блокирован",
              eng => "Daily traffic limit exceed or account expired. User blocked."));
      }
    } else {  # release block
      if ( $u->blocked ) {
        $user->blocked(0);
        $user->update;
        $total_alerts_sent ++;
        $m->comp('SELF:user_info', user=>$u, info => pick_lang(
              rus => "Снята блокировка с пользователя",
              eng => "User block released"));
      }
    }

  }   # while $u->restore_next

  # save information about sent alerts
  $app->Config('alerts_sent', \%alerts_sent);

  if ( $total_alerts_sent ) {
    $ARGS{job}->CurrentResult('done');
  } else {
    $ARGS{job}->CurrentResult('no_work');
  }

</%perl>
</ul>


%#=== @METAGS user_info ====================================================
<%method user_info><%perl>
  my $user = $ARGS{user};
  my $info = $ARGS{info};

  my $www_server = $ePortal->www_server;
  $www_server =~ s|/$||;            # remove trailing slash
</%perl>
  <li>
  <a href="<% href("$www_server/app/SquidAcnt/user_info.htm", user_id => $user->id) %>">
  <% $user->Title |h %>
  </a> - <% $info %>
</%method>

%#=== @METAGS attr =========================================================
%# This is default parameters for new CronJob object
<%attr>
Memo => {rus => "SquidAcnt: Контроль превышения лимитов", eng => "SquidAcnt: Limits control job"}
Period => '5'
</%attr>

%#=== @metags args =========================================================
<%args>
$job
</%args>
