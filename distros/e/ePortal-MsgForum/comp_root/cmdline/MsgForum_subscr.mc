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
<b><% pick_lang(rus => "Рассылка уведомлений о новых сообщениях на форумах",
    eng => "Sending notification about new messages on forums") %></b>
<p><blockquote>
<%perl>
  my $app = $ePortal->Application('MsgForum');
  my $messages_sent = 0;

  # Get array of MsgItem ID to notify subscribers
  my $msg = new ePortal::App::MsgForum::MsgItem;
  $msg->restore_where(where => 'email_sent is null or email_sent=0');
  push @newMsgItems, 0;    # to avoid empty array
  push @newMsgTopics, 0;    # to avoid empty array
  while($msg->restore_next) {
    # All new messages
    push @newMsgItems, $msg->id;

    # New topics
    my $topic_id = $msg->prev_id ? $msg->prev_id : $msg->id;
    push @newMsgTopics, $topic_id if ! grep {$_ == $topic_id} @newMsgTopics;
  }

  # Get subscribers
  my $subscr = new ePortal::ThePersistent::Support(
    DBISource => 'MsgForum',
    SQL => "SELECT DISTINCT username FROM MsgSubscr",
    OrderBy => "username");

  $subscr->restore_all;
  while($subscr->restore_next) {
    my $user = new ePortal::epUser;
    next if ! $user->restore($subscr->username);
    my $user_email_address = $user->email;
    if ( ! $user_email_address ) {
      $user_email_address = $user->username . '@' . $ePortal->mail_domain;
    }

    #
    # Prepare message body
    #
    $NewMessagesFound = 0;
    my $message_body = $m->scomp('SELF:message', username => $subscr->username, job => $job);

    # Send it!
    if ( $NewMessagesFound ) {
      $ARGS{job}->CurrentResult('done');
      $messages_sent ++;

      $ePortal->send_email($user_email_address,
        pick_lang(rus => "Новые сообщения на форумах", eng => "New messages of forums"),
          '<html><head><style type="text/css">
          body { font-size: x-small; font-family: MS Sans Serif;};
          table { font-size: x-small; font-family: MS Sans Serif; };
          </style></head>',
          '<body bgcolor="#ebd2a5">',
          $message_body,
          '</body></html>'
      );

      </%perl>
      <br><% $user->FullName |h %> - <% $NewMessagesFound %>
        <% pick_lang(rus => "новых сообщений на форумах", eng => "new messages on forums") %>
      <%perl>
    }
  }


  # Mark new messages as notified
  my $app_dbh = $app->dbh;
  foreach my $id (@newMsgItems) {
    $app_dbh->do("UPDATE MsgItem SET email_sent=1 WHERE id in (" . join(',', @newMsgItems) . ')');
  }

</%perl>
<p>
<% pick_lang(rus => "Всего отправлено писем: ", eng => "Total messages sent: ") %>
  <% $messages_sent %>
</blockquote>

%#=== @metags message ====================================================
<%method message><%perl>
  my $username = $ARGS{username};
  my $job = $ARGS{job};

  my $www_server = $ePortal->www_server;
  $www_server .= '/' if $www_server !~ m|/$|;     # add trailing slash

  # Get all unnotified messages for a subscriber
  my $msg = new ePortal::ThePersistent::Support(
    DBISource => 'MsgForum',
    SQL => "SELECT ms.username,
            f.id as forum_id, f.title as forum_title,
            i.id, i.prev_id, i.title, i.msgdate, i.fromuser
      FROM MsgSubscr ms
      left JOIN MsgForum f on ms.forum_id = f.id
      left JOIN MsgItem i on f.id = i.forum_id
    ",
    OrderBy => "f.title, i.msgdate",
    Where => "username=? AND i.id in (" . join(',', @newMsgTopics) . ')',
    Bind => [$username],
    );
  $msg->restore_all;

  </%perl>
  <p><% pick_lang(rus => "Новые сообщения на форумах. ", eng => "New messages on forums. ") %><%
    $job->LastRun %>
  <%perl>

  # look over all messages
  my $last_forum_id;
  while($msg->restore_next) {
    #
    # display forum title
    if ( $msg->forum_id != $last_forum_id ) {
      </%perl>
      <p>=======&nbsp;&middot;&nbsp;<% pick_lang(rus => "Форум: ", eng => "Forum: ") %><a
            href="<% $www_server %>forum/topics.htm?forum_id=<% $msg->forum_id %>"><b><%
            $msg->forum_title |h %></b></a>&nbsp;&middot;&nbsp;=======
      <%perl>
      $last_forum_id = $msg->forum_id;
    }
    $NewMessagesFound ++;

    # --------------------------------------------------------------------
    # Count new messages in topic
    my $topic_msg = new ePortal::ThePersistent::Support(
      DBISource => 'MsgForum',
      SQL => "SELECT count(*) as new_msg FROM MsgItem",
      Where => "prev_id=? AND (email_sent is null or email_sent=0)",
      Bind => [$msg->id],
      );
    $topic_msg->restore_all;
    $topic_msg->restore_next;

    </%perl>
    <blockquote>
    <% pick_lang(rus => "Дата: ", eng => "Date: ") %><b><% $msg->msgdate %></b>
    <% pick_lang(rus => "Автор темы: ", eng => "Topic author: ") %><b><% $msg->FromUser || pick_lang(rus => "Гость", eng => "Guest") %></b>
    <br><% pick_lang(rus => "Тема: ", eng => "Subject: ") %><a
      href="<% $www_server %>forum/view_msg.htm?msg_id=<% $msg->id %>"><b><% $msg->Title %></b></a>
    <% pick_lang(rus => "Новых ответов: ", eng => "New replies: ") %>
    <% $topic_msg->new_msg %>
    </blockquote>
    <%perl>

  }

  </%perl>
  <p><font color="#0d0d0d">
  <% pick_lang(rus => "Чтобы отказаться от получения уведомлений с форумов ",
    eng => "To unsubscribe from forums ") %>
  <a href="<% $www_server %>forum/subscribe.htm"><%
    pick_lang(rus => "нажмите сюда", eng => "click here") %></a>
  </font>
  <%perl>

</%perl>
</%method>


%#=== @METAGS attr =========================================================
%# This is default parameters for new CronJob object
<%attr>
Memo => {rus => "Рассылка новых сообщений с форумов подписчикам", eng => "Send new messages on forums to subscribers"}
Period => 'always'
</%attr>

%#=== @metags args =========================================================
<%args>
$job
</%args>

%#=== @METAGS once =========================================================
<%once>
my @newMsgItems = ();
my @newMsgTopics = ();
my $NewMessagesFound;
</%once>
