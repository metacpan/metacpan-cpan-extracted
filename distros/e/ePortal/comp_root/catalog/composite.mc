%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software.
%#
%#----------------------------------------------------------------------------
%#=== @METAGS shared =========================================================
<%once>
  my ($catid, $catitemid, $filename, $items_shown);
  my ($catalog, $calendar, $item);
</%once>
<%cleanup>
  ($catalog,$item,$calendar)=undef;
</%cleanup>

<%init>
  my %args = $m->request_args;
  my $current_date = sprintf("%04d-%02d-%02d", $calendar->date);

  my $catid1 = $args{catid1};
  $items_shown=0;
</%init>
<table align="right"><tr><td>
  <& /catalog/admin.mc,
      item_date => scalar $calendar->date,
      catalog => $catalog,
      item => $item &>
  <% $calendar->draw %>
  <& SELF:show_next_prev_link, current_date => $current_date &>
</table>

%#===========================================================================
%# Show the text
% if ($item->check_id) {
  <h2>
  <% $item->Title |h %>
  </h2>
  <& /catalog/show_text.mc,
            catalog => $catalog, item => $item,
            textType => $catalog->textType &>
  <br clear="all">
  <& /catalog/show_attachments.mc, catalog => $catalog, item => $item &>

%#============================================================================
%# Show groupping
% } else {

<div style="margin-left=10px;">
<&| SELF:show_category, current_date => $current_date,
                      $catid1 ? (catid => $catid1) : (),
                      level => 1 &>
  <%perl>
  # Increment counter
  $items_shown += 0+$catalog->dbh->selectrow_array(
    "SELECT count(*) from CtlgItem WHERE parent_id=? AND item_date=? AND category1=?", undef,
      $catalog->id, $current_date, $_->id);
  </%perl>

  <&| SELF:div_right &>
    <& SELF:show_items, current_date => $current_date,
          catid1 => $_->id &>
  </&>
</&>

<& /empty_table.mc, height => 10, width=> 100 &>

% if ($items_shown > 0) {
<& SELF:show_category_name &>
%}
  <&| SELF:div_right &>
    <& SELF:show_items, current_date => $current_date,
            rows => 50,
            catid1 => undef &>
  </&>
  <%perl>
  # Increment counter
  $items_shown += 0+$catalog->dbh->selectrow_array(
    "SELECT count(*) from CtlgItem WHERE parent_id=? AND item_date=? AND category1 is null", undef,
      $catalog->id, $current_date);
  </%perl>


% if ($items_shown == 0) {
  <div style="color:red; text-align:center;">
  <% sprintf(pick_lang(
        rus => "За %s нет ни одной статьи",
        eng => "No articles ofr %s"), scalar $calendar->date) %>
  </div>
% }

% } # if ($item->check_id)
</div>


%#=== @METAGS onStartRequest ====================================================
%# this method is called from /catalog/dhandler.mc:onStartRequest
<%method onStartRequest><%perl>

  # this object is passed from dhandler.mc
  $catalog = $ARGS{catalog};

  # Parse request arguments
  my $dh_args = $m->dhandler_arg;
  ($catid, $catitemid, $filename) = split('/', $dh_args);

  # A request to /catalog/num should be rewrited to /catalog/num/
  # It is possible to /catalog/num/?pageL=1&rowsL=10
  my $req_path = $ENV{SCRIPT_NAME} . $ENV{PATH_INFO};
  if ( $catitemid ne '' and $filename eq '' and $req_path !~ m|/$|o ) {
    throw ePortal::Exception::Abort(-text => $catid . '/' . $catitemid . '/');
  }

  # Prepare Calendar object
  $calendar = new ePortal::HTML::Calendar(m => $m, self_url => '/catalog/' . $catalog->id . '/');
  $m->comp('SELF:fill_calendar_dates');

  # Prepare Item object
  $item = new ePortal::CtlgItem;
  if ( $catitemid ) {
    $item->restore_or_throw($catitemid);
    $calendar->set_date($item->item_date);
  }

  # Download a file as attachment of CtlgItem
  if ( $filename ne '' ) {
    my $att = new ePortal::Attachment;
    $att->restore_where(obj => $item, filename => $filename);
    throw ePortal::Exception::FileNotFound(-file => '/catalog/' . $m->dhandler_arg)
      if ( ! $att->restore_next );

    $m->comp('/download.mc', att => $att, download => $ARGS{todisk});
  }

  # jump to last day with resources
  if ( $calendar->date_source eq 'self' ) {
    my $max_date = new ePortal::ThePersistent::Support(
      SQL => "SELECT max(item_date) as item_date from CtlgItem",
      Where => "parent_id=?",
      Bind => [$catalog->id],
      Attributes => { item_date => {dtype => 'Date'}},
      );
    $max_date->restore_all;
    $max_date->restore_next;
    if ( $max_date->item_date ne '' ) {
      throw ePortal::Exception::Abort(-text => '/catalog/' . $catalog->id . '/?cal_date='.$max_date->item_date);
    }
  }

  $r->no_cache(1);
</%perl></%method>


%#=== @METAGS fill_calendar_dates ====================================================
<%method fill_calendar_dates><%perl>

  if ( $catalog->xacl_check_update ) { # edit mode on
    $calendar->url_all('self');
    $calendar->bold_all(0);
  } 

  # show only dates with existing items
  # first day of month
  my $date_start = sprintf "%04d-%02d-01", ($calendar->date)[0,1];
  # distinct dates with resources
  my $distinct_dates = new ePortal::ThePersistent::Support(
    SQL => "SELECT distinct item_date FROM CtlgItem
            WHERE parent_id = ?
            AND item_date >= ?
            AND item_date <= adddate(?, interval 1 month)",
    Bind => [ $catalog->id, $date_start, $date_start ],
    Attributes => { item_date => {dtype => 'Date'} },
    );

  $distinct_dates->restore_where();
  while($distinct_dates->restore_next) {
    $calendar->url($distinct_dates->attribute('item_date')->day, 'self');
    $calendar->bold($distinct_dates->attribute('item_date')->day, 'self');
  }
</%perl></%method>


%#=== @METAGS show_items ====================================================
<%method show_items><%perl>
  # catid{1,2} - restrict to category
  # Required parameter
  my $current_date = $ARGS{current_date};
  my $rows = $ARGS{rows} || 10;


  # Apply category restrictions
  my @where;
  if ( exists $ARGS{"catid1"} ) {
    if ( ! $ARGS{"catid1"} ) {
      push @where, "category1 is null";
    } else {
      push @where, "category1 = ".$ARGS{"catid1"};
    }
  }
</%perl>
<&| /list.mc, obj => new ePortal::CtlgItem(
              SQL => "SELECT id, title FROM CtlgItem",
              Where => 'parent_id=? AND item_date=?',
              Bind => [ $catalog->id, $current_date ],
            ),
    -width => '60%',
    no_title => 1,
    no_footer => 2,
    rows => $rows,
    id => 'L'.$ARGS{catid1}.$catalog->id,
    restore_where => { where => \@where, order_by => 'id' }  &>

 <&| /list.mc:row &>
  <& /list.mc:column_image &>
  <& /list.mc:column, id => 'title',
      -style => 'font-size:10pt;',
      url => escape_uri(sprintf("/catalog/%s/%s/", $catalog->id, $_->id)) &>

% if ($_->xacl_check_update) {
  <& /list.mc:column_edit, url => href('/catalog/composite_edit.htm', objid=> $_->id) &>
% }
% if ($_->xacl_check_delete) {
  <& /list.mc:column_delete, objtype => 'ePortal::CtlgItem' &>
% }

 </&>
 <& /list.mc:nodata, content => '&nbsp;' &>
</&>

%#% if ($ARGS{silent}) {
%#  <div style="color:red; text-align:center;">
%#  <% pick_lang(
%#        rus => "Не найдено ни одного элемента для показа",
%#        eng => "No data found") %>
%#  </div>
%#% }
</%method>




%#=== @metags show_category_name ====================================================
<%method show_category_name><%perl>
  my $name = $ARGS{name};
  my $items_count = $ARGS{items_count};
</%perl>
<br><% img(src => '/images/ePortal/3-r.gif') %>
<b><% $name || pick_lang(rus => "Без имени", eng => "No name")|h %></b>
%# if ($items_count) {
%#<span class="memo">[<% $items_count %>]</span>
%# }
</%method>





%#=== @metags show_category ====================================================
<%method show_category><%perl>
  # required parameter
  my $current_date = $ARGS{current_date};
  my $level = $ARGS{level} || 1;  # {1,2} of category
  # catid - show only this category
  # catid1 - show categories2 inside catid1


  my $cat = new ePortal::ThePersistent::Support(
      SQL => "SELECT i.category$level as id, c.title, count(i.id) as items
        FROM CtlgItem i
          left join CtlgCategory c on c.id = i.category$level",
      Where => "i.parent_id=? AND i.item_date=? AND Category$level is not null",
      Bind => [ $catalog->id, $current_date ],
      GroupBy => "i.category$level, c.title",
      OrderBy => 'c.title',
      );

  # Restrict categories
  my @where;
  if ( $ARGS{catid}) {
    push @where, "i.category$level = $ARGS{catid}";
  }
  if ( $ARGS{catid1} ) {
    push @where, "i.category1 = $ARGS{catid1}";
  }

  # Restore and show categories
  $cat->restore_where(where => \@where);
  return if ! $cat->rows;

  my $counter = 0;
  while($cat->restore_next) {
    $counter++;
    local $_ = $cat;
    my $content = $m->content;
    next if ! $content;
    </%perl>
    <& SELF:show_category_name, name => $cat->title, items_count => $cat->items &>
    <% $content %>
    <%perl>
  }
</%perl></%method>




%#=== @METAGS div_right ====================================================
<%method div_right><%perl>
  my $cm = $ARGS{cm} || 1;
  $cm *= 20;
  my $content = $ARGS{content} || $m->content;
  return if ! $content;
</%perl>
<div style="margin-left: <% $cm %>px;">
<% $content %>
</div>
</%method>





%#=== @metags show_next_prev_link ====================================================
<%method show_next_prev_link><%perl>
  my $current_date = $ARGS{current_date};

  # Item not selected
  return if ! $item->check_id;

  # Next id 
  my $next_id = $item->dbh->selectrow_array("SELECT id FROM CtlgItem
      WHERE parent_id=? and item_date=? and id > ? ORDER BY id LIMIT 1",
      undef, $item->parent_id, $current_date, $item->id);
  
  # Prev id 
  my $prev_id = $item->dbh->selectrow_array("SELECT id FROM CtlgItem
      WHERE parent_id=? and item_date=? and id < ? ORDER BY id DESC LIMIT 1",
      undef, $item->parent_id, $current_date, $item->id);
  
  return if $next_id==0 and $prev_id==0;
</%perl>
<& /dialog.mc:_table3td, 
    td1 => $prev_id > 0
            ? sprintf('<a href="/catalog/%d/%d/" title="%s">&lt;&lt;&lt;</a>', $catalog->id, $prev_id,
                      pick_lang(rus => "Предыдущая статья", eng => "Previous article"))
            : undef,
    td3 => $next_id > 0
            ? sprintf('<a href="/catalog/%d/%d/" title="%s">&gt;&gt;&gt;</a>', $catalog->id, $next_id,
                      pick_lang(rus => "Следующая статья", eng => "Next article"))
            : undef,
    &>
</%method>
