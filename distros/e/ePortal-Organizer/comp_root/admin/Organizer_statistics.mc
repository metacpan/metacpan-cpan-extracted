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
  Organizer_count => {
    app => 'Organizer',
    title => pick_lang(rus => "Органайзеров всего", eng => "Organizers count"),
    sql_1 => "SELECT count(*) FROM Organizer",
    sql_2 => "SELECT uid, count(Organizer.id) as cnt FROM Organizer
        group by uid having cnt>0 ORDER BY cnt DESC",
  } &>
<& /admin/statistics.htm:show_stat,
  Organizer_notepad_count => {
    app => 'Organizer',
    title => pick_lang(rus => "Всего заметок", eng => "Notepad memos count"),
    sql_1 => "SELECT count(*) FROM Notepad",
    sql_2 => "SELECT uid, count(Notepad.id) as cnt FROM Organizer
        left join Notepad on Notepad.org_id = Organizer.id
        group by uid having cnt>0 ORDER BY cnt DESC",
  } &>
<& /admin/statistics.htm:show_stat,
  Organizer_contact_count => {
    app => 'Organizer',
    title => pick_lang(rus => "Всего контактов", eng => "Contacts count"),
    sql_1 => "SELECT count(*) FROM Contact",
    sql_2 => "SELECT uid, count(Contact.id) as cnt FROM Organizer
        left join Contact on Contact.org_id = Organizer.id
        group by uid having cnt>0 ORDER BY cnt DESC",
  } &>
<& /admin/statistics.htm:show_stat,
  Organizer_calendar_count => {
    app => 'Organizer',
    title => pick_lang(rus => "Всего дел в ежедневнике", eng => "Dairy entries count"),
    sql_1 => "SELECT count(*) FROM Calendar",
    sql_2 => "SELECT uid, count(Calendar.id) as cnt FROM Organizer
        left join Calendar on Calendar.org_id = Organizer.id
        group by uid having cnt>0 ORDER BY cnt DESC",
  } &>
<& /admin/statistics.htm:show_stat,
  Organizer_todo_count => {
    app => 'Organizer',
    title => pick_lang(rus => "Всего дел", eng => "To do count"),
    sql_1 => "SELECT count(*) FROM ToDo",
    sql_2 => "SELECT uid, count(ToDo.id) as cnt FROM Organizer
        left join ToDo on ToDo.org_id = Organizer.id
        group by uid having cnt>0 ORDER BY cnt DESC",
  } &>
<& /admin/statistics.htm:show_stat,
  Organizer_anniversary_count => {
    app => 'Organizer',
    title => pick_lang(rus => "Всего годовщин", eng => "Anniversaries count"),
    sql_1 => "SELECT count(*) FROM Anniversary",
    sql_2 => "SELECT uid, count(Anniversary.id) as cnt FROM Organizer
        left join Anniversary on Anniversary.org_id = Organizer.id
        group by uid HAVING cnt > 0 ORDER BY cnt DESC",
  } &>



