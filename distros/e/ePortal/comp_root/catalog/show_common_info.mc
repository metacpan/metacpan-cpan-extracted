%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software.
%#
%#----------------------------------------------------------------------------
<%init>
  if ( $ePortal::DEBUG ) {
    %ARGS = Params::Validate::validate(@_, {
      catalog      => { type => OBJECT },
      show_caption => {type => SCALAR, default => 1},
    });
  }
  my $catalog = $ARGS{catalog};
  $ARGS{show_caption} = 1 if ! exists $ARGS{show_caption};

  my $extra_text;
  if ( $catalog->show_info == 0 and ! $catalog->xacl_check_update ) {
    return;

  } elsif ( $catalog->show_info == 0 ) {
    $extra_text = pick_lang(
        rus => "Этот раздел невидим для обычных пользователей",
        eng => "This section is hidden for users");
  }

  my $subitems;
  if ( $catalog->RecordType eq 'composite' ) {
    $subitems = $catalog->dbh->selectrow_array(
      "SELECT count(*) from CtlgItem WHERE parent_id=?",
      undef, $catalog->id);
  }
</%init>
<p>
% if ($ARGS{show_caption}) {
  <& /item_caption.mc,
      extra => $extra_text,
      title => pick_lang(rus => "Общая информация о ресурсе", eng => "Information about resource") &>
% }

<p style="margin-left: 1cm;">
<b><% pick_lang(rus => "Название", eng => "Name") %></b>: <% $catalog->Title %>
<br><b><% pick_lang(rus => "Автор", eng => "Author") %></b>: <& /fio.mc, username => $catalog->uid &>
<br><b><% pick_lang(rus => "Дата создания", eng => "Created") %></b>: <% $catalog->firstcreated %>
<br><b><% pick_lang(rus => "Автор посл.изменения", eng => "Last editor") %></b>: <& /fio.mc, username => $catalog->lastmodifieduid &>
<br><b><% pick_lang(rus => "Дата посл.изменения", eng => "Last edited") %></b>: <% $catalog->lastmodified || $catalog->ts %>
% if ( $catalog->RecordType eq 'composite' ) {
<br><b><% pick_lang(rus => "Статей в ресурсе", eng => "Number of articles") %></b>: <% $subitems %>
%}
</p>
