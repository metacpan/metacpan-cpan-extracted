#!/usr/dim/perl/5.8/bin/perl

# $Id: admin.cgi,v 1.32 2004/09/14 09:08:03 joern Exp $

use strict;
BEGIN {
	$0 =~ m!^(.*)[/\\][^/\\]+$!;    # Win32 Netscape Server Workaround
	chdir $1 if $1;
	require "../etc/default-user.conf";
	require "../etc/newspirit.conf"
}

require $CFG::objecttypes_conf_file;

use CGI;
use Carp;
use CIPP;
use NewSpirit;
use NewSpirit::Passwd;
use NewSpirit::Project;
use NewSpirit::Session;
use NewSpirit::Widget;
use NewSpirit::Prefs;

main: {
	# dieses globale Hash können Module nutzen, um request
	# spezifische Daten abzulegen
	%NEWSPIRIT::DATA_PER_REQUEST = ();
	
	my $q = new CGI;
	print $q->header(-type=>'text/html')
		unless $q->param('no_http_header') == 1;

	eval { main($q) };
	NewSpirit::print_error ($@) if $@;

	%NEWSPIRIT::DATA_PER_REQUEST = ();
}

sub main {
	my $q = shift;
	my $e = $q->param('e');
	
	if ( $e ne '' and $e ne 'login' and $e ne 'check' and $e ne 'changes' ) {
		NewSpirit::check_session_and_init_request ($q);
	}
	
	if ( $e eq '' ) {
		login_form($q);

	} elsif ( $e eq 'login' ) {
		login($q);

	} elsif ( $e eq 'check' ) {
		login_check($q);

	} elsif ( $e eq 'logout' ) {
		NewSpirit::delete_session ($q);
		if ( $q->param('close') ) {
			print "<script>window.close()</script>\n";
		} else {
			login_form($q);
		}

	} elsif ( $e eq 'menu' ) {
		NewSpirit::delete_lock ($q);
		menu($q);

	} elsif ( $e eq 'clone_session' ) {
		NewSpirit::clone_session ($q);
		frameset($q);

	} elsif ( $e eq 'close_window' ) {
		NewSpirit::delete_lock($q);
		NewSpirit::delete_session($q);
		print qq{<script>window.close()</script>};

	} elsif ( $e =~ /^project_(.*)/ ) {
		project_event ($q, $1);

	} elsif ( $e =~ /^user_(.*)/ ) {
		user_event ($q, $1);

	} elsif ( $e =~ /^pref_(.*)/ ) {
		pref_event ($q, $1);
	} elsif ( $e eq 'changes' ) {
		changes($q);
	}
}

sub login_form {
	my $q = shift;
	my ($message) = @_;
	
	my $message_bg_color = $message eq '' ?
		$CFG::BG_COLOR : $CFG::ERROR_BG_COLOR;
	
	my $username = $q->param('username');
	print <<__HTML;
<html>
<head><title>$CFG::window_title</title></head>
<body bgcolor=$CFG::BG_COLOR text=$CFG::TEXT_COLOR
      alink=$CFG::LINK_COLOR link=$CFG::LINK_COLOR
      vlink=$CFG::LINK_COLOR
      onLoad="document.login.username.focus()">

<br>
<img src="$CFG::logo_url">
<br><br>

<form name="login" action="$CFG::admin_url" method="post">
<input type="hidden" name="e" value="login" >

<table $CFG::BG_TABLE_OPTS><tr><td>
<table $CFG::TABLE_OPTS>
  <tr><td>
    $CFG::FONT Username:</font>
  </td><td>
    $CFG::FONT
    <input type="text" name="username" value="$username" size=20>
    </font>
  </td></tr>
  <tr><td>
    $CFG::FONT Password:
    </font>
  </td><td>
    $CFG::FONT
    <input type="password" name="password" size=20 onChange="this.form.submit()">
    </font>
  </td></tr>
  <tr><td colspan=2 align=right>
    $CFG::FONT
    <input type="button" value="Login" onClick="document.login.submit()">
    </font>
  </td></tr>
</table>
</td></tr></table>
</form>

$CFG::FONT
<small>spirit Server Version <b>$CFG::VERSION</b>, CIPP Version <b>$CIPP::VERSION</b></small><br>
<small>See <a href="$CFG::admin_url?e=changes"><b>CHANGES</b></a>file
for recent changes of new.spirit<br></small>
</font>

<table width=50% CELLSPACING=0 CELLPADDING=0>
  <tr><td bgcolor="$message_bg_color" align="center">
    $CFG::FONT_ERROR
    <br>
    <B>$message</B>
    <br>
    &nbsp;
    </FONT>
  </td></tr>
</table>

</body>
</html>
__HTML
}

sub login_check {
	my $q = shift;

	my ($username, $password) = (
		$q->param('username'),
		$q->param('password')
	);
	
	my $ph = new NewSpirit::Passwd ($q);

	if ( not $ph->check_password ($username, $password) ) {
		print "invalid credentials\n";
	} else {
		print "ok\n";
	}
}

sub login {
	my $q = shift;

	my ($username, $password) = (
		$q->param('username'),
		$q->param('password')
	);
	
	my $ph = new NewSpirit::Passwd ($q);

	if ( not $ph->check_password ($username, $password) ) {
		login_form ($q, "Invalid username or password!");
		return;
	}
	
	# unlock passwd file
	$ph = undef;
	
	# read user config
	NewSpirit::read_user_config ($username);

	# now we create a user session
	my $sh = new NewSpirit::Session;
	my $ticket  = $sh->create ($q->remote_addr(), $username);
	my $project = $sh->get_attrib('project');

	# unlock session file
	$sh = undef;

	if ( $CFG::LOGIN_SHOW_LAST_PROJECT ) {
		# check if user has access to this project. If not, 
		# reset project here, otherwise the user is unable
		# to login, because he only sees "access denied"
		# messages
		$ph = new NewSpirit::Passwd ($q);
		$project = '' if not $ph->check_project_access($username, $project) ;
		$ph = undef;
	}

	# put params in query object, frameset() needs them
	$q->param('ticket', $ticket);
	$q->param('project', $project);

	frameset($q);
}

sub frameset {
	my $q = shift;
	
	my $ticket = $q->param('ticket');
	my $project = $q->param('project');
	my $object = $q->param('object');

	my $action_event = '';
	if ( $object ) {
		$action_event = "&e=edit&object=$object";
	}
	
	my $control_url = "$CFG::pbrowser_url?project=$project&ticket=$ticket&e=frameset";
	my $action_url  = "$CFG::object_url?project=$project&ticket=$ticket$action_event";

	if ( not $project ) {
		$action_url = "$CFG::admin_url?ticket=$ticket&e=menu";
	}

	print <<__HTML;
<html>
<head><title>$CFG::window_title</title></head>
<frameset cols="$CFG::FRAMESET" border=1>
  <frame src="$control_url" NAME=CONTROL>
  <frame src="$action_url" name="ACTION">
</frameset>
</html>
__HTML
}

sub menu {
	my $q = shift;
	
	my $username = $q->param('username');
	
	my $passwd_h = new NewSpirit::Passwd ($q);
	my $project_h = new NewSpirit::Project ($q);
	
	my ($projects, $flags);
	if ( $username ne 'spirit' ) {
		($projects, $flags) =
			$passwd_h->get_access_rights ($username);
	} else {
		$flags = {
			'PROJECT' => 1,
			'USER' => 1,
		};
		$projects = $project_h->get_project_list (
			name2desc => 1
		); 
        };

	NewSpirit::std_header (
		page_title => "Main Menu"
	);

	print "<TABLE BORDER=0 CELLPADDING=0 CELLSPACING=0>\n";
	
	# Project menu
	print "<TR><TD VALIGN=top>\n";
	$project_h->main_menu ($q, $projects, $flags);
	print "</TD>\n";

	# vertical blanker
	print "<TD>$CFG::FONT_BIG&nbsp; &nbsp;</FONT></TD>\n";

	# User menu
	print "<TD VALIGN=top>\n";
	if ( $flags->{USER} ) {
		$passwd_h->main_menu ($q, $projects, $flags);
	} else {
		print "&nbsp;\n";
	}
	print "</TD></TR>\n";

	# horizontal blanker

	print "<TR><TD COLSPAN=3>&nbsp;</TD></TR>\n";

	# Account menu
	print "<TR><TD VALIGN=top>\n";
	$passwd_h->account_menu ($q, $projects, $flags);
	print "</TD>\n";

	print "</TABLE>\n";
	
	NewSpirit::end_page();
}

sub project_event {
	my $q = shift;
	my ($event) = @_;
	
	my $project_h = new NewSpirit::Project ($q);
	my $method = "event_$event";
	
	$project_h->$method();
}

sub user_event {
	my $q = shift;
	my ($event) = @_;
	
	my $passwd_h = new NewSpirit::Passwd ($q);
	my $method = "event_$event";
	
	$passwd_h->$method();
}

sub pref_event {
	my $q = shift;
	my ($event) = @_;
	
	my $prefs_h = new NewSpirit::Prefs ($q);
	my $method = "event_$event";
	
	$prefs_h->$method();
}

sub changes {
	my $q = shift;
	
	NewSpirit::std_header (
		page_title => "CHANGES of new.spirit version $CFG::VERSION",
		window_title => "CHANGES of new.spirit version $CFG::VERSION",
	);
	
	print <<__HTML;
$CFG::FONT
<a href="$CFG::admin_url"><b>[ Go back to the login screen ]</b></a>
</font>
<p>
__HTML
	
	print "$CFG::FONT_FIXED<pre>\n";
	open (IN, $CFG::changes_file) or die "can't read $CFG::changes_file";
	while (<IN>) {
		print;
	}
	close IN;

	print "</pre></font>\n";
	NewSpirit::end_page();
}
