%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software
%#
%#
%#----------------------------------------------------------------------------
<!-- mostpopular -->
<%perl>
my $config = $m->comp('SELF:config_object');
my $d = new ePortal::HTML::Dialog(
              title => pick_lang(
                rus => "Популярные ресурсы",
                eng => "Most popular"),
              formname => '',
              width => $config->ctlg_mp_width,
              edit_button => $ePortal->isAdmin ? '/catalog/mostpopular_edit.htm' : undef,
  );
</%perl>

<% $d->dialog_start %>
<% $d->row( $m->scomp('SELF:drawLinks', count => $config->ctlg_mp_count)) %>
<% $d->row(
    '<span class="memo">'.
    pick_lang(
      rus => "В скобках указано кол-во обращений к ресурсу",
      eng => "Click count is in brackets").
    '</span>',
  -align => "left") %>
<% $d->dialog_end %>





%#=== @metags drawLinks ====================================================
<%method drawLinks>
<table border=0 width="100%">
<%perl>
  my $links_count = 0;
  my $catalog = new ePortal::Catalog;
  $catalog->restore_where(
                          recordtype => "link",
                          order_by => "clicks DESC",
                          skip_attributes => [qw/text/],
                          limit_rows => $ARGS{count});
  while($catalog->restore_next) {
    $links_count ++;
    $m->comp("SELF:drawLink", link => $catalog);
  }
  undef $catalog;
</%perl>
</table>

% if ($links_count == 0) {
  <div style="font-size: 8pt; color:red; text-indent: 20px;">
  <% img(src=> "/images/ePortal/item.gif") %>
  <% pick_lang(
      rus => "Нет ни одного ресурса в этом разделе.",
      eng => 'There is no resources in this group.' ) %>
  </div>
% }
</%method>





%#=== @metags drawLink ====================================================
<%method drawLink><%perl>
my $link = $ARGS{link};
return if $link->Clicks == 0;

my $parent = $link->parent;
my $razdel;
$razdel = pick_lang(rus => "Раздел:", eng => "Section:") . $parent->Title . "\n"
  if $parent;

</%perl>
<tr><td width=12>
<% img(src=> "/images/ePortal/item.gif") %>
</td><td>
  <a class="smallbold"
  title="<% $razdel . $link->Memo |h%>"
  href="/catalog/<% $link->id %>/">
  <% $link->Title %></a>&nbsp;<span class="memo">(<% $link->Clicks %>)</span>
</td></tr>
</%method>




%#=== @metags config_object ====================================================
<%method config_object><%perl>
  my $config = new ePortal::ThePersistent::UserConfig;
  $config->add_attribute(ctlg_mp_count => {
                      # Number of links to show in most popular
                      dtype => 'Number',
                      label => {rus => 'Кол-во ссылок для показа', eng => 'Number of links to show'}});

  $config->add_attribute(ctlg_mp_width => {
                      # Width of the dialog
                      dtype => 'Number',
                      label => {rus => 'Ширина окна,пикс.', eng => 'Width of the window,px'}});
  $config->restore;
  if ( $config->ctlg_mp_count < 5 ) {
    $config->ctlg_mp_count(10);
    $config->update;
  }
  if ($config->ctlg_mp_width < 50) {
    $config->ctlg_mp_width(200);
    $config->update;
  }
  return $config;
</%perl></%method>
