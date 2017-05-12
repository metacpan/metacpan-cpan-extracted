%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software
%#
%#----------------------------------------------------------------------------
<%doc>

=head1 NAME

list.mc - List of something as HTML table

=head1 SYNOPSIS

This Mason component replaces absoleted ePortal::HTML::List package.

It is used to create HTML tables for iterable objects and arrays.

 <&| /list.mc, id=>'list1', obj => $object OR  list => [@array] &>

  <&| /list.mc:row, parameters &>   # this method is optional
    <& /list.mc:column, parameters &>
    <& /list.mc:column_image, src => ... &>
  </&> # end of row
  <&| /list.mc:extra_row &>
     ...
  </&>

  # These method going after all "column" methods
  <&| /list.mc:before_title &> ...  </&>
  <&| /list.mc:after_title &> ...  </&>
  <&| /list.mc:before_footer &> ...  </&>
  <&| /list.mc:after_footer &> ...  </&>

  <&  /list.mc:row_span &>
 </&> # end of list

The typical list consists of the following:

 <table>
  <form>

   <before_title row>
   <title row>
   <after_title row>

     <one or more rows>
      <extra_row for each row>

   <before_footer row>
   <footer row>
   <action_bar row>
   <after_footer row>

  </form>
 </table>

The content of <&| list.mc &> is responsible for HTML generation of each row.

The very first call to content is when row_number==0. This call is used to 
count all columns, create soring groups and discover column titles. 
ThePersistent object is not restored at this moment and $_ is undefined for 
array lists.

Use local variable C<$_> as iterator for array. $_ is the object for 
ThePersistent lists.

=head1 PARAMETERS

All -xxx like parameters are passed directly to CGI::start_table. Others are

=over 4

=item * id

The ID of the list. Used for submit forms and when more then 1 list exists on
page.

=item * submit

Make HTML form inside the list.

=item * no_title

Do not produce title row

=item * no_footer

=over 4

=item * ==1

Do not produce footer row any case

=item * ==2

Show footer row if there is more than one page to display

=back

=item * order_by

ID of column to order by this column by default or "!ID" string to order by 
descending.

=back

=head1 METHODS

=cut

</%doc>
%#== @metags start_of_list ============================================
<%perl>

  # initialise global list hash
  my $L = {
    row_number => 0,    # Current row on page starting from 1
    column_number => 0,
    columns => 0,       # Number of columns with data

    rows => 20,         # rows per page
    page => 1,          # page number to display

    column_title => [],        # title for each column after first row
    column_id_num => {},       # hash ID => column number
    column_num_id => [],
    column_order_by => [],     # array column number => order_by
    column_order_by_desc => [],
    no_title => 0,             # do not show title row
    no_footer => 0,
    id => $ARGS{id} || 'L',    # ID of the list
    submit => 0,               # Make submit form
    title_bgcolor => '#cdcdcd',

    row_method_called => undef,    # 1 of called at least once per iteration
    column_method_called => undef,
    obj => $ARGS{obj},
    list => $ARGS{list},
    };
  
  # Push current list on the stack
  $gdata{list_stack} ||= [];
  push @{$gdata{list_stack}}, $gdata{list};
  $gdata{list} = $L;

  my $obj = $L->{obj};
  my $list = $L->{list};
  my $listid = $L->{id};

  # get arguments from %ARGS
  foreach (qw/ page rows no_title no_footer submit order_by /) {
    $L->{$_} = $ARGS{$_} if exists $ARGS{$_};
  }
  # get arguments from request
  my %args = $m->request_args;
  $L->{page} = $args{'page'.$listid} if $args{'page'.$listid} > 0;
  $L->{rows} = $args{'rows'.$listid} if List::Util::first {$args{'rows'.$listid} == $_} 10,20,50,100;
  $L->{order_by} = $args{'order_by'.$listid} if $args{'order_by'.$listid};

  # Very first call to content with row_number==0
  # Need it to iterate all columns
  {
    local $_ = $L->{obj};
    $m->content;
  }

  # Starting row number (0 bazed)
  my $offset = ($L->{page}-1) * $L->{rows};

  # restore ThePersistent object
  my $items_in_collection;
  if ( ref($obj) ) {
    
    # Apply optional order_by
    my ($desc, $order_by) = ($L->{order_by} =~ /^(\!?)(.*)$/o);
    my $sort_column_number = $L->{column_id_num}{$order_by};
    if ( $sort_column_number ) {
      $ARGS{restore_where}{order_by} = $desc
        ? $L->{column_order_by_desc}[$sort_column_number]
        : $L->{column_order_by}[$sort_column_number];
    } else {  # order_by column not found. Looking for default
      for(my $i=0; $i < $L->{columns}; $i++) {
        if ( $L->{column_order_by}[$i] ) {
          $L->{order_by} = $L->{column_num_id}[$i];
          $ARGS{restore_where}{order_by} = $L->{column_order_by}[$i];
          last;
        }
      }  
    }  
    
    # Apply restore_where parameters
    $ARGS{restore_where}{limit_offset} = $offset;
    $ARGS{restore_where}{limit_rows} ||= 1000;
    $obj->restore_where(%{$ARGS{restore_where}});
    $items_in_collection  = $obj->rows;
  } else {
    $items_in_collection = scalar( @{$L->{list}} );
  }

  # Calculate a number of pages total
  { use integer;
  $L->{pages} = $L->{page}  + ($items_in_collection-1) / $L->{rows};
  $L->{page} = $L->{pages} if $L->{page} > $L->{pages};
  }

  # start <table>
  my %CGI = (
    -width => '99%',
    -cellpadding=>1,
    -cellspacing=>0,
    -border => 0,
  );
  foreach (keys %ARGS) {
    $CGI{$_} = $ARGS{$_} if /^-/o;
  }
  $m->print( CGI::start_table(\%CGI) );
  $m->comp('SELF:_submit_form') if $L->{submit};
  $m->comp('SELF:_title');
  $m->flush_buffer;

  # list iterator
  ITERATOR:
  while(1) {
    $L->{row_number} ++;

    # Prepare internal row data
    $L->{row_method_called} = 0;
    $L->{column_method_called} = 0;


    # get next iteration
    my $content;
    if ( ref($obj) ) {
      $L->{more_data} = $obj->restore_next;
      last ITERATOR if ! $L->{more_data};

      local $_ = $obj;
      $content = $m->content;

    } else {
      my $i = $offset + $L->{row_number} - 1;
      $L->{more_data} = exists $list->[$i];
      last ITERATOR if ! $L->{more_data};

      $L->{current_element} = $list->[$L->{row_number}-1];
      local $_ = $L->{current_element};
      $content = $m->content;
    }

    # output row
    if (! $L->{row_method_called}) {
      $m->comp('SELF:row', content => $content) ;
    } else {
      $m->print($content);
    }
    $m->flush_buffer;

    # limit number of rows per page
    if ( $L->{row_number} >= $L->{rows} ) {
      last ITERATOR;
    }
  }
  
  # Stopped at first row. That is no data available to show
  if ($L->{row_number} == 1) {
    $m->comp('SELF:_nodata');
  }
  
  # finish output
  $m->comp('SELF:_footer');
  $m->print('</form>') if $L->{submit};
  $m->print('</table>');
  $m->comp('SELF:_javascript');
  $m->flush_buffer;

  $gdata{list} = pop @{$gdata{list_stack}};
</%perl>



%#=== @METAGS row ====================================================
<%doc>

=head2 row

Generic method to make a row. Call once per list content. Use 
L<extra_row|extra_row> method if you need more than one row per iteration.

This is optionsl method. list.mc call it implicitly at least once if you don't.

 <&| /list.mc:row &>
  <& /list.mc:column &>
  ...
 </&>

 <&| /list.mc:extra_row &>
  this is additional row
 </&>

=over 4

=item * -xxx

All parameters starting with '-' are passed to CGI::Tr() function.

=back

=cut

</%doc>
<%method row><%perl>
  my $L = $gdata{list};
  $L->{row_method_called} = 1;

  $L->{column_number} = 0;

  my $content = $ARGS{content} || $m->content;
  $content = $m->scomp('SELF:column', content => $content)
    if ! $L->{column_method_called};

  # prepare CGI parameters
  my %CGI = (
    '-bgcolor' => $L->{row_number} % 2 == 1? '#FFFFFF' : '#eeeeee',
  );
  foreach (keys %ARGS) {
    $CGI{$_} = $ARGS{$_} if substr($_, 0, 1) eq '-';
  }

  return if $L->{row_number} == 0;
</%perl>
<% CGI::Tr(\%CGI, $content) %>
</%method>



%#=== @metags extra_row ====================================================
<%doc>

=head2 extra_row

Produce "extra" row in the same style as main row. Used for description and
memos

=over 4

=item * start_column

By default extra_row is a td with all columns colspan. C<start_column>
specifies starting column to make colspan

=item * tr

Parameters hash to pass to CGI::Tr() function

=item * td

Parameters hash to pass to CGI::td() function

=item * -xxx

All parameters starting with '-' treated as parameters for td

=item * content

The content of extra row. You may use <&|> call instead of it.

=back

=cut

</%doc>
<%method extra_row><%perl>
  my $L = $gdata{list};
  my $content = $ARGS{content} || $m->content;

  # row parameters
  $ARGS{tr}{-bgcolor} = $L->{row_number} % 2 == 1? '#FFFFFF' : '#eeeeee',

  # td parameters
  $ARGS{start_column} ||= 1;
  my $first_cell_colspan = $ARGS{start_column};
  $ARGS{td}{-colspan} = $L->{columns} - $first_cell_colspan;

  foreach (keys %ARGS) {
    $ARGS{td}{$_} = $ARGS{$_} if substr($_, 0, 1) eq '-';
  }

</%perl>
  <% CGI::Tr($ARGS{tr},
      CGI::td({-colspan => $first_cell_colspan}, img(src => '/images/ePortal/1px-trans.gif')),
      CGI::td($ARGS{td}, $content)
      ) %>
</%method>

%#=== @metags row_span ====================================================
<%doc>

=head2 row_span

Make a space between rows.

 <&| list.mc:row &>
  ...
 </&>
 <& list.mc:row_span &>

=over 4

=item * height

Height of free space in pixels

=back

=cut

</%doc>
<%method row_span><%perl>
  my $L = $gdata{list};
  $ARGS{height} ||= 4;
  my %CGI = (
    '-bgcolor' => $L->{row_number} % 2 == 1? '#FFFFFF' : '#eeeeee',
  );
</%perl>
<% CGI::Tr( \%CGI,
    CGI::td(
      {-colspan => $L->{columns}, -height => $ARGS{height}},
      img(src => '/images/ePortal/1px-trans.gif', height => $ARGS{height}, width=>1)
    )
   ) %>
</%method>


%#=== @metags action_bar ====================================================
<%doc>

=head2 action_bar

Action bar below footer consists of two cells. Left is your content and right
is popup_menu with submit button. The name of popup_menu is B<list_action>.
You may get it with L<list_action|list_action> method or as $ARGS{list_action}.

Array of ID of selected checkboxes available with L<checkboxes|checkboxes> method.

=over 4

=item * content

The content of left cell. You may use <&|> call instead of it.

=item * td

Parameters hash for left CGI::td() function

=item * popup_menu

Parameters hash for popup_menu

=item * button

Optional parameters hash for submit button. Defaults are enough.

=item * label

A label for popup_menu. Default is "Selected items:"

=back

=cut

</%doc>
<%method action_bar><%perl>
  my $L = $gdata{list};
  $ARGS{content} = $m->content if ! exists $ARGS{content};
  $L->{action_bar_content} = $m->scomp('SELF:_action_bar', %ARGS);
</%perl></%method>
%# action_bar method does not produces any HTML output. Actually it does _action_bar
<%method _action_bar><%perl>
  my $L = $gdata{list};
  my $content = $ARGS{content} || img(src => '/images/ePortal/1px-trans.gif');
  $ARGS{td} ||= {};
  $ARGS{label} = pick_lang(rus => "Отмеченные:", eng => "Selected items:") if ! exists $ARGS{label};
  $ARGS{popup_menu}{-class} ||= 'dlgfield';
  $ARGS{popup_menu}{-name}  ||= 'list_action'.$L->{id};
</%perl>
<!-- action bar method -->
<tr bgcolor="<% $L->{title_bgcolor} %>"><td colspan="<% $L->{columns} %>" bgcolor="<% $L->{title_bgcolor} %>">
 <table width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <% CGI::td($ARGS{td}, $content) %>
    <td align="right">
      <% $ARGS{label} %>
      <% CGI::popup_menu($ARGS{popup_menu}) %>
      <% CGI::submit({-name => 'submit'.$L->{id}, -class => 'button', -value => '...'}) %>
    </td>
  </tr>
 </table>
</td></tr>
</%method>


%#=== @metags checkboxes ====================================================
<%doc>

=head2 checkboxes

Returns array ID of checked checkboxes or empty array.

=cut

</%doc>
<%method checkboxes><%perl>
  my $listid = $ARGS{id} || 'L';
  my %args = $m->request_args;

  my $ary = $args{'list_chbox'.$listid};
  if ( ref($ary) eq 'ARRAY' ) {
    return @{$ary};
  } else {
    return $ary ? $ary : ();
  }
</%perl></%method>

%#=== @metags list_action ====================================================
<%doc>

=head2 list_action

Returns a value of list_action popup_menu or undef if form was not submitted.
The fact of submit is request method eq 'POST'.

=cut

</%doc>
<%method list_action><%perl>
  # $gdata{list} not exists at this point
  my $listid = $ARGS{id} || 'L';
  my %args = $m->request_args;

  return $r->method eq 'POST' ? $args{'list_action'.$listid} : undef;
</%perl></%method>


%#=== @METAGS column ====================================================
<%doc>

=head2 column

Generic method to make a column. Call it as many times as many columns you 
have. Place the calls inside C<row> method.

=over 4

=item * id

ID of the column. Also act as field name for Persistent objects

=item * title

Column title

=item * a

Hashref of arguments for CGI::a(). 

=item * url

More short way to say a => {-href => ...}

=item * self_url

Hashref of parameters to cunstruct self referencing URL. These parameters
will be replaced with given values.

A special parameter '#' => ... will be added as URL anchor

=item * -xxx

All parameters like -xxx are passed to CGI::td() function.

=item * order_by

Order By clause of SQL query when sort is on by this column. C<id> column 
parameter is required if you use C<order_by> of C<order_by_desc> feature.

=item * order_by_desc

Descending sorting for this column. By default is "L<order_by|order_by> DESC".

=back

=cut

</%doc>
<%method column><%perl>
  my $L = $gdata{list};
  $L->{column_method_called} = 1;
  $L->{column_number} ++;

  # Process TD content
  my $content = $ARGS{content};
  if ( $L->{row_number} > 0) {
   $content ||= $m->content;
    if ( $content eq '' and ref($L->{obj}) and $ARGS{id} ) {
      $content = $L->{obj}->htmlValue($ARGS{id});
    }
  }

  # Add optional URL around cell content
  if ( $L->{row_number} > 0) {
    $ARGS{a}{-href} = $ARGS{url} if $ARGS{url};

    if ( ref($ARGS{self_url}) eq 'HASH') {
      my %a = $m->request_args;
      my $anchor;
      foreach (keys %{$ARGS{self_url}}) {
        if ( $_ eq '#' ) {
          $anchor = '#' . $ARGS{self_url}{$_};
        } else {
          $a{$_} = $ARGS{self_url}{$_};
        }  
      }
      $ARGS{a}{-href} = href($ENV{SCRIPT_NAME}, %a) . $anchor;
    }
    $content = CGI::a($ARGS{a}, $content) if ref($ARGS{a}) eq 'HASH';
  }

  # Some things do only once
  if ( $L->{row_number} == 0) {
    # save column title.
    my $title = $ARGS{title};
    if ( $ARGS{id} and ref($L->{obj}) ) {
      my $a = $L->{obj}->attribute($ARGS{id});
      $title ||= $a->{label} if $a;
      $title = pick_lang($title) if ref($title) eq 'HASH';
    }
    $L->{column_title}[ $L->{column_number} -1 ] = $title;
    $L->{column_width}[ $L->{column_number} -1 ] = $ARGS{-width};
    $L->{column_num_id}[$L->{column_number} - 1] = $ARGS{id};
    $L->{column_id_num}{$ARGS{id}} = $L->{column_number}-1 if $ARGS{id};
    
    throw ePortal::Exception::Fatal(-text => 'Sortable column should have ID')
      if $ARGS{order_by} and ! $ARGS{id};
    $L->{column_order_by}[ $L->{column_number} -1 ] = $ARGS{order_by};
    $L->{column_order_by_desc}[ $L->{column_number} -1 ] = $ARGS{order_by_desc} || "$ARGS{order_by} DESC";

    # Calculate the number of columns
    $L->{columns} = List::Util::max($L->{columns}, $L->{column_number});
  }
  
  # prepare CGI::td parameters
  my %CGI = (
  );
  foreach (keys %ARGS) {
    $CGI{$_} = $ARGS{$_} if substr($_, 0, 1) eq '-';
  }

  return if $L->{row_number} == 0;
</%perl>
<% CGI::td(\%CGI, $content) %>
</%method>


%#=== @metags column_image ====================================================
<%doc>

=head2 column_image

A column with image.

=over 4

=item * src

Path to image. Default is C</images/icons/msg.gif>

=back

=cut

</%doc>
<%method column_image><%perl>
  if ( ! $ARGS{src} ) {
    $ARGS{src} = '/images/icons/msg.gif';
    $ARGS{-width} = '2%';
  }
  $ARGS{content} = img( src => $ARGS{src} );
</%perl>
<& SELF:column, %ARGS &>
</%method>


%#=== @METAGS column_delete ====================================================
<%doc>

=head2 column_delete

Produce delete button.

=over 4

=item * url

Optional URL for delete action.

=item * objid

Optional object id for delete.htm. Default is ID of current object.

=item * objtype

Reference type of object to delete. Default is ref of current object.

=back

=cut

</%doc>
<%method column_delete><%perl>
  my $L = $gdata{list};
  my $href = $ARGS{url} ||
              href("/delete.htm",
                objid => $ARGS{objid} || $L->{obj}->id,
                objtype => $ARGS{objtype} || ref($L->{obj})
                );

</%perl>
<&| SELF:column, -align => 'center', -width => '3%', title => '', id => 'column_delete',
    a => { -href => $href,  -title => pick_lang(rus => "Удалить", eng => "Delete") } &>
<% img(src => "/images/ePortal/trash.gif") %>
</&>
</%method>


%#=== @METAGS column_edit ====================================================
<%doc>

=head2 column_edit

Produce "edit object" button.

=over 4

=item * url

URL for edit action.

=item * objid

Optional object id of object to edit. Default is ID of current object.

=back

=cut

</%doc>
<%method column_edit><%perl>
  my $L = $gdata{list};
  my $href = $ARGS{url};
  throw ePortal::Exception::Fatal(-text => "Required argument url missing for list.mc:column_edit")
    if ! $href;
</%perl>
<&| SELF:column, -align => 'center', -width => '3%', title => '', id => 'column_edit',
    a => { -href => $href,  -title => pick_lang(rus => "Редактировать", eng => "Edit") } &>
<% img(src => "/images/ePortal/setup.gif") %>
</&>
</%method>


%#=== @metags column_checkbox ====================================================
<%doc>

=head2 column_checkbox

Produce checkbox column

=over 4

=item * value

The value of checkbox. Default is array element or object ID

=item * name

Name of checkbox field. Default is C<list_chboxLISTID>

=back

=cut

</%doc>
<%method column_checkbox><%perl>
  my $L = $gdata{list};
  my $name = $ARGS{name} || 'list_chbox'.$L->{id};
  my $formname = 'lf'.$L->{id};
  my $value = $ARGS{value};
  if ( ! exists $ARGS{value} ) {  # $value is undefined for row_count==0
    if ( ref($L->{obj}) ) {
      $value = $L->{obj}->id;
    } else {
      $value = $L->{current_element};
    }
  }

#  throw ePortal::Exception::Fatal(-text => "column_checkbox requires submit parameter for list.mc")
#    if ! $L->{submit};
</%perl>
<&| SELF:column, -align => 'center', -width => '3%', title => '', id => 'column_checkbox',
    title =>
      img( src => "/images/ePortal/plus.gif", href => "javascript:CheckAll_$L->{id}(true)" ) .
      img( src => "/images/ePortal/minus.gif", href => "javascript:CheckAll_$L->{id}(false)" )
     &>
 <% CGI::checkbox(-class=> 'dlgfield', -name => $name, -label => '', -value => $value ) %>
</&>
</%method>


%#=== @metags column_number ====================================================
<%doc>

=head2 column_number

Row number counter

=cut

</%doc>
<%method column_number><%perl>
  my $L = $gdata{list};
  my $n = ($L->{page}-1) * $L->{rows} + $L->{row_number};
</%perl>
<&| SELF:column, title => '', id => 'column_number', -width => '3%' &>
<% $n %>.&nbsp;
</&>
</%method>



%#=== @metags _title ====================================================
<%method _title><%perl>
  my $L = $gdata{list};
  my %args = $m->request_args;
  delete $args{'order_by'.$L->{id}};
</%perl>
% if ( $L->{before_title_content} ) {
  <% CGI::Tr({}, CGI::td({-colspan => $L->{columns} }, $L->{before_title_content})) %>
% }


% if (! $L->{no_title} ) {
<tr bgcolor="<% $L->{title_bgcolor} %>">
    <%perl>
    for(my $i=0; $i < $L->{columns}; $i++) {
     my $title = $L->{column_title}[$i] ? '<b>'. $L->{column_title}[$i] . '</b>' : '&nbsp;';

     if ( $L->{column_order_by}[$i] ) {
      $title .= '&nbsp;' . 
                img(src => '/images/icons/ascend.gif', 
                    href => href($ENV{SCRIPT_NAME}, 
                    'order_by'.$L->{id} => $L->{column_num_id}[$i], %args)) . 
                img(src => '/images/icons/descend.gif',
                    href => href($ENV{SCRIPT_NAME}, 
                    'order_by'.$L->{id} => '!'.$L->{column_num_id}[$i], %args));
     }

     my %CGI = (-nowrap => undef, -bgcolor => $L->{title_bgcolor}, -align=>'center');
     $CGI{-width} = $L->{column_width}[$i] if $L->{column_width}[$i];
     $CGI{-valign} = 'top';
    </%perl>
      <% CGI::td(\%CGI, $title) %>
    <%perl>
    }
    </%perl>
</tr>
% }


% if ( $L->{after_title_content} ) {
  <% CGI::Tr({}, CGI::td({-colspan => $L->{columns} }, $L->{after_title_content})) %>
% }
</%method>

%#=== @metags _footer ====================================================
<%method _footer><%perl>
  my $L = $gdata{list};
  my %args = $m->request_args;
  my $content = $m->content;

  # Page number selector
  my $page = $L->{page};
  my $pages = $L->{pages};
  my $listid = $L->{id};
</%perl>


% if ( $L->{before_footer_content} ) {
  <% CGI::Tr({}, CGI::td({-colspan => $L->{columns} }, $L->{before_footer_content})) %>
% }


% if ( ($L->{no_footer}==0) or ($L->{no_footer}==2 and ($pages > 1 or $page > 1)) ) {
<tr bgcolor="<% $L->{title_bgcolor} %>"><td colspan="<% $L->{columns} %>" bgcolor="<% $L->{title_bgcolor} %>">
% if ($content) {
 <% $content %>
% } else {
  <table width="100%" cellspacing="0" cellpadding="0" border="0"><tr>
    <td nowrap valign="middle">
      &nbsp;<% pick_lang(rus => "Строк на страницу:", eng => "Rows per page:") %>
% delete $args{'rows'.$listid};
% $args{'page'.$listid} = $L->{page};
% foreach my $p (10, 20, 50, 100) {
  &nbsp;
% if ($L->{rows} == $p) {
  <b><% $p %></b>
% } else {
  <a href="<% href($ENV{SCRIPT_NAME}.$ENV{PATH_INFO}, 'rows'.$listid => $p, %args) %>"><u><% $p %></u></a>
% }
  &nbsp;
% }
    </td>
    <td nowrap valign="middle" align="right">
      <% pick_lang(rus => "Страница:", eng => "Page:") %>

% $args{'rows'.$listid} = $L->{rows};
% delete $args{'page'.$listid};
% if ($page > 1) {
  <a href="<% href($ENV{SCRIPT_NAME}.$ENV{PATH_INFO}, 'page'.$listid => $page-1, %args) %>"
        title="<% pick_lang(rus => "Предыдущая страница", eng => "Previous page")
        %>"><u>&lt;&lt;&lt;</u></a>&nbsp;&middot;&nbsp;
% }
% if ($page >= 7) {
  <a href="<% href($ENV{SCRIPT_NAME}.$ENV{PATH_INFO}, 'page'.$listid => 1, %args) %>"><u>1</u></a>&nbsp;&middot;&nbsp;
% }


% foreach my $p( $page-5 .. $page+5 ) { next if $p < 1; last if ($p > $pages);
% if ($p == $page) {
  <b><% $p %></b>&nbsp;&middot;&nbsp;
% } else {
  <a href="<% href($ENV{SCRIPT_NAME}.$ENV{PATH_INFO}, 'page'.$listid => $p, %args) %>"><u><% $p %></u></a>&nbsp;&middot;&nbsp;
% }
% }


% if ($page < $pages) {
  <a href="<% href($ENV{SCRIPT_NAME}.$ENV{PATH_INFO}, 'page'.$listid => $page+1, %args) %>"
        title="<% pick_lang(rus => "Следующая страница", eng => "Next page")
        %>"><u>&gt;&gt;&gt;</u></a>
% }
    </td>
  </tr></table>
% }
</td></tr>
% } # end of if ! no_footer

% if ( $L->{action_bar_content} ) {
  <% $L->{action_bar_content} %>
% }

% if ( $L->{after_footer_content} ) {
  <% CGI::Tr({}, CGI::td({-colspan => $L->{columns} }, $L->{after_footer_content})) %>
% }
</%method>


%#=== @metags state ====================================================
<%doc>

=head2 state

Returns HASH of arguments that represent current state of the list. Put these
parameters to other forms on the page to save list apperance untouched.

=over 4

=item * id

ID of list

=back

=cut

</%doc>
<%method state><%perl>
  my $listid = $ARGS{id} || 'L';
  my %args = $m->request_args;
  my %state;

  foreach (qw/page order_by rows list_action /) {
    $state{$_ . $listid} = $args{$_ . $listid} if $args{$_ . $listid};
  }
  return %state;
</%perl></%method>



%#=== @METAGS self_url ====================================================

<%doc>

=head2 self_url

Return self referencing URL without checkboxes selected.

=cut

</%doc>
<%method self_url><%perl>
  my $listid = $ARGS{id} || 'L';
  my %args = $m->request_args;
  foreach (keys %args) {
    delete $args{$_} if /^list_chbox/o;
    delete $args{$_} if /^submit/o;
  }  
  return href($ENV{SCRIPT_NAME}, %args);
</%perl></%method>

%#=== @METAGS state_as_hidden ====================================================
<%doc>

=head2 state_as_hidden
 
Put list state as hidden fields into your form
 
=cut

</%doc> 
<%method state_as_hidden><%perl>
  my %state = $m->comp('SELF:state', %ARGS);
  foreach (keys %state) {
    $m->print(CGI::hidden(-name => $_, -value => $state{$_}, -override=>1));
  }  
</%perl></%method>



%#=== @METAGS _submit_form ====================================================
<%method _submit_form><%perl>
  my $L = $gdata{list};
  my $listid = $L->{id};

  my %args = $m->request_args;
  $args{'rows'.$listid}    = $L->{rows};
  $args{'page'.$listid}    = $L->{page};
  $args{'order_by'.$listid} = $L->{order_by};
  delete $args{'list_action'.$listid};
  delete $args{'submit'.$listid};
  delete $args{'list_chbox'.$listid};
</%perl>

<form name="lf<% $listid %>" method="POST" action="<% $ENV{SCRIPT_NAME} %>">
%  foreach (keys %args) {
  <% CGI::hidden(-name => $_, -value => $args{$_}, -override=>1 ) %>
%  }
</%method>


%#=== @metags before_title ====================================================
<%doc>

=head2 before_title,after_title,before_footer,after_footer

This method used to insert a text before|after title|footer row. Place it AFTER all
C<column> methods. The content of method method is placed into one
wide TD cell. Arguments are:

 <&| /list.mc:before_title &>
  this text goes before title row
 </&>

=cut

</%doc>

<%method before_title><%perl>
  my $L = $gdata{list};
  $L->{before_title_content} ||= $ARGS{content} || $m->content;
</%perl></%method>
<%method after_title><%perl>
  my $L = $gdata{list};
  $L->{after_title_content} ||= $ARGS{content} || $m->content;
</%perl></%method>
<%method before_footer><%perl>
  my $L = $gdata{list};
  $L->{before_footer_content} ||= $ARGS{content} || $m->content;
</%perl></%method>
<%method after_footer><%perl>
  my $L = $gdata{list};
  $L->{after_footer_content} ||= $ARGS{content} || $m->content;
</%perl></%method>


%#=== @METAGS _nodata ====================================================
<%method _nodata><%perl>
  my $L = $gdata{list};
  $L->{nodata} ||= 
    '<font color="red">' .
    pick_lang(rus => "Нет данных для просмотра", eng => "No more data to show") .
    '</font>';

</%perl>
<% CGI::Tr({}, CGI::td({-colspan => $L->{columns} }, $L->{nodata})) %>
</%method>



%#=== @metags nodata ====================================================
<%doc>

=head2 nodata

What to show when no data available in recordset?

=over 4

=item * content

The content of warning

=back

=cut

</%doc>
<%method nodata><%perl>
  my $L = $gdata{list};
  my $content = $ARGS{content} || $m->content;
  $L->{nodata} = $content;
</%perl></%method>

%#=== @metags _javascript ====================================================
<%method _javascript><%perl>
  my $L = $gdata{list};
</%perl>
<script language="JavaScript">
<!--
function CheckAll_<% $L->{id} %>(checked) {
  var i;
  
  for (i=0; i < document.all.length; i++) {
    if (document.all(i).type == "checkbox" &&
      document.all(i).name == "list_chbox<% $L->{id} %>") {
        document.all(i).checked = checked;
    }
  }
}
// -->
</script>
</%method>


%#=== @metags filter ====================================================
<%filter>
  # ----------------------------------------------------------------------
  # remove empty lines from content
  s/\n[\s\r]*\n/\n/gso;
</%filter>



<%doc>

=head1 REQUEST ARGUMENTS

These arguments are significant for list.mc when exists in request. See 
L<state|state> method for convenient way to get hash of all of them.

=over 4

=item * rowsLISTID

Rows per page for LISTID list.

=item * pageLISTID

Page number to display for LISTID list.

=item * order_byLISTID

Sort order internal variable. This is id of column to sort ascending or !id 
to sort descending.

=back



=head1 AUTHOR

Sergey Rusakov, E<lt>rusakov_sa@users.sourceforge.netE<gt>

=cut

</%doc>
