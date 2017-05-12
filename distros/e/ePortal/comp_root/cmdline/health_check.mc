%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software
%#
%#
%#----------------------------------------------------------------------------
<p>
<& SELF:expire_sessions, %ARGS &>
<p>
<& SELF:compress_statistics, %ARGS &>
<p>
% if ($m->comp_exists('/app/OffPhones/health_check.mc')) {
  <& /app/OffPhones/health_check.mc, %ARGS &>
% }

%#=== @metags expire_sessions ====================================================
<%method expire_sessions>
<b><% pick_lang(rus => "Удаление просроченных сессий", eng => "Expire old sessions") %></b>
<p><blockquote>
<%perl>
  if ($ePortal->days_keep_sessions == 0) {
    </%perl>
    Session expiration is disabled.
    <%perl>

  } else {
      my $cnt = 0 + $ePortal->dbh->do("DELETE
              FROM sessions
              WHERE ts < date_sub(now(), interval ? day)",
              undef, $ePortal->days_keep_sessions);
      $ARGS{job}->CurrentResult('done') if $cnt;
      </%perl>
      Old sessions exiped: <% $cnt %>
      <%perl>
  }
</%perl>
</blockquote>
</%method>

%#=== @metags compress_statistics ====================================================
<%method compress_statistics>
<b><% pick_lang(
      rus => "Обработка и сжатие статистики Каталога",
      eng => "Compressing Catalogue statistics") %></b>
<p><blockquote>
<%perl>
  my $ep_dbh = $ePortal->dbh;
  COMPRESS_STATISTICS: {
      # calculate first of month $MAX_MONTH_SHOW ago
      my $first_of_month = $ep_dbh->selectrow_array(
              "SELECT date_format(
              date_sub(curdate(), interval $ePortal::Catalog::MAX_MONTH_SHOW month),
              '%Y.%m.01')");
      if ($first_of_month !~ /\d\d\d\d\.\d\d\.\d\d/) {
        </%perl>
        <font color="red">
        <p>Compress statistics: expected date but got <% $first_of_month %>
        <br>
        <% $DBI::errstr |h %>
        <%perl>
        $ARGS{job}->CurrentResult('failed');
        last COMPRESS_STATISTICS;
      }

      # remove statistics that is older than $first_of_month
      my $records_removed = 0+$ep_dbh->do("DELETE from Statistics WHERE date < ?", undef, $first_of_month);

      # GROUP BY all statistics that is older then MAX_DATES_SHOW days
      # and add it to the first day of month
      my $st = new ePortal::ThePersistent::Support(
          SQL => "SELECT catalog_id, visitor, date, hits,
                      date_format(date, '%Y.%m.01') as first_of_month
                  FROM Statistics",
          Where => "dayofmonth(date) != 1 AND date < date_sub(current_date(), interval ? day)",
          Bind => [$ePortal::Catalog::MAX_DATES_SHOW],
          Attributes => { date => {dtype => 'Varchar'} }, # This will return Date in MySQL ready format
          );

      my $records_coalesced = 0;
      $st->restore_all();
      while($st->restore_next) {
          $records_coalesced ++;

          # Is there a records for 1st of month?
          my $check_first = $ep_dbh->selectrow_array("SELECT ts FROM Statistics
                  WHERE catalog_id=? AND visitor=? AND date=?", undef,
                  $st->catalog_id, $st->visitor, $st->first_of_month);

          if ($check_first ne '') {   # record exists, use UPDATE
              $ep_dbh->do("UPDATE Statistics SET hits = hits + ?
                      WHERE catalog_id=? AND visitor=? AND date=?", undef,
                      $st->hits, $st->catalog_id, $st->visitor, $st->first_of_month);
          } else {    # no such record, use INSERT
              $ep_dbh->do("INSERT INTO Statistics (catalog_id, visitor, date, hits)
                      VALUES(?,?,?,?)", undef,
                      $st->catalog_id, $st->visitor, $st->first_of_month, $st->hits);
          }

          #remove old record
          $ep_dbh->do("DELETE FROM Statistics
                  WHERE catalog_id=? AND visitor=? AND date=?", undef,
                  $st->catalog_id, $st->visitor, $st->date);
      }

      if ( $records_removed or $records_coalesced ) {
        $ARGS{job}->CurrentResult('done');
      }
      </%perl>
        <p>Old Records removed: <% $records_removed %>
        <p>Records coalesced: <% $records_coalesced %>
      <%perl>
  }##//COMPRESS_STATISTICS

</%perl>
</blockquote>
</%method>


%#=== @METAGS attr =========================================================
%# This is default parameters for new CronJob object
<%attr>
Memo => {rus => "Проверка структуры данных ePortal", eng => "Health checking job"}
Period => 'daily'
</%attr>

%#=== @metags args =========================================================
<%args>
$job
</%args>
