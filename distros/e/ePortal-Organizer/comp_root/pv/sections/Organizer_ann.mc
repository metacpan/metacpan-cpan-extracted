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
%# Today's calendar section
%#-----------------------------------------------------------------------------
<%perl>
  my $app = $ePortal->Application('Organizer');

  my $section = $ARGS{section};
  my $org_id = $section->SetupInfo;
  if ( $org_id eq '' ) {    # Private Org
    if (! $ePortal->username) {
        $m->comp("/pv/sections/Organizer_ann.mc:user_not_registered");
        return;
    }
    $org_id = try {$app->DefaultPrivateOrganizerID} otherwise {undef;};
  }

  my $ann = new ePortal::App::Organizer::Anniversary;
     $ann->restore_where(org_id => $org_id, where => "an_month=month(curdate()) AND an_day=dayofmonth(curdate())",
      order_by => "category_id,title");
</%perl>

<table width="100%" border="0" cellspacing=0 cellpadding=0>
  <%perl>
  my $last_category_id;
  my $counter;
  my $C = new ePortal::App::Organizer::Category;
  while($ann->restore_next) {
    if ( $ann->category_id != 0 and $ann->category_id != $last_category_id ) {
      $C->restore($ann->category_id);
      $last_category_id = $C->id;
      </%perl>
      <tr><td class="smallfont">
        <b><% $C->Title %></b>
      </td></tr>
      <%perl>
    }
    my $bgcolor = $counter++ % 2 == 0? '#FFFFFF' : '#eeeeee';
    </%perl>

    <tr><td bgcolor="<% $bgcolor %>" class="smallfont">
    &nbsp;<% substr($ann->title, 0, 40) %>...
    </td></tr>
% }

</table>

%   if (! $counter) {
    <& /pv/sections/Organizer_ann.mc:no_tasks &>
% }

<div align="right">
  <% plink({rus => "Дальше...", eng => "More..."}, -href => href('/Organizer/ann_list.htm', org_id => $org_id)) %>
</div>

%#=== @METAGS user_not_registered ====================================================
<%method user_not_registered>
<span class="smallfont">
Этот раздел имеет смысл только для <a href="/login.htm" target="_top">зарегистрированных</a> пользователей
<br>
You are not <a href="/login.htm" target="_top">registered</a> user.
</span>
</%method>


%#=== @METAGS no_tasks ====================================================
<%method no_tasks>
<span class="smallfont">
<% pick_lang(rus => "Сегодня событий не предвидится...", eng => "No anniversaries today...") %>
</span>
</%method>

%#=== @metags attr =========================================================
<%attr>
def_title => {eng => "Anniversaries today", rus => "События сегодня"}
def_params => ""
def_url => "/Organizer/ann_list.htm"
def_width => 'N',
</%attr>


%#=== @METAGS Setup ====================================================
<%method Setup><%perl>
  my $section = $ARGS{section};
  my %args = $m->request_args;
  my ($selected_type, $selected_org);

  if ( $args{save} ) {
    if ( $args{org_type} eq 'private' ) {
      $section->SetupInfo(undef);
    } else {
      $section->SetupInfo($args{org_id});
    }
    $section->update;
  }

  if ( $section->SetupInfo eq '' ) {
    $selected_type = 'private';
  } else {
    $selected_type = 'public';
    $selected_org = $section->SetupInfo;
  }


  my $dummy = new ePortal::ThePersistent::Dual(
  Attributes => {
        org_type => {
            label => {rus => "Вид Органайзера", eng => "Organizer type"},
            fieldtype => 'popup_menu',
            values => ['private', 'public'],
            default => $selected_type,
            labels => {
              private => pick_lang(rus => "Личный для пользователя", eng => "Private organizer"),
              public => pick_lang(rus => "Общий. Из списка", eng => "Public. Choose one"),
            },
        },
        org_id => {
            label => {rus => "Общий Органайзер", eng => "Public Organizer"},
            dtype => 'Number',
            fieldtype => 'popup_menu',
            default => $selected_org,
            popup_menu => sub {
                my $self = shift;
                my $m = $ePortal->Application('Organizer')->stOrganizers();
                return $m->restore_all_hash();
            }
        },
  });

  $dummy->value('org_type', $selected_type);
  $dummy->value('org_id', $selected_org);
  my $dlg = new ePortal::HTML::Dialog( obj => $dummy, width => '300',
    title => pick_lang(rus => "Настройка секции", eng => "Section setup")
  );

</%perl>
  <% $dlg->dialog_start %>
  <input type=hidden name="save" value="1">
  <input type=hidden name="us" value="<% $ARGS{us} %>">
  <% $dlg->field('org_type') %>
  <% $dlg->field('org_id') %>
  <% $dlg->row('&nbsp;')  %>
  <% $dlg->buttons (cancel_button => 0) %>
  <% $dlg->dialog_end %>
</%method>
