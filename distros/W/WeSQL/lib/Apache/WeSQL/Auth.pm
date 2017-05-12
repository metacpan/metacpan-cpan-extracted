package Apache::WeSQL::Auth;

use 5.006;
use strict;
use warnings;
use lib(".");
use lib("..");

use Apache::WeSQL qw(:all);
use Apache::WeSQL::SqlFunc qw(:all);
use Apache::WeSQL::Journalled qw(:all);

use Apache::Constants qw(:common);
require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	jLogout jLoginForm jLogin authenticate
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );

our $VERSION = '0.53';

# Preloaded methods go here.
############################################################
# authenticate
# Almost every call to an url passes through this sub (there is a line
# in AppHandler.pm that makes sure of this). This sub checks if
# a user is properly authenticated, and if not, redirects the request
# to jloginform.wsql, passing the redirdest along. If the user is properly
# authenticated, this sub does nothing.
############################################################
sub authenticate {
	my $dbh = shift;
	my $superuserdir = shift;
	my $authsuper = shift;
	my @logincheck = (0);
	my ($redirstr,$sql) = ('','','');
	# Superuser directory or not?
	my $r = Apache->request;
	&Apache::WeSQL::log_error("$$: Auth.pm: authenticate: called with sudir: $superuserdir, authsuper: $authsuper and uri: " . $r->uri) if ($Apache::WeSQL::DEBUG);
	$Apache::WeSQL::cookies{id} = -1 if (!defined($Apache::WeSQL::cookies{id}));
	$Apache::WeSQL::cookies{hash} = -1 if (!defined($Apache::WeSQL::cookies{hash}));
	$redirstr = 'jloginform.wsql?redirdest=';
	if (($ENV{REQUEST_URI} =~ /^$superuserdir/) && ($authsuper == 1)) {
		$redirstr = $superuserdir . $redirstr;
		$sql = "select hash from logins,users where logins.userid=users.id and userid='$Apache::WeSQL::cookies{su}' " . 
						"and hash='$Apache::WeSQL::cookies{hash}' and logins.status='1' and users.status='1' and users.superuser='1'";
		&Apache::WeSQL::log_error("$$: Auth.pm: authenticate: sudir requested, authsuper=1, redirstr: $redirstr") if ($Apache::WeSQL::DEBUG);
	} else {
		$sql = "select hash from logins where userid='$Apache::WeSQL::cookies{id}' and hash='$Apache::WeSQL::cookies{hash}' and status='1'";
		&Apache::WeSQL::log_error("$$: Auth.pm: authenticate: no sudir requested and/or authsuper=1, redirstr: $redirstr") if ($Apache::WeSQL::DEBUG);
	}
	if (($ENV{REQUEST_URI} =~ /^$superuserdir/) && ($authsuper != 1)) {	# $authsuperuser is disabled in WeSQL.pl, so no logging in as a superuser!
		my $request_uri = $ENV{REQUEST_URI};
		$request_uri ||= "";
		my $escaped = CGI::escape($request_uri);
		&Apache::WeSQL::log_error("$$: Auth.pm: authenticate: XXX redir to: $redirstr$escaped REQUEST_URI: $request_uri") if ($Apache::WeSQL::DEBUG);
		&Apache::WeSQL::redirect($redirstr . $escaped);
	}
	# Check if this request comes from a user that is logged in!
	@logincheck = &sqlSelect($dbh,$sql);
	if (!defined($logincheck[0]) || ($Apache::WeSQL::cookies{hash} ne $logincheck[0])) {
		my $request_uri = $ENV{REQUEST_URI};
		$request_uri ||= "";
		my $escaped = CGI::escape($request_uri);
		&Apache::WeSQL::log_error("$$: Auth.pm: authenticate: redir to: $redirstr$escaped REQUEST_URI: $request_uri") if ($Apache::WeSQL::DEBUG);
		if ($request_uri =~ /jloginform\.wsql\?redirdest=.*$/) {	# Circular redirect!!
			&Apache::WeSQL::Journalled::jErrorMessage("Error on the server (perpetual redirect). Please contact the webmaster!","$$: Auth.pm: authenticate: Perpetual redirect, redirecting $request_uri to jloginform.wsql",1);
		} else {
			&Apache::WeSQL::redirect($redirstr . $escaped);
		}
	}
}

############################################################
# loggedin
# loggedin return 1 when the user is logged in and 0 when (s)he is not.
############################################################
sub loggedin {
	my $dbh = shift;
	my $sql = "select hash from logins where userid='$Apache::WeSQL::cookies{id}' and hash='$Apache::WeSQL::cookies{hash}' and status='1'";
	if (defined($Apache::WeSQL::cookies{id}) && defined($Apache::WeSQL::cookies{hash})) {
		my @logincheck = &sqlSelect($dbh,$sql);
		if (defined($logincheck[0]) && ($Apache::WeSQL::cookies{hash} eq $logincheck[0])) {
			return 1;
		}
	}
	return 0;
}

############################################################
# jLogout
# jLogout logs a user out, and redirects him/her to jloginform.wsql, with
# / as the destination for successfull logins, or another destination 
# if redirdest is specified
############################################################
sub jLogout {
	my $dbh = shift;
	&sqlUpdate($dbh,"logins","status='0'","hash='$Apache::WeSQL::cookies{hash}'");
	my $request_uri = $Apache::WeSQL::params{redirdest};
	$request_uri ||= "/";
	my $escaped = CGI::escape($request_uri);
	&Apache::WeSQL::redirect($request_uri);
}

############################################################
# jLogin
# jLogin does the actual logging in of the user (if the credentials are correct).
# This involves setting 2 cookies, and adding a record to the 'logins' table
# in the database. If the credentials are wrong, the user is redirected to 
# jloginform.wsql
############################################################
sub jLogin {
	my $dbh = shift;
	my $authsuperuserdir = shift;
	my $ok = 0;
	my @logincheck;
	my $type = 'id';	# By default we are in the 'ordinary' part of the application
	# But if redirdest matches a directory in the 'superuser' part, then we are trying to log into the superuser part!
	$type = 'su' if ($Apache::WeSQL::params{redirdest} =~ /^$authsuperuserdir/);	
	&Apache::WeSQL::log_error("$$: Auth.pm: jLogin: logging user in (type: $type)") if ($Apache::WeSQL::DEBUG);
	if (defined($Apache::WeSQL::params{login}) && defined($Apache::WeSQL::params{passwd})) {
		@logincheck = &sqlSelect($dbh,"select id,login from users where login='$Apache::WeSQL::params{login}' and password='$Apache::WeSQL::params{passwd}' and status='1' and active='1'");
		$ok = 1 if (defined($logincheck[0]));
	}
	if (!$ok) {
		&Apache::WeSQL::log_error("$$: Auth.pm: jLogin: wrong password!") if ($Apache::WeSQL::DEBUG);
		&sqlGeneric($dbh,"UPDATE logins set status='0' where userid='$Apache::WeSQL::cookies{$type}'") if defined($Apache::WeSQL::cookies{$type});
		my $request_uri = $Apache::WeSQL::params{redirdest};
  	$request_uri ||= "index.wsql";
	  my $escaped = CGI::escape($request_uri);
  	&Apache::WeSQL::redirect('jloginform.wsql?redirdest=' . $escaped);
	} else {
		my $request_uri = $Apache::WeSQL::params{redirdest};
  	$request_uri ||= "index.wsql";
		&Apache::WeSQL::log_error("$$: Auth.pm: jLogin: right password!") if ($Apache::WeSQL::DEBUG);
		&sqlGeneric($dbh,"UPDATE logins set status='0' where userid='$logincheck[0]'");
		my $hashstr = join ('', ('.', '/', 0..9, 'A'..'Z', 'a'..'z')[rand 64, rand 64, rand 64, rand 64, rand 64, rand 64, rand 64, rand 64, rand 64, rand 64, rand 64, rand 64, rand 64, rand 64, rand 64, rand 64]);
		my @cols = ('userid','hash');
		my @vals = ($logincheck[0],$hashstr);
		jAdd($dbh,"logins",\@cols,\@vals,'id',$logincheck[0]);
		print "HTTP/1.1 302 Redirect\r\n";
		print "Location: $request_uri\r\n";
		print "Set-Cookie: id=$logincheck[0]\r\n";
		print "Set-Cookie: hash=$hashstr\r\n";
		print "Content-type:text/html\r\n\r\n";
		print << "EOF";
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<HTML><HEAD>
<TITLE>302 Found</TITLE>
</HEAD><BODY>
<H1>Found</H1>
The document has moved <A HREF="$request_uri">here</A>.<P>
<HR>
<ADDRESS>Apache Server</ADDRESS>
</BODY></HTML>
    
EOF
		exit;
	}
}

############################################################
# jLoginForm
# jLoginForm displays the login form, making use of the layout.cf file
############################################################
sub jLoginForm {
	my $body;
	my $cookieheader = shift;
  my $dd = localtime();
	my %layout = &Apache::WeSQL::readLayoutFile('layout.cf');
	# Protect against 'Use of uninitialized value in concatenation...' errors in the log files!
	$layout{listheader} ||= ''; $layout{listbody} ||= ''; $layout{liststarttable1} ||= ''; $layout{liststarttable2} ||= '';
	$layout{publiclogon} ||= ''; $layout{liststoptable} ||= ''; $layout{listfooter} ||= ''; $layout{loginformcaption} ||= '';
	$body = <<EOF;
HTTP/1.1 200 OK
Date: $dd
Server: Apache
EOF
	$body .= "$cookieheader\r\n" if (defined($cookieheader));
	$body .= <<EOF;
Connection: close
Content-type: text/html

$layout{listheader}
<title>Log In</title>
$layout{listbody}
$layout{liststarttable1}
<center><b>$layout{loginformcaption}</b></center>
$layout{liststarttable2}
$layout{loginform1}
<input type=hidden name=redirdest value="$Apache::WeSQL::params{redirdest}">
$layout{loginform2}
$layout{publiclogon}
$layout{loginform3}
$layout{liststoptable}
$layout{listfooter}

EOF
	return($body,0);
}

1;
__END__

=head1 NAME

Apache::WeSQL::Auth - Auth subs for a journalled WeSQL application

=head1 SYNOPSIS

  use Apache::WeSQL::Auth qw( :all );

=head1 DESCRIPTION

This module contains the code necessary for authentication support in WeSQL. Some form
of authentication support, that is, because you could easily implement your own.

This module is called from AppHandler.pm, and WeSQL.pm

This module is part of the WeSQL package, version 0.53

(c) 2000-2002 by Ward Vandewege

=head2 EXPORT

None by default. Possible: jLogout jLoginForm jLogin authenticate

=head1 AUTHOR

Ward Vandewege, E<lt>ward@pong.beE<gt>

=head1 SEE ALSO

L<Apache::WeSQL>, L<Apache::WeSQL::AppHandler>, L<Apache::WeSQL::Journalled>, L<Apache::WeSQL::Display>

=cut
