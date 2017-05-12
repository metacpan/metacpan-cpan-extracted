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
<& /admin/statistics.htm:show_stat,
  MsgForum_count=> {
    app => 'MsgForum',
    title => pick_lang(rus => "Форумов всего", eng => "Forums count"),
    sql_1 => "SELECT count(*) FROM MsgForum",
  } &>
<& /admin/statistics.htm:show_stat,
  MsgForum_messages => {
    app => 'MsgForum',
    title => pick_lang(rus => "Сообщений в форумах", eng => "Messages at forums"),
    sql_1 => "SELECT count(*) FROM MsgItem",
    sql_2 => "SELECT MsgForum.title, count(MsgItem.id) as cnt FROM MsgForum
        left join MsgItem on MsgItem.forum_id = MsgForum.id
        group by MsgForum.title HAVING cnt > 0 ORDER BY cnt DESC",
  } &>
<& /admin/statistics.htm:show_stat,
  MsgForum_users => {
    app => 'MsgForum',
    title => pick_lang(rus => "Пишущие пользователи", eng => "Active users"),
    sql_1 => "SELECT count(distinct fromuser) FROM MsgItem",
    sql_2 => "SELECT IF(isnull(fromuser) or fromuser='','Guest', fromuser), count(id) as cnt FROM MsgItem
        group by fromuser having cnt > 0 ORDER BY cnt DESC",
  } &>

