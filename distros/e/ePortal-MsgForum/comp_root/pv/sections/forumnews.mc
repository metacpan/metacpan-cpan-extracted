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
%#
%# SetupInfo:
%# Кол-во строк новостей для показа
%#
%#============================================================================
<%perl>
	my $section = $ARGS{section};

	my $counter=0;
  my ($maxrows, $forum_id) = split ':', $section->SetupInfo();
  $maxrows ||= 5;
  $forum_id ||= $section->params;

  my $app = $ePortal->Application( 'MsgForum' );
  if ( ! ref($app) ) {
    </%perl>
      <& /message.mc, ErrorMessage => pick_lang(
        rus => "Приложение MsgForum не установлено",
        eng => "MsgForum application is not installed") &>
    <%perl>
    return;
  }
  my $forum = new ePortal::App::MsgForum::MsgForum;
	if (not $forum->restore($forum_id)) {
		$m->out(pick_lang(rus => "<h2>Форум $forum_id не найден</h2>", eng => "<h2>Cannot find discussion $forum_id</h2>"));
	}

  my $messages = new ePortal::App::MsgForum::MsgItem;
  $messages->restore_where(forum_id => $forum->id,
      where => "(prev_id is null or prev_id=0)",
      order_by => "msgdate desc");
</%perl>


% while ($counter++ < $maxrows and $messages->restore_next) {
%# get only first row of body
% my $body = (split('\n',$messages->Body))[0];
% $body =~ s/[\s\.]+$//;  # remove trailing points

		<table width="100%" boder=1 cellspacing=0 cellpadding=0>
			<tr BGCOLOR="#e0e0e0">
        <td class="smallfont">
        <% $messages->picture
            ? img(src=> '/images/MsgForum/msg/'. $messages->picture . '.gif')
            : undef %>
        <b><% $messages->Title %></b></td>
				<td class="smallfont" align="right"><% $messages->short_date %></td>
			</tr>
			<tr>
        <td colspan=2 class="smallfont"><& /htmlify.mc, content => $body, 
              allowphtml=>1, allowsmiles => 1 &>...</td>
			</tr>
			<tr>
				<td align="left">
%					if ($messages->titleurl) {
						<% img( src => "/images/ePortal/item.gif" ) %>
						<% plink({rus => "Ссылка по теме", eng => "Link"}, -href => $messages->titleurl) %>
%					}
				</td>
				<td align="right">
						<% plink({rus => "Обсудить", eng => "Discuss it"}, -href => href("/forum/view_msg.htm", msg_id => $messages->id)) %>
				</td>
			</tr>
			<% empty_tr( colspan => 2, height => 6 ) %>
		</table>
% }





%#=== @METAGS Setup ====================================================
<%method Setup><%perl>
	my $section = $ARGS{section};
	if ($ARGS{save}) {
    $ARGS{maxrows} = 5 if $ARGS{maxrows} <= 0 or $ARGS{maxrows} > 20;
    $section->SetupInfo( join ':', $ARGS{maxrows}, $ARGS{forum_id} );
		$section->update;
	}

  my ($maxrows, $forum_id) = split ':', $section->SetupInfo();
</%perl>

	<p>
	<b><% pick_lang(rus => "Настройка раздела новостей", eng => "Setup") %>.</b>
	<p>

	<form action="<% $ENV{SCRIPT_NAME} %>" method="GET">
		<input type=hidden name="save" value="1">
    <input type=hidden name="us" value="<% $ARGS{us} %>">

    <%perl>
      my $F = new ePortal::App::MsgForum::MsgForum;
      my ($values, $labels) = $F->restore_all_hash();
    </%perl>

    <% pick_lang(rus => "Форум", eng => "Forum") %>
    <% CGI::popup_menu({-name => 'forum_id', -labels => $labels, -values => $values, -default => $forum_id}) %>
    <p>
    <% pick_lang(rus => "Показывать в разделе", eng => "Show ") %>
    <input type="text" name="maxrows" class="dlgfield" size="3" value="<% $maxrows %>">
		<% pick_lang(rus => "строк.", eng => "lines.") %>


		<input type="submit" name="button" class="button" value="<% pick_lang(rus => "Сохранить", eng => "Save") %>">.

	</form>
	<p>


</%method>


%#=== @metags attr =========================================================
<%attr>
def_title => { eng => "News", rus => "Новости" }
def_width => "W"
def_url => "/forum/forum.htm?forum_id=news"
def_params => "news"
</%attr>



%#=== @METAGS Help ====================================================
<%method Help>

<b>Section parameter</b>: Forum ID or nickname
</%method>

