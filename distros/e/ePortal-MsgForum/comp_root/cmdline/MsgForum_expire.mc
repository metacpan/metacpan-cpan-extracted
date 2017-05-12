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
<p>
<& SELF:expire_messages, %ARGS &>
<p>
<& SELF:clean_lost_messages, %ARGS &>
<p>

%#=== @metags expire_messages ====================================================
<%method expire_messages>
<b><% pick_lang(rus => "Удаление старых сообщений с форумов", eng => "Expire messages on forums") %></b>
<p><blockquote>
  <table border="1" width="90%">
    <tr>
      <th><% pick_lang(rus => "Форум", eng => "Forum") %>
      <th><% pick_lang(rus => "Сообщений/Тем", eng => "Messages/Topics") %>
      <th><% pick_lang(rus => "Удалено", eng => "Expired") %>
    </tr>
<%perl>
  my $app = $ePortal->Application('MsgForum');
  my $F = new ePortal::App::MsgForum::MsgForum;
  $F->restore_all;
  while($F->restore_next) {
    </%perl>
    <tr>
      <td><b><% $F->Title |h %></b></td>
      <td align="center"><% $F->messages %>/<% $F->topics %></td>
    <%perl>
    my $removed_messages = 0;
    if ($F->keepdays == 0) {
      </%perl>
      <td align="center">
      <% pick_lang(rus => "Удаление отключено", eng => "Expiration disabled") %>
      </td></tr>
      <%perl>
      next;
    }

    # restore old topics
    my $topic = new ePortal::App::MsgForum::MsgItem();
    $topic->restore_where(
            forum_id => $F->id,
            where => "(prev_id is null or prev_id=0) AND
            (msgdate <= date_sub(now(), interval ? day))",
            bind => [$F->keepdays],
            order_by => 'msgdate');
    while($topic->restore_next) {
        # count fresh replies
        my $replies = new ePortal::App::MsgForum::MsgItem;
        my $res = $replies->restore_where(
                count_rows => 1,
                prev_id => $topic->id,
                where => "(msgdate > date_sub(now(), interval ? day))",
                bind => [$F->keepdays]);

        if ($res == 0) {
            $removed_messages += $topic->delete;
            $ARGS{job}->CurrentResult('done');
        }
    }

    </%perl>
    <td align="center"><% $removed_messages %></td>
    </tr>
    <%perl>
  }
</%perl>
</table>
</blockquote>
</%method>

%#== @metags clean_lost_messages ====================================================
<%method clean_lost_messages>
<b><% pick_lang(rus => "Удаление сообщений с несуществующих форумов", eng => "Clean lost in space messages") %></b>
<%perl>
  my $F = new ePortal::App::MsgForum::MsgForum;
  my @forums = (0, @{$F->restore_all_array('id')});
  my $result = 0+ $F->dbh->do("DELETE FROM MsgItem WHERE forum_id not in (" .
    join(',', @forums) . ')');
  $ARGS{job}->CurrentResult('done') if $result;

</%perl>
<p><blockquote>
  <% pick_lang(rus => "Удалено сообщений: ", eng => "Messages deleted: ") %>
  <% $result %>
</blockquote>
</%method>

%#=== @METAGS attr =========================================================
%# This is default parameters for new CronJob object
<%attr>
Memo => {rus => "Удаление старых сообщений с форумов", eng => "Delete old messages from Forums"}
Period => 'daily'
</%attr>

%#=== @metags args =========================================================
<%args>
$job
</%args>
