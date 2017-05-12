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

dialog.mc - Dialog contruction module.

=head1 SYNOPSIS

This Mason component replaces obsoleted ePortal::HTML::Dialog package.

C<dialog.mc> is used to draw a dialog like windows. Some methods are used
for easy creation of dialogs to edit C<ThePersistent> objects.

=head2 Usage

 <&| /dialog.mc, parameters ... &>
  content of the dialog
 </&>

 <%method onStartRequest><%perl>
  $obj = new ePortal::Catalog;
  $m->comp('/dialog.mc:handle_request', obj => $obj);
 </%perl></%method>

=head2 Parameters

=over 4

=item * width,align

These parameters are passed to <table> tag.

=item * color,bgcolor

Colors used

=item * title, title_url, title_popup, title_class

The title of dialog

=item * icons

ArrayRef to HASHes with infomation about icons to place on the right side
of the title. This HASH is passed directly to C<img()> global function.

 icons => [
    { src => '/images/image.gif',
      href => 'some.where.htm',
      title => 'alt description for icons' }
 ]

=item * xxx_icon

Some of icons are known to dialog.mc. No need for them to pass image source
url. Icon names are B<edit q copy min max x>

B<xxx_icon> - URL for the icon

B<xxx_icon_title> - popup title for the icon

where B<xxx> is a name of icon.

=back

=head1 METHODS

=cut

</%doc>
<%perl>
  # ----------------------------------------------------------------------
  # Global Dialog configuration
  my $D = {
    width       => $ARGS{width}    || '70%',
    bgcolor     => $ARGS{bgcolor}  || '#FFFFFF',
    color       => $ARGS{color}    || '#CCCCFF',
    align       => $ARGS{align},
    title       => $ARGS{title},           # The title of dialog
    title_popup => $ARGS{title_popup},     # a Popup message for title
    title_url   => $ARGS{title_url},       # A URL to anchor from title
    title_class => $ARGS{title_class} || 'sidemenu',
    icons       => [],                     # array of hashes of icon description
  };
  $gdata{dialog} = $D;

  # ----------------------------------------------------------------------
  # Add optional icons to dialog caption
  my %well_known_icons = (
    q     => pick_lang(rus => "Помощь", eng => "Help"),
    edit  => pick_lang(rus => "Настроить", eng => "Setup"),
    min   => pick_lang(rus => "Свернуть", eng => "Minimize"),
    max   => pick_lang(rus => "Развернуть", eng => "Maximize"),
    x     => pick_lang(rus => "Закрыть", eng => "Close dialog"),
    copy  => pick_lang(rus => "Копировать", eng => "Copy object"),
    up    => pick_lang(rus => "Передвинуть выше", eng => "Move up"),
    down  => pick_lang(rus => "Передвинуть ниже", eng => "Move down"),
  );

  foreach (qw/down up q copy edit min max x/ ) {   # well known icons
    next if ! exists $ARGS{$_."_icon"};

    if ( exists($ARGS{$_."_icon"}) and $ARGS{$_."_icon"} eq '1') {
      $ARGS{$_."_icon"} = href($ENV{SCRIPT_NAME}, 'dlgb_'.$_ => 1);
    }

    push @{$D->{icons}} , {
          src => "/images/ePortal/dlg_" . $_ . ".png",
          href => $ARGS{$_."_icon"},
          title => $ARGS{$_ . "_icon_title"} || $well_known_icons{$_}
        };
  }
  my $html_icons = join('&nbsp;', map { img(%{$_}) } @{$D->{icons}});
  my $content = $ARGS{content} || $m->content;

  if ( $D->{title_url} ) {
    $D->{title_html} = CGI::a( 
          {-href => $D->{title_url}, -title => $D->{title_popup}}, 
          $D->{title});
  } else {
    $D->{title_html} = $D->{title};
  }

</%perl>
%if ($ePortal::DEBUG) {
<!-- dialog start -->
%}
% if ($D->{align} or $ARGS{extra}) {
 <&| SELF:_table3td, align => $D->{align}, extra => $ARGS{extra} &>
 <& SELF:_dialog, D => $D, html_icons => $html_icons, content => $content &>
 </&>
% } else {
 <& SELF:_dialog, D => $D, html_icons => $html_icons, content => $content &>
% }
%if ($ePortal::DEBUG) {
<!-- dialog end -->
%}
%delete $gdata{dialog};

%#=== @metags _dialog ====================================================
<%method _dialog>
% my $D = $ARGS{D};
% my $html_icons = $ARGS{html_icons};
% my $content = $ARGS{content};

%# Start of the dialog
<table width="<% $D->{width} %>" border="0" cellspacing="1" cellpadding="1" bgcolor="<% $D->{color} %>">
<tr>
 <td align="left" class="<% $D->{title_class} %>" nowrap>
  <% $D->{title_html} %>
 </td>
 <td align="right" nowrap>
   <% $html_icons %>
 </td>
</tr>

%# a Row with dialog's content (start of table)
<tr><td colspan="2" bgcolor="<% $D->{bgcolor} %>">
  <table border="0" width="100%" cellpadding="0" cellspacing="0" bgcolor="<% $D->{bgcolor} %>">
  <tr><td>
  <% $content %>
  </td></tr></table>
</td></tr></table>
</%method>

<%filter>
  # ----------------------------------------------------------------------
  # remove empty lines from dialog content
  if ( ! /<textarea/osi ) {
    s/\n[\s\r]*\n/\n/gso;
  }
</%filter>

%#=== @metags edit_dialog ====================================================
<%doc>

=head2 edit_dialog

This method used to construct "Edit an object" dialog with a submit L<form|form>
iside.

B<WARNING>! This method generates

 <table cols="2">
  Your content here
 </table>

Parameters:

=over 4

=item * obj

C<ThePersistent> object to edit.

=item * xxx_icon

For predefined icons enough to pass parameter

 xxx_icon => 1

to construct an icons with all needed parameters. Call isButtonPressed('xxx')
to check what button or icon was actually clicked.

=item * focus

Name of the field to be focused when dialog apeears on screen

=back

=cut

</%doc>
<%method edit_dialog><%perl>
  my %args = $m->request_args;

  # prepare object to edit
  my $objid;
  $objid = $ARGS{objid} || $args{objid};
  $objid ||= $ARGS{obj}->id if ref($ARGS{obj});
  my $objtype = $ARGS{objtype} || ref($ARGS{obj});
  my $back_url = $m->comp('SELF:back_url');

  # Prepare dialog icons
  foreach (qw/edit q copy min max x/) {
    if ( exists($ARGS{$_."_icon"}) and $ARGS{$_."_icon"} eq '1') {
      $ARGS{$_."_icon"} = href( $ENV{SCRIPT_NAME}, 'dlgb_'.$_ => 1, objid => $objid, back_url => $back_url);
    }
  }

  my %hidden_fields = (dialog_submit => 1);
  $hidden_fields{objid} = $objid if $objid;
  $hidden_fields{objtype} = $objtype if $objtype;
  $hidden_fields{back_url} = $back_url if $back_url;

  $ARGS{formname} ||= 'dialog';
  $ARGS{align} = 'center' if ! exists $ARGS{align};

</%perl>
<&| /dialog.mc, %ARGS &>
  <%perl># $gdata{dialog} just initialized
  my $D = $gdata{dialog};
  $D->{obj} = $ARGS{obj};
  $D->{focus} = $ARGS{focus};
  $D->{formname} = $ARGS{formname};
  </%perl>
 <% CGI::start_table({ -width => '100%', -cellpadding => 0, -cellspacing => 0, -border => 0, -cols => 2 }) %>
  <&| SELF:form,  formname => $ARGS{formname},
                    method => $ARGS{method} || 'POST',
                    multipart => $ARGS{multipart},
                    hidden => \%hidden_fields &>
   <% $m->content %>
  </&>
 </table>
</&>

<%perl>
#
# Focus first field
#
  $ARGS{focus} = $gdata{dialog_focus_field} if ! exists $ARGS{focus};
  delete $gdata{dialog_focus_field};
  if ($ARGS{focus} and $ARGS{formname}) {
    </%perl>
    <script language="JavaScript">
    <!--
      document.<% $ARGS{formname} %>.<% $ARGS{focus} %>.focus();
    // -->
    </script>
% }
</%method>



%#=== @metags form ====================================================
<%doc>

=head2 form

Generate HTML form. See L<field methods|DIALOG FORM FIELDS> for details how
to generate HTML fields.

 <& /dialog.mc:form, parameters, ... &>

=over 4

=item * formname

Name of the form. Default is 'theForm'

=item * method

Method of the form. Default is 'POST'

=item * action

Action of the form. Default is $ENV{SCRIPT_NAME}

=item * multipart,multipart_form

If true generate multipart form.

=back

=cut

</%doc>
<%method form><%perl>
  my $multipart = $ARGS{multipart} || $ARGS{multipart_form};
  $ARGS{method} = 'POST' if $multipart;

  # form parameters
  my %form_parameters = (
    name    => $ARGS{formname}  || 'theForm',
    method  => $ARGS{method}    || 'POST',
    action  => $ARGS{action}    || $ENV{SCRIPT_NAME}
    );

  # hidden fields
  $ARGS{hidden} ||= {};
</%perl>
<% $multipart
    ? CGI::start_multipart_form(\%form_parameters)
    : CGI::start_form(\%form_parameters) %>
% foreach (keys %{$ARGS{hidden}}) {
<& SELF:hidden, name => $_, value => $ARGS{hidden}{$_} &>
% }
 <% $m->content %>
</form></%method>



%#=== @metags dialog_fields ====================================================
<%doc>

=head1 DIALOG FORM FIELDS

Most of dialog field creation method accepts the following parameters:

=over 4

=item * obj

Base ThePersistent object to be edited. The C<$obj> object may contain some
useful attributes: C<fieldtype>, C<value>, C<label>, etc...

=item * label

What label to attach for the field. Default is C<label> attribute of the
object.

=item * value

Default value of the field. Default is C<value> attribute of the object.

=item * class,align

These parameters are applied to C<canvas> property.

=back

=cut

</%doc>



%#=== @METAGS prepare_field ====================================================
%# Internal method to prepare the field for output
<%method prepare_field><%perl>
  my $D = $gdata{dialog};
  # %ARGS passed as ref
  my $args = shift @_;

  # obj may be passed to dialog.mc directly
  $args->{obj} ||= $D->{obj};
  my $obj = $args->{obj};

  # id is synonym for name
  $args->{name} ||= $args->{id};

  # default value
  $args->{defaultvalue} = $args->{value};
  $args->{defaultvalue} ||= $obj->value($args->{name}) if ref($obj) and $obj->attribute($args->{name});
  $args->{defaultvalue} ||= $args->{default} if exists $args->{default};
  $args->{defaultvalue} = join(', ', @{$args->{defaultvalue}}) if ( ref($args->{defaultvalue}) eq 'ARRAY');

  # Save field name for dialog's auto focus feature
  $gdata{dialog_focus_field} ||= $args->{name};

  # Fillin ARGS hash with object attribute parameters
  if ( ref($obj) and $obj->attribute($args->{name})) {
    foreach (qw/size maxlength rows columns class/) {
      $args->{$_} ||= $obj->attribute($args->{name})->{$_}
        if exists $obj->attribute($args->{name})->{$_};
    }  
    $args->{CGI}{-title} ||= $obj->attribute($args->{name})->{description};
    $args->{CGI}{-title} = pick_lang($args->{CGI}{-title}) if ref($args->{CGI}{-title}) eq 'HASH';
  }

  # prepare default CGI parameters
  $args->{CGI}{-name}  = $args->{name};
  $args->{CGI}{-class} = $args->{class} || 'dlgfield';
  foreach (keys %{$args}) {
    $args->{CGI}{$_} = $args->{$_} if /^-/o;
  }  
</%perl></%method>



%#=== @METAGS cell ====================================================
<%doc>

=head2 cell

Draw a cell for edit_dialog. That is is <td colspan="2">. 
All -xxx like parameters are passed to CGI::td() function.

=cut

</%doc>
<%method cell><%perl>
  my %CGI = (colspan => 2);
  my $content = $ARGS{content} || $m->content;
  foreach (keys %ARGS) {
    $CGI{$_} = $ARGS{$_} if /^-/o;
  }    
</%perl>
<tr><% CGI::td(\%CGI, $content) %></tr>
</%method>

%#=== @METAGS label_value_row ====================================================
<%doc>

=head2 label_value_row

Draw a row with two cells: label and value

=over 4

=item * label

=item * value

=back

=cut

</%doc>
<%method label_value_row><%perl>
  my $label = $ARGS{label};
  my $value = $ARGS{value} || $ARGS{content} || $m->content;
</%perl>
  <tr>
    <td align="right">
      <span class="dlglabel"><% $label %>:</span>
    </td>
    <td align="left">
      <% $value %>
    </td>
  </tr>
</%method>


%#=== @METAGS canvas ====================================================
<%doc>

=head2 canvas

Display C<content> inside a C<canvas>.

 <&| /dialog.mc:canvas, label => ..., parameters, ... &>
  dialog value
 </&>

 <canvas>
  <% optional label %>
  <% $m->content %>
 </canvas>

=over 4

=item * label

Optional label for content. Styled with class="dlglabel".

=item * canvas

Type of canvas. May be one of the following: tr td div span none

=item * vertical

Align label and content vertically. Not possible for tr canvas.

 <canvas>
  label
  content
 </canvas>

=back

=cut

</%doc>
<%method canvas><%perl>
  my $c = $ARGS{canvas} || 'tr';
  my $content = $ARGS{content} || $m->content;
  my $label = $ARGS{label};
  $label .= ':' if $label;

  my $align;
  $align = qq{ align="$ARGS{align}"} if $ARGS{align};

  my $colspan;
  $colspan = qq{ colspan="$ARGS{colspan}"} if $ARGS{colspan};
</%perl>

% if ( $c eq 'tr' ) {
% if ($label) {
  <tr>
    <td align="right">
      <span class="dlglabel"><% $label %></span>
    </td>
    <td align="left">
      <% $content %>
    </td>
  </tr>
% } else {
%   $ARGS{canvas} = 'td';
%   $ARGS{colspan} = 2;
 <tr>
  <&| SELF:canvas, %ARGS &><% $content %></&>
 </tr>
% }


% } elsif ( $c eq 'td') {
% $ARGS{canvas} = 'none';
  <td<% $align %><% $colspan %>>
    <&| SELF:canvas, %ARGS &><% $content %></&>
  </td>
% } else {  # none
%  if ($ARGS{vertical}) {
  <span class="dlglabel"><% $label%></span>
  <br><% $content %>
%  } else {
  <span class="dlglabel"><% $label%></span><% $content %>
%  }
% }
</%method>



%#=== @METAGS field ====================================================
<%doc>

=head2 field

Discover field type with a help of C<fieldtype> attribute of the object and
call appropriate method of dialog.mc. Default field type is C<textfield>.

This is default method to produce a dialog field. This method created a row
of table

 <tr>
   <td>label:</td> <td>field</td>
 </tr>

=over 4

=item * obj

The object to edit.

=item * name,id

Mandatory. The name of the field to generate.

=back

=cut

</%doc>

<%method field><%perl>
  my $D = $gdata{dialog};

  $m->comp('SELF:prepare_field', \%ARGS );
  my $label = $m->comp('SELF:_label', %ARGS);

  my $obj = $ARGS{obj};
  my $name = $ARGS{name};
  throw ePortal::Exception::Fatal(-text => 'name parameter is required for dialog.mc:field')
    if ! $name;

  my $fieldtype = $ARGS{fieldtype};
  if (ref($obj)) {
    $fieldtype ||= $obj->attribute($name)->{fieldtype} if $obj->attribute($name);
    $fieldtype ||= 'yes_no' if lc($obj->attribute($name)->{dtype}) eq 'yesno';
  }
  $fieldtype ||= 'textfield';

  my $content;
  if ( $fieldtype eq 'textfield' ) {
    $content = $m->scomp('SELF:textfield', %ARGS);

  } elsif ( $fieldtype eq 'popup_menu' ) {
    $content = $m->scomp('SELF:popup_menu', %ARGS);

  } elsif ( $fieldtype eq 'textarea' ) {
    $content = $m->scomp('SELF:textarea', %ARGS);

  } elsif ( $fieldtype eq 'checkbox' ) {
    $content = $m->scomp('SELF:checkbox', %ARGS);

  } elsif ( $fieldtype eq 'yes_no' ) {
    $content = $m->scomp('SELF:yes_no', %ARGS);

  } elsif ( $fieldtype eq 'password' ) {
    $content = $m->scomp('SELF:password', %ARGS);

  } elsif ( $fieldtype eq 'upload' ) {
    $content = $m->scomp('SELF:upload', %ARGS);

  } elsif ( $fieldtype eq 'xacl' ) {
    $content = $m->scomp('SELF:xacl_field', %ARGS);

  } elsif ( $fieldtype eq 'date' or $fieldtype eq 'datetime') {
    $content = $m->scomp('SELF:date', %ARGS);

  } elsif ( $fieldtype eq 'radio_group') {
    $content = $m->scomp('SELF:radio_group', %ARGS);

  } else {
    throw ePortal::Exception::Fatal(-text => "Unknown field type $fieldtype of attribute $name");
  }
</%perl>
<& SELF:label_value_row, label => $label, value => $content &>
</%method>







%#=== @metags hidden ====================================================
<%doc>

=head2 hidden

/dialog.mc:hidden - generate hidden field

=over 4

=item * name

Name of the field

=item * value

Value of the field

=back

=cut

</%doc>
<%method hidden><%perl>
  HTML::Mason::Escapes::basic_html_escape( \$ARGS{value} );
</%perl><%
  CGI::hidden({ -name => $ARGS{name}, -value => $ARGS{value}, -override => 1})
%></%method>


%#=== @metags popup_menu ====================================================
<%doc>

=head2 popup_menu

Generates list box aka popup_menu.

=over 4

=item * values

Array ref of values

=item * labels

Hash ref of labels for values. Every HASH label is decoded with pick_lang().

=item * popup_menu

Callback function. Called with the object as argument. Should return array

 ($values_array, $labels_hash)

=back

=cut

</%doc>
<%method popup_menu>
<& SELF:prepare_field, \%ARGS &>
<%perl>
  my %CGI = %{$ARGS{CGI}};
  my $obj = $ARGS{obj};

  # Arguments passed directly
  $CGI{-default} = $ARGS{defaultvalue};     # initialized by :prepare_field
  foreach (qw/ size labels values /) {
      $CGI{"-$_"} = $ARGS{$_} if exists $ARGS{$_};
  }
  if (!$CGI{-values} and !$CGI{-labels} and ref($ARGS{popup_menu}) eq 'CODE') {
    ($CGI{-values},$CGI{-labels}) = $ARGS{popup_menu}($obj);
  }

  # Arguments initialized with object
  if ( ref($obj) ) {
    my $A = $obj->attribute($ARGS{name});
    $CGI{-labels} ||=  $A->{labels} if ref($A->{labels}) eq 'HASH';
    $CGI{-values} ||=  $A->{values} if ref($A->{values}) eq 'ARRAY';
    if (!$CGI{-values} and ref($A->{values}) eq 'CODE') {
        $CGI{-values} = $A->{values}($obj);
    }
    if (!$CGI{-values} and !$CGI{-labels} and ref($A->{popup_menu}) eq 'CODE') {
        ($CGI{-values},$CGI{-labels}) = $A->{popup_menu}($obj);
    }

  }

  # decode language with pick_lang
  if (ref($CGI{-labels}) eq 'HASH') {
      foreach (keys %{$CGI{-labels}}) {
          $CGI{-labels}{$_} = pick_lang($CGI{-labels}{$_}) if ref($CGI{-labels}{$_}) eq 'HASH';
      }
  }

</%perl>
<% CGI::popup_menu( {%CGI} ) %>
</%method>

%#=== @metags radio_group ====================================================
<%doc>

=head2 radio_group

Generates radio button group.

=over 4

=item * values

Array ref of values

=item * labels

Hash ref of labels for values. Every HASH label is decoded with pick_lang().

=back

=cut

</%doc>
<%method radio_group>
<& SELF:prepare_field, \%ARGS &>
<%perl>
  my %CGI = %{$ARGS{CGI}};
  my $obj = $ARGS{obj};

  # Arguments passed directly
  $CGI{-default} = $ARGS{defaultvalue};     # initialized by :prepare_field
  foreach (qw/ labels values /) {
      $CGI{"-$_"} = $ARGS{$_} if exists $ARGS{$_};
  }

  # Arguments initialized with object
  if ( ref($obj) ) {
    my $A = $obj->attribute($ARGS{name});
    $CGI{-labels} ||=  $A->{labels} if ref($A->{labels}) eq 'HASH';
    $CGI{-values} ||=  $A->{values} if ref($A->{values}) eq 'ARRAY';
  }

  # decode language with pick_lang
  if (ref($CGI{-labels}) eq 'HASH') {
      foreach (keys %{$CGI{-labels}}) {
          $CGI{-labels}{$_} = pick_lang($CGI{-labels}{$_}) if ref($CGI{-labels}{$_}) eq 'HASH';
      }
  }

</%perl>
<% CGI::radio_group( {%CGI} ) %>
</%method>




%#=== @metags textfield ====================================================
<%doc>

=head2 textfield

Generate text field.

=over 4

=item * size

Visible size of text field

=item * maxlength

Maximum length of input string

=back

See L<DIALOG FORM FIELDS|DIALOG FORM FIELDS> for other parameters.

=cut

</%doc>
<%method textfield>
<& SELF:prepare_field, \%ARGS &>
<%perl>
  my %CGI = %{$ARGS{CGI}};
  my $obj = $ARGS{obj};

  # Arguments passed directly
  $CGI{-value} = $ARGS{defaultvalue};     # initialized by :prepare_field
  foreach (qw/ size maxlength /) {
      $CGI{"-$_"} = $ARGS{$_} if exists $ARGS{$_};
  }
  HTML::Mason::Escapes::basic_html_escape( \$CGI{-value} );
</%perl>
<% CGI::textfield( {%CGI} ) %>
</%method>


%#=== @metags password ====================================================
<%doc>

=head2 password

Generate password input field.

=over 4

=item * size

Visible size of text field

=item * maxlength

Maximum length of input string

=back

See L<DIALOG FORM FIELDS|DIALOG FORM FIELDS> for other parameters.

=cut

</%doc>
<%method password>
<& SELF:prepare_field, \%ARGS &>
<%perl>
  my %CGI = %{$ARGS{CGI}};
  my $obj = $ARGS{obj};

  # Arguments passed directly
  $CGI{-value} = $ARGS{defaultvalue};     # initialized by :prepare_field
  foreach (qw/size maxlength /) {
      $CGI{"-$_"} = $ARGS{$_} if exists $ARGS{$_};
  }

  HTML::Mason::Escapes::basic_html_escape( \$CGI{-value} );
</%perl>
<% CGI::password_field( {%CGI} ) %>
</%method>



%#=== @metags textarea ====================================================
<%doc>

=head2 textarea

Generate text area field.

=over 4

=item * rows,cols

Visible size of text area field

=item * maxlength

Maximum length of input string

=back

See L<DIALOG FORM FIELDS|DIALOG FORM FIELDS> for other parameters.

=cut

</%doc>
<%method textarea>
<& SELF:prepare_field, \%ARGS &>
<%perl>
  my %CGI = (%{$ARGS{CGI}});
  my $obj = $ARGS{obj};

  # Arguments passed directly
  $CGI{-default} = $ARGS{defaultvalue};     # initialized by :prepare_field
  $CGI{-rows}    = $ARGS{rows} || 8;
  $CGI{-cols}    = $ARGS{cols} || 70;

  HTML::Mason::Escapes::basic_html_escape( \$CGI{-defaultvalue} );
</%perl>
<% CGI::textarea( {%CGI} ) %>
</%method>



%#=== @metags xacl_field ====================================================
<%doc>

=head2 xacl_field

Generate ACL property field.

=over 4

=back

See L<DIALOG FORM FIELDS|DIALOG FORM FIELDS> for other parameters.

=cut

</%doc>
<%method xacl_field>
<& SELF:prepare_field, \%ARGS &>
<%perl>
  my %CGI = (%{$ARGS{CGI}});
  my $obj = $ARGS{obj};

  $CGI{-values} = $ARGS{-values} || ['admin', 'everyone', 'uid', 'gid','registered', 'owner'];
  $CGI{-labels} = {
          admin => pick_lang(rus => 'Только администратор',  eng => 'Admin only'),
          everyone => pick_lang(rus => 'Все', eng => 'Everyone'),
          uid => pick_lang(rus => 'Только пользователь', eng => 'Only user'),
          gid => pick_lang(rus => 'Группа пользователей', eng => 'Group of users'),
          owner => pick_lang(rus => 'Владелец', eng => 'Owner'),
          registered => pick_lang(rus => 'Зарегистрированный', eng => 'Registered'),
  };
  $CGI{-onchange} = "on_change_xacl_combo('$ARGS{name}');";

  # current values
  my $defaultvalue = $ARGS{defaultvalue};     # initialized by :prepare_field
  my ($uid_def, $gid_def);
  my ($uid_style, $gid_style) = ('none', 'none');
  if ($defaultvalue =~ /^uid:(.*)/) {
      $defaultvalue = 'uid';
      $uid_def = $1;
      $uid_style = 'inline';
  }
  if ($defaultvalue =~ /^gid:(.*)/) {
      $defaultvalue = 'gid';
      $gid_def = $1;
      $gid_style = 'inline';
  }
  $CGI{'-default'} = $defaultvalue;

  # list of groups
  my $G = new ePortal::epGroup;
  my ($G_values, $G_labels) = $G->restore_all_hash('groupname','groupname', 'hidden=0');


</%perl>
<% CGI::popup_menu( {%CGI} ) .
            '<div id="'. $ARGS{name} .
                '_uidspan" class="smallfont" style="display:'.
                $uid_style . ';"><br>' .
            pick_lang(rus => 'Имя:', eng => 'Name:') .
            CGI::textfield({
                    -name => $ARGS{name}.'_uid',
                    -class => 'dlgfield',
                    -size => 20,
                    -value => $uid_def}) .
            qq{</div>} .
            '<div id="'.$ARGS{name}.'_gidspan" class="smallfont" style="display:'.$gid_style.';"><br>' .
            pick_lang(rus => 'Группа:', eng => 'Group:') .
            CGI::popup_menu({
                    -name => $ARGS{name}.'_gid',
                    -class => 'dlgfield',
                    -values => $G_values,
                    -labels => $G_labels,
                    -default => $gid_def}) .
            qq{</div>} %>
</%method>





%#=== @metags upload ====================================================
<%doc>

=head2 upload

Generate file upload field.

See L<DIALOG FORM FIELDS|DIALOG FORM FIELDS> for other parameters.

=cut

</%doc>
<%method upload>
<& SELF:prepare_field, \%ARGS &>
<%perl>
  my %CGI = (%{$ARGS{CGI}});
  my $obj = $ARGS{obj};

  $CGI{-default} = $ARGS{defaultvalue};     # initialized by :prepare_field
  $CGI{-size}    ||= 30;

</%perl>
<% CGI::filefield( {%CGI} ) %>
</%method>




%#=== @metags yes_no ====================================================
<%doc>

=head2 yes_no

Generates list box or checkbox to input YES or NO.

=cut

</%doc>
<%method yes_no><%perl>
  $ARGS{values} = [0, 1];
  $ARGS{labels} = {
          1 => pick_lang(rus => 'Да',  eng => 'Yes'),
          0 => pick_lang(rus => 'Нет', eng => 'No')
  };
</%perl><& SELF:popup_menu, %ARGS &></%method>




%#=== @metags checkbox ====================================================
<%doc>

=head2 checkbox

Generates checkbox tag.

=cut

</%doc>
<%method checkbox>
<& SELF:prepare_field, \%ARGS &>
<%perl>
  my %CGI = %{$ARGS{CGI}};
  my $obj = $ARGS{obj};

  $CGI{-checked} = $ARGS{defaultvalue};     # initialized by :prepare_field
  $CGI{'-value'} = $ARGS{value} || 1;
  $CGI{'-label'} = $ARGS{checkbox_label} || '';      # checkbox does not have internal label.
                                            # label attribute of the object placed in another TD

</%perl>
<% CGI::checkbox( {%CGI} ) %>
</%method>




%#=== @metags date ====================================================
<%doc>

=head2 date

Generates date input field.

=cut

</%doc>
<%method date>
<& SELF:prepare_field, \%ARGS &>
<%perl>
  my %CGI = %{$ARGS{CGI}};
  my $obj = $ARGS{obj};

  my @date = split('[\s\.]+', $ARGS{defaultvalue}, 4);
  my %CGIdate = %CGI;
  my %CGItime = %CGI;

  $CGIdate{-value} = (split ' ', $ARGS{defaultvalue})[0];
  $CGIdate{-size} = 10;
  $CGIdate{-maxlength} = 10;
  $CGIdate{-name} = $ARGS{name} . '_date';
  $CGIdate{-onBlur} = "javascript:ValidateDate('$CGIdate{-name}');return true;";

  $CGItime{-name} = $ARGS{name} . '_time';
  $CGItime{-value} = (split ' ', $ARGS{defaultvalue})[1] || '00:00:00';
  $CGItime{-size} = 8;
  $CGItime{-maxlength} = 8;
  $CGItime{-onBlur} = "javascript:ValidateTime('$CGItime{-name}');return true;";

  my $click_here = pick_lang(rus => 'Нажмите сюда, чтобы появился календарь',
      rus => 'Click here to show calendar window');
  my $html = CGI::textfield( {%CGIdate} ) .
          CGI::a( {-href => "javascript:DateSelector('$CGIdate{-name}')",
              -onMouseOver => "window.status='$click_here';return true;",
              -onMouseOut => "window.status='';return true;",
              -title => $click_here},
              img(src => "/images/ePortal/pdate.gif"));

  if ($ARGS{fieldtype} eq 'datetime') {
      $html .= '&nbsp;' . CGI::textfield( {%CGItime} );
  }
</%perl>
<% $html %>
</%method>




%#=== @metags read_only ====================================================
<%doc>

=head2 read_only

Generate text read only field.

See L<DIALOG FORM FIELDS|DIALOG FORM FIELDS> for other parameters.

=cut

</%doc>
<%method read_only>
<& SELF:prepare_field, \%ARGS &>
<%perl>
  my $label = $m->comp('SELF:_label', %ARGS);
  my $value = $ARGS{defaultvalue};

  my $name = $ARGS{name};
  my $obj = $ARGS{obj};
  my $htmlValue = $value;
  $htmlValue = $obj->htmlValue($name) if ref($obj);
</%perl>
% if ($name and $value) {
<& SELF:hidden, name => $name, value => $value &>
% }
<& SELF:label_value_row, label => $label, value => $htmlValue &>
</%method>





%#=== @metags buttons ====================================================
<%doc>

=head2 buttons

Display dialog buttons.

 <& /dialog.mc:buttons, parameters, ... &>

Possible button names are: ok, cancel, more, delete, apply.

To diplay a button pass parameter xxx_button => 1

To change predefined label of a button pass parameter xxx_label => "..."

B<ok> and B<cancel> buttons are displayed by default.

=cut

</%doc>
<%method buttons>
<&| SELF:cell, -align => 'right' &>
<& SELF:_buttons, %ARGS &>
</&>
</%method>

%#=== @metags _buttons ====================================================
<%method _buttons><%perl>
  $ARGS{class} ||= 'button';
  $ARGS{align} ||= 'right';
  $ARGS{ok_button}     = 1 if ! exists $ARGS{ok_button};
  $ARGS{cancel_button} = 1 if ! exists $ARGS{cancel_button};

  my %button_label = (
    ok => pick_lang(rus => "Сохранить!", eng => "Save!"),
    cancel => pick_lang(rus => "Отменить", eng => "Cancel"),
    more => pick_lang(rus => "Дальше", eng => "More"),
    delete => pick_lang(rus => "Удалить !!!", eng => "Delete !!!"),
    apply => pick_lang(rus => "Применить", eng => "Apply")
    );

  my @buttons;
  foreach my $b (qw/ more ok apply cancel delete/) {
    push @buttons, CGI::submit( -name => "dlgb_$b",
          -value => $ARGS{$b."_label"} || $button_label{$b},
          -class => $ARGS{class})
        if ($ARGS{$b."_button"});
  }

</%perl>
<% join('&nbsp;&nbsp;&nbsp;&nbsp;', @buttons) %>&nbsp;
</%method>

%#=== @metags _label ====================================================
<%method _label><%perl>
  my $label = $ARGS{label};
  my $D = $gdata{dialog};
  my $obj = $ARGS{obj} || $D->{obj};
  my $name = $ARGS{name} || $ARGS{id};

  $label = $obj->attribute($name)->{label} 
    if ($label eq '') and ref($obj) and $name;

  $label = $ARGS{name} if $label eq '';
  $label = pick_lang($label) if ref($label) eq 'HASH';
  return $label;
</%perl></%method>

%#=== @metags _table3td ====================================================
<%doc>

=head2 _table3td

Internal method. Do not use it! Used to produce one row table with three 
cells. This is the correct way to align a table.

 td1     td2     td3

=over 4

=item * td1

Content of cell td1

=item * td2

Content of cell td2

=item * td3

Content of cell td3

=item * align

Where to place "main" content. Left is td1, center is td2, right is td3.

=item * extra

Extra info. Placed in opposite of main content (left or right). Not used if
main content is aligned at center or none.

=back

=cut

</%doc>
<%method _table3td><%perl>
  my $content = $ARGS{content} || $m->content;

  if ($ARGS{align} eq 'left') {
    $ARGS{td1} ||= $content;
    $ARGS{td3} = $ARGS{extra} if $ARGS{extra};
  } elsif ($ARGS{align} eq 'center') {
    $ARGS{td2} = $content;
  } elsif ($ARGS{align} eq 'right') {    
    $ARGS{td3} ||= $content;
    $ARGS{td1} = $ARGS{extra} if $ARGS{extra};
  }
</%perl>
<!-- _table3td:start -->
% if ( $ARGS{td1} or $ARGS{td2} or $ARGS{td3}) {
<table width="100%" border="0" cellspacing="0" cellpadding="0"><tr>
% if ($ARGS{td1}) {  
<td align="left"><% $ARGS{td1} %></td>
% }
% if ($ARGS{td2}) {  
<td align="center"><% $ARGS{td2} %></td>
% }
% if ($ARGS{td3}) {  
<td align="right"><% $ARGS{td3} %></td>
% }
</tr></table>
% } else {
<% $content %>
% }
<!-- _table3td:end -->
</%method>



%#=== @metags collapse ====================================================
<%method collapse><%perl>
  if ( $ePortal::DEBUG ) {
    %ARGS = Params::Validate::validate(@_, {
        title => { type => SCALAR},
        collapse => { type => BOOLEAN, optional => 1},
    });  
  }
  my $D = $gdata{dialog};
  my %args = $m->request_args;

  # The title of a section
  my $title = $ARGS{title};

  # Unique number each collapseable section
  $D->{collapsenum}++;
  my $sectionname = 'dlgcs_' . $D->{collapsenum};
  my $imgname = 'dlgci_' . $D->{collapsenum};
  my $varname = 'dlgcv_' . $D->{collapsenum};
  my $formname = 'dlgcf_' . $D->{collapsenum};

  # a section initially collapsed
  my $collapse = exists $ARGS{collapse} ? 0+$ARGS{collapse} : 1;
  $collapse = $args{$formname} if exists $args{$formname}; # highier priority !!!

</%perl>
%#
%# Строка с треугольником и названием секции
%# 
<tr bgcolor="#E8FFDD">
 <td colspan="2" valign="top">
  <% img(src => '/images/ePortal/3-r.gif', 
         id => $imgname, onClick => "javascript:toggle_$sectionname(null)",
         title => pick_lang(rus => "Щелкните чтобы свернуть/зарвернуть секцию", eng => "Click to collapse"),
         href => 'javascript:void(0);') %>
  &nbsp;&nbsp;&nbsp;
  <a href="javascript:void(0);" 
     onclick="javascript:toggle_<% $sectionname %>(null);"><b><% $title |h %></b></a>
  <input type="hidden" name="<% $formname %>" value="<% $collapse %>">
 </td>
</tr>
%#
%# Сделать невидимым могу только tr, придется завернуть все остальное
%# содержимое во внутреннюю таблицу.
%# 
<tr id="<% $sectionname %>" style="display=inline;"><td colspan="2">
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<% $m->content %>
</table></td></tr>
<script language="JavaScript">
//<!--
var <% $varname %> = <% $collapse ? 'true' : 'false' %>; // true if collapsed
function toggle_<% $sectionname %>(pos) {
  if ( pos == null ) {
    <% $varname %> = ! <% $varname %>;
  } else {
    <% $varname %> = pos;
  }
  if ( <% $varname %> ) { // true if collapsed
    document.all('<% $sectionname %>').style.display = 'none';
    document.all('<% $imgname %>').src = '/images/ePortal/3-r.gif';
    document.all('<% $formname %>').value = 1;
  } else {
    document.all('<% $sectionname %>').style.display = 'inline';
    document.all('<% $imgname %>').src = '/images/ePortal/3-d.gif';
    document.all('<% $formname %>').value = 0;
  }
}
toggle_<% $sectionname %>(<% $varname %>);
var dummy1_<% $imgname %> = new Image();
dummy1_<% $imgname %>.src = "/images/ePortal/3-r.gif";
var dummy2_<% $imgname %> = new Image();
dummy2_<% $imgname %>.src = "/images/ePortal/3-d.gif";
//-->
</script>
</%method>


%#=== @METAGS handle_request ====================================================

<%doc>

=head1 REQUEST HANDLING METHODS 

=head2 handle_request

This the engine of dialog. Call it from C<onStartupRequest> method for 
proper redirect handling.

This method does the following:

=over 4

=item 1 
 
L<restore_or_throw|ePortal::thePersistent::Support> object to edit
 
=item 2 
 
L<htmlSave|htmlsave> parameters from request
 
=item 3 
 
if ok button is pressed then save the object and redirect to 
L<back_url|back_url>

=item 4 
 
if cancel button is pressed then just redirect to L<back_url|back_url>

=back

=over 4

=item * obj

Required. The object to work on it.

=item * objid

This parameter usually passed as request parameter. The ID of object to edit.

=item * callback_htmlSave

Code reference. Called after SELF:htmlSave

 callback_htmlSave => sub {
  my $obj = shift;
  my $args = shift;
 }

=item * callback_validate

Code reference. Called just before updating the object

 callback_validate => sub {
  my $obj = shift;
 }

=item * callback_aftersave

Code reference. Called after the object has been updated or inserted.

 callback_aftersave => sub {
  my $obj = shift;
  my $args = shift;
 }

=back

=cut

</%doc>

<%method handle_request><%perl>
  if ( $ePortal::DEBUG ) {
    %ARGS = Params::Validate::validate(@_, {
      obj => { type => OBJECT, isa => 'ePortal::ThePersistent::Support' },
      objid => { type => SCALAR, optional => 1},
      back_url => { type => SCALAR, optional => 1},
      callback_htmlSave => { type => CODEREF, optional => 1},
      callback_validate=> { type => CODEREF, optional => 1},
      callback_aftersave => { type => CODEREF, optional => 1},
    });  
  }
  my %args = $m->request_args;
  my $obj = $ARGS{obj};
  my $objid = $ARGS{objid} || $args{objid};
  my $back_url = $ARGS{back_url} || $m->comp('SELF:back_url');
  my $callback_htmlSave = $ARGS{callback_htmlSave};
  my $callback_validate = $ARGS{callback_validate};
  my $callback_aftersave = $ARGS{callback_aftersave};

  # restore object to edit
  if ( $objid ) {
    $obj->restore_or_throw($objid);
  }

  # Get default or new values from URL. Do not save the object !
  $m->comp('SELF:htmlSave', obj => $obj);
  if (ref($callback_htmlSave) eq 'CODE') {
    &$callback_htmlSave($obj, \%args);
  }

  # Process BUTTONS
  if ( $m->comp('SELF:isButtonPressed', button => 'ok' ) or 
       $m->comp('SELF:isButtonPressed', button => 'apply' )) {
    my $success = try {
      if (ref($callback_validate) eq 'CODE') {
        &$callback_validate( $obj );
      }
      if ($obj->check_id()) {
          $obj->update;
      } else {
          $obj->insert;
      }
      if (ref($callback_aftersave) eq 'CODE') {
        &$callback_aftersave($obj, \%args);
      }
      1;

    } catch ePortal::Exception::DataNotValid with {
      my $E = shift;
      $session{ErrorMessage} = $E->text;
      0;
    };

    throw ePortal::Exception::Abort(-text => $back_url)
      if $success and $m->comp('SELF:isButtonPressed', button => 'ok' );

  } elsif ( $m->comp('SELF:isButtonPressed', button => 'cancel' )) {
    throw ePortal::Exception::Abort(-text => $back_url);

  } elsif ( $m->comp('SELF:isButtonPressed', button => 'delete' )) {
    throw ePortal::Exception::Abort(-text => href("/delete.htm", 
            objtype => ref($obj),
            objid => $objid,
            done => $back_url));
  }
</%perl></%method>


%#=== @METAGS htmlSave ====================================================
<%doc>

=head2 htmlSave

Safely get attributes values from request and apply them to the object with 
object->htmlSave2(). This method does not updates the object in database. Do 
it yourself.

This method does extra processing for special multipart attributes like 
DateTime, xacl_field, etc...

This method does not updates ID attributes.

=over 4

=item * obj

Object to update.

=back

=cut

</%doc>
<%method htmlSave><%perl>
  if ( $ePortal::DEBUG ) {
    %ARGS = Params::Validate::validate(@_, {
        obj => { type => OBJECT, isa => 'ePortal::ThePersistent::Support'},
    });  
  }
  my %args = $m->request_args;
  my $obj = $ARGS{obj};

  # Save attributes from HTTP request into self
  FIELD:
  foreach my $field ( $obj->attributes_at ) {

      # Date and DateTime fields may be passed as multi-field. See htmlField
      # for details
      my $A = $obj->attribute($field);
      if ( $A->{dtype} =~ /^DateT/oi ) {
          if ( exists $args{$field.'_date'} ) {  # java style
            $args{$field} = $args{$field.'_date'} . ' ' .$args{$field.'_time'};
            delete $args{$field.'_date'};
            delete $args{$field.'_time'};
            next FIELD;
          }

      } elsif ( $A->{dtype} =~ /^Date/oi ) {
          if ( exists $args{$field.'_date'} ) {  # java style
            $args{$field} = $args{$field.'_date'};
            delete $args{$field.'_date'};
            next FIELD;
          }

      } elsif ($field =~ /^xacl_/o) {     # ExtendedACL
          next if ! exists $args{$field};
          if ($args{$field} eq 'uid') { $args{$field} = 'uid:' . $args{$field . '_uid'}; }
          if ($args{$field} eq 'gid') { $args{$field} = 'gid:' . $args{$field . '_gid'}; }
          delete $args{$field . '_uid'};
          delete $args{$field . '_gid'};
          next FIELD;

      }
  }
  $obj->htmlSave2(%args);

</%perl></%method>



%#=== @METAGS isButtonPressed ====================================================
<%doc>

=head2 isButtonPressed

Check is a button was pressed on dialog. 

Every standard dialog button named as C<dlgb_NAME>. If no C<dlgb_NAME> 
parameter exists in request then C<isButtonPressed('ok')> returns true on 
dialog submit.

=over 4

=item * button

A button name to check. 

 icons: q max min edit x
 buttons: ok cancel copy delete apply more

=back

=cut

</%doc>
<%method isButtonPressed><%perl>
  if ( $ePortal::DEBUG ) {
    %ARGS = Params::Validate::validate(@_, {
        button => { type => SCALAR},
    });  
  }
  my $button = $ARGS{button};
  my %args = $m->request_args;

  throw ePortal::Exception::Fatal(-text => 'Unknown button name for isButtonPressed')
    if ($button eq '');

  my $button_pressed;
  $button_pressed = 'ok' if $args{dialog_submit}; # as default

  foreach (keys %args) {
    # All standard dialog buttons named as dlgb_name
    if ( /^dlgb_(.*)$/o) {
      $button_pressed = $1;
      last;
    }
    # Special case. A button named 'submit'
    if ( /^submit/io ) {
      $button_pressed = $_;
      last;
    }
  }

  return $button eq $button_pressed ? 1 : 0;
</%perl></%method>



%#=== @METAGS back_url ====================================================
<%doc>

=head2 back_url

Calculates URL where to return (redirect) from Dialog when a button will 
pressed.

=cut

</%doc>
<%method back_url><%perl>
  my %args = $m->request_args;
  my $back_url = $args{back_url};

  # Get it from referer request header
  if (! $back_url) {
    my $referer_uri = new URI($ENV{HTTP_REFERER}, 'http');
    my $this_uri = new URI($ENV{REQUEST_URI}, 'http');
    $back_url = $ENV{HTTP_REFERER} if $referer_uri->path ne $this_uri->path;
  }

  # last chance
  $back_url = 'index.htm' if ! $back_url;

  return $back_url;
</%perl></%method>


<%doc>

=head1 DATA FLOW

 handle_request()     dialog.mc     
  htmlSave()          dialog.mc      handler DateTime, xacl fields
  htmlSave2()         Support.pm     this called 
  value_from_req()    Support.pm     for each attribute to save
  value()
 update() or insert() Base.pm
  validate()


=head1 AUTHOR

Sergey Rusakov, E<lt>rusakov_sa@users.sourceforge.netE<gt>

=cut

</%doc>
