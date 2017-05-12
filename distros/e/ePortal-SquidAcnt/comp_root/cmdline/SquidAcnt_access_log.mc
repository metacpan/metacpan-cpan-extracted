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
<%perl>

</%perl>
<p>
<& SELF:parse_squid_log, %ARGS &>
<p>
<& SELF:expire_SAtraf, %ARGS &>
<p>

%#=== @METAGS parse_squid_log ====================================================
<%method parse_squid_log><%perl>
  my $app = $ePortal->Application('SquidAcnt');
  my $lines_in_total = 0;
  my $lines_in_processed = 0;

  # ----------------------------------------------------------------------
  # read access.log two times.
  # 1. attempt to find a point when we last time finished
  # 2. read all lines from very begin
  PASS: foreach my $pass (1..2) {
    $lines_in_total = 0;
    $lines_in_processed = 0;

    # --------------------------------------------------------------------
    # where we stopped last time?
    my $last_access_time_found = undef;
    my $last_access_time = $app->Config('last_access_time');
    my ($access_time, $dummy);
    next PASS if $pass==1 and ! $last_access_time;

    # ----------------------------------------------------------------------
    # open access.log
    my $fh_access_log = new IO::File( $app->access_log );
    throw ePortal::Exception::FileNotFound(-file => $app->access_log)
      if ! $fh_access_log;

    # ----------------------------------------------------------------------
    # read access.log
    while(my $line = <$fh_access_log>) {
      chomp $line;
      $lines_in_total ++;
      ($access_time, $dummy) = split('\s+', $line, 2);  # extract time part

      if ( $pass == 2 or $last_access_time_found ) {  # Process line
        my $result = $app->ProcessAccessLogLine($line);
        $app->Config('last_access_time', $access_time)
          if $lines_in_processed % 10 == 0;
        $lines_in_processed++;

      } elsif ($pass == 1) {        # Skip line. Looking for last stop point
        $last_access_time_found = 1  if $access_time eq $last_access_time;
      }

    }
    $fh_access_log->close;
    $app->Config('last_access_time', $access_time) if $access_time;

    # Do not go second pass if the data is Ok
    last PASS if $last_access_time_found;
  }

  if ( keys %{ $app->{users_not_found} } ) {
    $ARGS{job}->CurrentResult('failed');
  } elsif ( $app->{processed_lines} ) {
    $ARGS{job}->CurrentResult('done');
  }

</%perl>
<p><blockquote>
  <br>Lines read total: <% $lines_in_total %>
  <br>Lines processed: <% $lines_in_processed %>
  <p>Addresses not found in users database:
  <blockquote>
    <% join "\n<br>", keys %{$app->{users_not_found}} %>
  </blockquote>
  <br>local_domain_lines: <% $app->{local_domain_lines} %>
  <br>hit_lines: <% $app->{hit_lines} %>
  <br>ignored_lines: <% $app->{ignored_lines} %>
</blockquote>
</%method>


%#=== @metags expire_SAtraf ====================================================
<%method expire_SAtraf><%perl>
  my $app = $ePortal->Application('SquidAcnt');
  my $count = 0+ $app->dbh->do('DELETE FROM SAtraf WHERE log_date < date_format(subdate(curdate(), interval 2 month), "%Y-%m-01")');
  $ARGS{job}->CurrentResult('done') if $count > 0;
</%perl>
% if ($count) {
  <blockquote>
    Old records expired: <% $count %>
  </blockquote>
% }
</%method>


%#=== @METAGS attr =========================================================
%# This is default parameters for new CronJob object
<%attr>
Memo => {rus => "SquidAcnt: Обработка файла access.log", eng => "SquidAcnt: Processing access.log"}
Period => '5'
</%attr>

%#=== @metags args =========================================================
<%args>
$job
</%args>
