%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software
%#
%#
%#----------------------------------------------------------------------------
%# $Layout:
%#    Normal - normal window
%#    Dialog - Dialog window
%#    MenuItems - normal with menu on the left
%#    Popup - popup window
%#    Empty - No widgets (for Errors, Exports)
%#    Nothing - Absolutely not output in autohandler
<%init>
  #
  # Prepare for page construction.
  #
  my $call_next_content = undef;
  my ($location, $Title, $MenuItems);
  my $Layout = 'Normal';

  $m->interp->set_escape(h => \&HTML::Mason::Escapes::basic_html_escape);
  CGI::autoEscape(0);         # turn off CGI euto escaping

  try {
    $ePortal = new ePortal::Server( m => $m ); # Create ePortal Server object
    $ePortal->initialize();                  # this calls dbh and config_load
                                             # may throw DatabaseNotConfigured
    
    # User recognition
    if ($r->connection->user) {
      logline('info', "User ".$r->connection->user." recognized from r->connection->user");
      $ePortal->username($r->connection->user);
    } else {
      my %cookies = Apache::Cookie->fetch;
      my $cookie_value = $cookies{ePortal_auth} ? $cookies{ePortal_auth}->value() : undef;
      my($username, $remoteip, $md5hash) = split(/:/, $cookie_value);
      my $actualremoteip = $r->get_remote_host;
      my $mymd5 = Digest::MD5::md5_hex('13', $username, $remoteip);
      if ( $username ) {
        try {
          throw ePortal::Exception::BadUser(-reason => 'md5_changed')
            if $mymd5 ne $md5hash;
          throw ePortal::Exception::BadUser(-reason => 'ip_changed')
            if $actualremoteip ne $remoteip;

          $ePortal->username($username);
          logline('info', "User $username recognized from cookie");

        } catch ePortal::Exception::BadUser with {
          my $E = shift;
          logline('error', ref($E). ':'. $E->{-reason}. $E->text);
          $session{ErrorMessage} ||= $E->text;
          $ePortal->username(undef);
          $m->scomp('/pv/send_auth_cookie.mc');
        };

      } else {
        $ePortal->username(undef);
      }
    }
      
    $m->scomp("/pv/create_session.mc");         # create persistent Session hash
    eval {
      # Load and create application object
      my $app_name = $m->request_comp->attr('Application');
      $ePortal->Application($app_name) if $app_name;
    };
    warn $@ if $@;

    $location = $m->comp('SELF:onStartRequest', %ARGS);

    # Determine Title and Layout
    $Title = $m->comp("SELF:Title", %ARGS);
    $Title = pick_lang($Title) if ref($Title) eq 'HASH';
    $Layout = $m->request_comp->attr("Layout");


    # MenuItems
    $MenuItems = $m->comp("SELF:MenuItems", %ARGS);
    $MenuItems = $m->scomp("/pv/leftmenu.mc", $MenuItems);
    $Layout = 'MenuItems' if ($Layout eq 'Normal') and $MenuItems;

    # Access control
    my $require_user  = $m->request_comp->attr("require_user");
    my $require_group = $m->request_comp->attr("require_group");
    my $require_admin = $m->request_comp->attr("require_admin");
    my $require_registered = $require_user || $require_group ||
      $require_admin || $m->request_comp->attr("require_registered");

    if ( $require_registered and ! $ePortal->username) {
      throw ePortal::Exception::ACL(-operation => 'require_registered');
    }
    if ($require_user) {
      $require_user = [$require_user] if ref($require_user) ne 'ARRAY';
      my $username = $ePortal->username;
      throw ePortal::Exception::ACL(-operation => 'require_user')
        if ! grep { $_ eq $username } @$require_user;

    } elsif ($require_group) {
      $require_group = [$require_group] if ref($require_group) ne 'ARRAY';
      throw ePortal::Exception::ACL(-operation => 'require_group')
        if ! grep { $ePortal->user->group_member($_) } @$require_group;

    } elsif ($require_admin) {
      throw ePortal::Exception::ACL(-operation => 'require_admin')
        unless $ePortal->isAdmin;

    }


  #===========================================================================
  } catch ePortal::Exception::ACL with {
  #===========================================================================
    my $E = shift;
    logline('info', join(' ',
            ref($E), ref($E->object). ':'. $E->value, $E->text, $E->stacktrace ));
    $call_next_content = $m->scomp('/pv/show_exception_acl.mc', E => $E);
    $Layout = 'Empty';

  #===========================================================================
  } catch ePortal::Exception::Fatal with {
  #===========================================================================
    my $E = shift;
    logline('emerg', join(' ',
            ref($E), ref($E->object). ':'. $E->value, $E->text, $E->stacktrace ));
    $call_next_content =
          $m->scomp('/message.mc', ErrorMessage => "$E") .
          "\n<!-- " . $E->stacktrace . "-->\n";
    $Layout = 'Empty';

  #===========================================================================
  } catch ePortal::Exception::DatabaseNotConfigured with {
  #===========================================================================
    my $E = shift;
    $Layout = 'Empty';
    logline('alert', "Error in DB storage. Need upgrade.");
    $location = '/admin/ePortal_database.htm';

  #===========================================================================
  } catch ePortal::Exception::DBI with {
  #===========================================================================
    my $E = shift;
    $Layout = 'Empty';
    logline('emerg', join(' ',
            ref($E), ref($E->object). ':'. $E->value, $E->text, $E->stacktrace ));
    $call_next_content = $m->scomp('/message.mc',
        ErrorMessage => pick_lang(
          rus => "Ошибка сервера баз данных",
          eng => "SQL server error")) .
          "\n<!-- $E  -->\n" .
          "\n<!-- ".$E->stacktrace."  -->\n";

  #===========================================================================
  } catch ePortal::Exception::DataNotValid with {
  #===========================================================================
    my $E = shift;
    logline('debug', join(' ',
            ref($E), ref($E->object). ':'. $E->value, $E->text, $E->stacktrace ));
    $session{ErrorMessage} = '' . $E;
    $location = undef;

  #===========================================================================
  } catch ePortal::Exception::ObjectNotFound with {
  #===========================================================================
    my $E = shift;
    logline('error', join(' ',
            ref($E), ref($E->object). ':'. $E->value, $E->text, $E->stacktrace ));
    $call_next_content = $m->scomp('/message.mc', ErrorMessage => "$E");
    $location = undef;

  #===========================================================================
  } catch ePortal::Exception::ApplicationNotInstalled with {
  #===========================================================================
    my $E = shift;
    logline('critical', join(' ',
            ref($E), ref($E->object). ':'. $E->value, $E->text, $E->stacktrace ));
    $Layout = 'Empty';
    $call_next_content = $m->scomp('/message.mc', ErrorMessage => "$E");

  #===========================================================================
  } catch ePortal::Exception::FileNotFound with {
  #===========================================================================
    my $E = shift;
    logline('warn', ref($E), ': '. $E->file);
    $Layout = 'Empty';
    $call_next_content = $m->scomp('/message.mc', ErrorMessage => "File ".$E->file." not found");
    #$m->clear_buffer;
    $r->status(404);

  #===========================================================================
  } catch ePortal::Exception::Abort with {
  #===========================================================================
    my $E = shift;
    $location = $E->text || '';   # Finish request. empty but defined

  #===========================================================================
  } catch ePortal::Exception with {
  #===========================================================================
    my $E = shift;
    logline('error', join(' ',
            ref($E), ref($E->object). ':'. $E->value, $E->text, $E->stacktrace ));
    $Layout = 'Normal';
    $call_next_content = $m->scomp('/message.mc', ErrorMessage => "$E");

  #===========================================================================
  } otherwise {
    my $E = shift;
    logline('emerg', 'General exception: ', ref($E), $E);

    if ( UNIVERSAL::can($E, 'rethrow') ) {
      $E->rethrow;
    } else {
      die $E;
    }
  };


  # $location may be empty but defined, and defined and not empty
  if (defined $location) {
    $m->scomp('SELF:cleanup_request');
    if ($location) {
      $m->comp("/redirect.mc", location => $location);
    }
    return OK;
  }

  # Everything after that is HTML!
  # may use attribute ContentType to set any or 
  # set it in onStartRequest() and set attribute to empty value ''
  my $content_type = $m->request_comp->attr("ContentType");
  $r->content_type($content_type) if $content_type;
  $r->send_http_header;
  return if $r->header_only;
</%init>
%#============================================================================
%# START OF HTML
%#============================================================================
% if ($Layout ne 'Nothing') {
<!doctype html public "-//w3c//dtd html 4.0 transitional//en">
<html>
<head>
  <meta name="Author" content="'S.Rusakov' <rusakov_sa@users.sourceforge.net>">
  <meta name="keywords" content="ePortal, WEB portal, organizer, personal organizer, ежедневник, портал">
  <meta name="copyright" content="Copyright (c) 2001-2002 Sergey Rusakov">
  <meta name="Description" content="<% pick_lang(rus => "Домашняя страница ePortal", eng => "Home page of ePortal") %>">
  <title><% $Title %></title>
  <link rel="STYLESHEET" type="text/css" href="/styles/default.css">
  <script language="JavaScript" src="/common.js"></script>
  <& SELF:HTMLhead, %ARGS &>
</head>
<body bgcolor="#FFFFFF" leftmargin="0" rightmargin="0" topmargin="0" bottommargin="0" marginwidth="0" marginheight="0">
%} # end of ($Layout ne 'Nothing')
%
%#
%# =========== SCREEN BEGIN ==================================================
%#
%
% if (grep { $Layout eq $_} (qw/Normal Dialog MenuItems/)) {
  <noindex>
  <& /pv/topmenubar.mc &>
  <& /pv/topappbar.mc, title => $Title &>
  </noindex>
%}
%
% if ($Layout eq 'MenuItems') {
<table width="100%" border=0 cellspacing=0 cellpadding=0><tr>
  <td width="120" valign="top"><% $MenuItems %></td>
  <& /empty_td.mc, width=>1, black => 1 &>
  <& /empty_td.mc, width=>5 &>
  <td width="95%" valign="top">
% }
%
% if ($Layout ne 'Nothing') {
  <& /message.mc &>
% }
%
<%perl>
  $m->flush_buffer;
  try {
    $m->call_next if $call_next_content eq '';

  #===========================================================================
  } catch ePortal::Exception::ACL with {
  #===========================================================================
    my $E = shift;
    logline('info', join(' ',
            ref($E), ref($E->object). ':'. $E->value, $E->text, $E->stacktrace ));
    $call_next_content = $m->scomp('/pv/show_exception_acl.mc', E => $E);

  #===========================================================================
  } catch ePortal::Exception::DBI with {
  #===========================================================================
    my $E = shift;
    logline('emerg', join(' ',
            ref($E), ref($E->object). ':'. $E->value, $E->text, $E->stacktrace ));
    $call_next_content = $m->scomp('/message.mc',
        ErrorMessage => pick_lang(
          rus => "Не могу подключиться к серверу баз данных",
          eng => "Cannot connect to database server")) .
          "\n<!-- $E  -->\n" .
          "\n<!-- ".$E->stacktrace."  -->\n";

  #===========================================================================
  } catch ePortal::Exception::DataNotValid with {
  #===========================================================================
    my $E = shift;
    logline('debug', join(' ',
            ref($E), ref($E->object). ':'. $E->value, $E->text, $E->stacktrace ));
    $session{ErrorMessage} = '' . $E;

  #===========================================================================
  } catch ePortal::Exception::ApplicationNotInstalled with {
  #===========================================================================
    my $E = shift;
    logline('critical', join(' ',
            ref($E), ref($E->object). ':'. $E->value, $E->text, $E->stacktrace ));
    $call_next_content = $m->scomp('/message.mc', ErrorMessage => "Application $E is not installed");

  #===========================================================================
  } catch ePortal::Exception::FileNotFound with {
    my $E = shift;
    logline('warn', ref($E), ': '. $E->file);
    $Layout = 'Empty';
    $r->status(404);
    #$m->clear_buffer;
    $call_next_content = $m->scomp('/message.mc', ErrorMessage => "File ".$E->file." not found");

  #===========================================================================
  } catch ePortal::Exception::ObjectNotFound with {
  #===========================================================================
    my $E = shift;
    logline('error', join(' ',
            ref($E), ref($E->object). ':'. $E->value, $E->text, $E->stacktrace ));
    $call_next_content = $m->scomp('/message.mc', ErrorMessage => "$E");

  #===========================================================================
  } catch ePortal::Exception with {
  #===========================================================================
    my $E = shift;
    logline('error', join(' ',
            ref($E), ref($E->object). ':'. $E->value, $E->text, $E->stacktrace ));
    $call_next_content = $m->scomp('/message.mc', ErrorMessage => "$E");

  #===========================================================================
  } otherwise {
    my $E = shift;

      # compilation error goes here
    logline('emerg', 'General exception: ', "$E");
    $call_next_content = $m->scomp('/message.mc', ErrorMessage => "System error. See error_log for details.");
    if ( UNIVERSAL::can($E, 'rethrow') ) {
      $E->rethrow;
    } else {
      die $E;
    }
  };

</%perl>
<% $call_next_content %>
%
%#============================================================================
%# AFTER THE call_next
%#============================================================================
% if ($Layout eq 'MenuItems') {
</td></tr></table>
% }
%
% if (grep { $Layout eq $_} (qw/Normal Dialog MenuItems/)) {
 <& /empty_table.mc, black => 1, height => 1 &>
 <& SELF:Footer &>
%}
%
%#============================================================================
%# END OF SCREEN
%#============================================================================
% if ($ePortal->username and grep { $Layout eq $_} (qw/Normal MenuItems/)) {
<Iframe Name="Alerter_IFrame" scrolling="no" src="/frame_alerter.htm" width="0" height="0" align="right" border="0" noresize>
</Iframe>
% }
%
% if ($Layout ne 'Nothing') {
</body>
</html>
% }
%#============================================================================
%# CLEANUP BLOCK
%#============================================================================
<& SELF:cleanup_request &>
%
%#
%# =========== SCREEN END ====================================================
%#
% return;   # Stop output empty lines to client


%#=== @METAGS attr ===========================================================
<%attr>
Title       => "ePortal v.$ePortal::Server::VERSION. Home page"
Layout      => 'Normal'
Application => 'ePortal'
ContentType => 'text/html'

dir_enabled => 1
dir_nobackurl => 1
dir_sortcode => undef
dir_description => \&ePortal::Utils::filter_auto_title
dir_columns => [qw/icon name size modified description/]
dir_include => []
dir_exclude => []
dir_title => 'default'

require_registered => undef
require_user => undef
require_group => undef
require_admin => undef
require_sysacl => undef
</%attr>




%#=== @METAGS methods_prototypes =============================================
<%method HTMLhead><%perl>
  my $Layout = $m->request_comp->attr("Layout");
  if ( $Layout eq 'Dialog' ) {
    $m->print(qq{<META NAME="Robots" CONTENT="noindex,nofollow">\n});
  }
</%perl></%method>
<%method MenuItems><%perl> return []; </%perl></%method>
<%method onStartRequest></%method>
<%method Title><%perl>return $m->request_comp->attr("Title");</%perl></%method>


%#=== @metags Footer ====================================================
<%method Footer>
<span class="copyright">
ePortal v<% $ePortal::Server::VERSION %> &copy; 2000-2004 S.Rusakov
<br>
<& /inset.mc, page => "/autohandler.mc", number => 9 &>
</span>

</%method>


%#=== @METAGS cleanup_request ====================================================
<%method cleanup_request><%perl>
  $ePortal->cleanup_request;
  $m->scomp('/pv/destroy_session.mc');
  $ePortal = undef;

</%perl></%method>

%#=== @METAGS eng_rus ====================================================
<%method eng><% $ePortal->language eq 'eng' or $ePortal->language eq '' ? $m->content : undef %></%method>
<%method rus><% $ePortal->language eq 'rus' ? $m->content : undef %></%method>

<%doc>

=head1 NAME

autohandler.mc - Base Mason component


=head1 SYNOPSIS

autohandler.mc is base Mason component for entire ePortal site.






=head1 ATTRIBUTES

Attributes are defined via E<lt>attrE<gt> mason tag:

 <%attr>
 Attribute => value
 </%attr>


=head2 Title

This is title for the page. This title is used for E<lt>TITLEE<gt> HTML tag
and displayed at top of every ePortal's page.

This attribute is used for static Title. For dynamic Title see C<Title> method


=head2 Popup

May be 1 or 0. Default is 0.

Used for popup windows. No windows caption, no APP bar, no menus.






=head2 Directory browsing

There are some attributes to control directory browsing process. Browsing
is go when no index.htm file in directory.



=head3 dir_enabled

Enable or disable directory browsing. Default is 1. Is browsing is disabled
then redirect to /errors/not_found.htm is done.



=head3 dir_nobackurl

Show or not C<..> at top of list of files.



=head3 dir_sortcode

Should be sub ref. Two arguments ($a,$b) are passed to sub which both are
absolute filenames.


=head3 dir_description

How to discover a description of a file? May be HASH with filenames or sub
ref. Two arguments C<(absolute_filename,filename)> are passed to sub.

The default is C<\&ePortal::Utils::filter_auto_title>


=head3 dir_columns

How many columns and which to show? This is array ref. Possible values are:
/icon name size modified description/



=head3 dir_include,dir_exclude

Array ref with regexs. First all dir_include regexs work then dir_exclude.
Default is to include all files.

=head3 dir_title

How to title the directory listing? Default is directory name.





=head2 Access control

You always may restrict access to some pages with a help of .htaccess. Use
C<require> directives to to this.

Here is another way to do this. You may use the following attributes in
pages or directory autohandlers to restrict access to some parts of your
site.

Attributes are processed in given order. If any of them are true then
access is allowed else redirect is made to /errors/require_xxx.htm page.

=head3 require_registered => boolean

Requre user to be registered. Deny access for anonymous users.

=head3 require_user => [ ]

Require user to be registered and be listed. Argument if array ref to list
of valid user names.

=head3 require_group => [ ]

Require user to be registered and be member of a group. Argument if array ref to list
of valid group names.

=head3 require_admin => boolean

Require user to be registered and be an admin.















=head1 METHODS TO OVERLOAD

You may overload some autohandler's method to add more functionality to a
page.

 <%method method_name>
 .. your code goes here
 return "something";
 </%method>

Overloaded parent can be called as

 <& PARENT:method_name, %ARGS &>


=head2 HTMLhead

Add any HTML text to put in E<lt>HEADE<gt> section of HTML page.




=head2 onStartRequest

This method is called just after request processing preparation (check
user, etc.) but before any content is sent to client. This method is useful
for client events processing and handling redirects.

Any string returned is passed to redirect.mc to do external redirect.



=head2 Title

This is the same functionality as C<Title> attribute. This method is used
to make the Title be dynamic not static.




=head2 Footer

This is very last part of screen. Useful to show copyright messages



=head2 MenuItems

This method is used to show a menu on the left side of the screen. It
returns an array or pairs.

 <% method MenuItems>
 % return [
   ['menu1' => 'http://...'],
   ['---' => '---'],
   ['html' => '<b>this is HTML</b>']
  ];
 </%method>

Every pair may be any of the following

=over 4

=item * ['title','URL']

Used to make usual menu item

=item * ['---','---']

Make a horizontal separator 1 pixel height

=item * ['require-user','username']

Require C<username> to be registered to see next items.

=item * ['require-group','groupname']

Require the user to be member to the C<groupname> to see next items.

=item * ['require-none','']

Turns off any restriction on user or group to see next items.

=item * ['html','any HTML text']

This pair is used to produce any HTML text at this point.

=item * ['img','http://www/images/file.gif']

Just insert an image at this point

=item * ['',5]

Insert blank row 5 pixels width.

=back





=head1 COMMON URL ARGUMENTS

Some arguments names are reserved for internal purposes. Here are:

=over 4

=item * objid

Object identifier. The ID of the current object to work with it.

=item * objtype

Type of the object. It means ref($object) in Perl.


=item * cal_xxx

Reserved for C<calendar> component

=item * dlg_xxx,dlgb_xxx

Reserved for Dialog controls and buttons.

=item * list_xxx

Reserved for C<list> component.

=back


=head1 AUTHOR

Sergey Rusakov, E<lt>rusakov_sa@users.sourceforge.netE<gt>

=cut

</%doc>
