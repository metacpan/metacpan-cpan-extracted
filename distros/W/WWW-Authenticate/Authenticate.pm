###############################################################################
# Perl Module WWW::Authenticate
#
# copyright 2001 D. Scott Barninger <barninger@fairfieldcomputers.com>
# copyright 2001 Chris Fleizach <chris@fightliteracy.com>
# licensed under the GNU General Public License ver. 2.0
# see the accompaning LICENSE file
###############################################################################

package WWW::Authenticate;

use strict;

BEGIN {
	use vars qw($VERSION @ISA @EXPORT);
	use DBI;

	require Exporter;

	@ISA = qw(Exporter);

	# exported functions
	@EXPORT = qw(
		&CheckAuth 
		&GetSessionCookie 
		&Login
		&Logout);

	$VERSION = '0.6.0';
}

# package globals
use vars qw($dbh);
$dbh = "";


################################################################################
# FUNCTION:  CheckAuth($dsn,$sql_username,$sql_password,$sql_table,$session)
# DESCRIPTION: authenticates the user using current session number
################################################################################
sub CheckAuth
{
	my ($dsn,$sql_username,$sql_password,$sql_table,$session) = @_;
	my $SQL	= qq| select session from $sql_table where session = "$session" |;
	$dbh = Connect($dsn,$sql_username,$sql_password);
	my $sth = DatabaseQuery($dbh,$SQL);
	my ($t_session) = $sth->fetchrow_array();
	$dbh->disconnect();

	if (!$t_session) {
		return 0;
	}
	else {
		return 1;
	}
}


################################################################################
# FUNCTION:  Cleanup
# DESCRIPTION: To be called when exiting
################################################################################
sub Cleanup
{
	$dbh->disconnect();
	exit(0);
}

################################################################################
# FUNCTION:  Connect($dsn,$sql_username,$sql_password)
# DESCRIPTION: Connect to the MySQL database
################################################################################
sub Connect
{
	my ($dsn,$sql_username,$sql_password) = @_;
	$dbh = DBI->connect($dsn,$sql_username,$sql_password) 
		or ErrorMessage("Could not connect to the database."); 
	return $dbh;
}

################################################################################
# FUNCTION:  CreateSession
# DESCRIPTION: gets info in cookies
################################################################################
sub CreateSession
{ 
	my $size=int(rand(256)+255);
	my $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
	my @array= split(//,$chars);
	my @dots = ();
	while($size--){
		push @dots,$array[rand(@array)];
	}

	my $line = "";
	foreach (@dots) {
		if (int(rand(time^$$)) % 2 == 0) {
			$line .= $_;
		}
	}

	my $add = "";
	for (my $k = 0; $k < 40; $k++) {
		my $n1 = int(rand(length($line)));
		my $sub = substr($line,$n1,1);
		$add .= "$sub$n1";
	}

	my $session = int(rand(99999999)) . crypt(time*rand(999),"YT") . $add . 
		crypt(rand(730300334) * rand(31443),"EP"); 
	return $session;
}
################################################################################
# FUNCTION:  DatabaseQuery($dbh,$SQL)
# DESCRIPTION:  Allows for a query to the database, for a general query
#               If they didn't send a where clause, we have to ignore it
#               Returns a sth handle so that the user can define what the sth
#               fetchrow_array should return
################################################################################
sub DatabaseQuery
{
	my ($dbh,$SQL) = @_;

	my $sth = $dbh->prepare($SQL) || ErrorMessage($SQL);
	$sth->execute() || ErrorMessage($SQL);
	return $sth;
}

################################################################################
# FUNCTION:  ErrorMessage
# DESCRIPTION: When something fails should print the error message that is
#              passed and we also output to a log. Then we call Cleanup and
#              exit the program
################################################################################
sub ErrorMessage
{
	my $message = shift;
	print qq|$message\n$DBI::err ($DBI::errstr)|;
	Cleanup();
}

################################################################################
# FUNCTION:  GetSessionCookie
# DESCRIPTION: gets info in cookies
################################################################################
sub GetSessionCookie
{ 
	use CGI qw/:standard/;
	use CGI::Cookie;
	# fetch existing cookies
	my %cookies = fetch CGI::Cookie;
	my ($session,$id);
	if ($cookies{'session'}) { $session = $cookies{'session'}->value; }
	if ($cookies{'id'}) { $id = $cookies{'id'}->value; }
	return ($session,$id);
}

################################################################################
# FUNCTION:  Login($dsn,$sql_username,$sql_password,$sql_table,$username,$password)
# DESCRIPTION: The user will log in, sending the username and password
################################################################################
sub Login
{
	my ($dsn,$sql_username,$sql_password,$sql_table,$username,$password) = @_;
	my $SQL	= qq| select id from $sql_table where user_name = "$username" and
	              password = "$password" |;
	$dbh = Connect($dsn,$sql_username,$sql_password);
	my $sth = DatabaseQuery($dbh,$SQL);
	my ($uid) = $sth->fetchrow_array();

	# if we pass this condition, the user has logged in, so retrieve information
	if (!$uid) {
		$dbh->disconnect();
		return 0;  
	}
	else {
		$dbh->disconnect();
		LoginTheUser($dsn,$sql_username,$sql_password,$sql_table,$uid);
	}
}

################################################################################
# FUNCTION:  LoginTheUser
# DESCRIPTION: process screen
################################################################################
sub LoginTheUser
{
	my ($dsn,$sql_username,$sql_password,$sql_table,$uid) = @_;
	my $session = CreateSession();
	$dbh = Connect($dsn,$sql_username,$sql_password);
	my $SQL = qq| update $sql_table set session="$session" where id = "$uid" |;
	my $sth = DatabaseQuery($dbh,$SQL);
	SetSessionCookie($session,$uid);
	$dbh->disconnect();
	return 1;
}

################################################################################
# FUNCTION:  Logout($dsn,$sql_username,$sql_password,$sql_table,$session,$uid)
# DESCRIPTION: The user will be logged out deleting the session value in the DB
################################################################################
sub Logout
{
	my ($dsn,$sql_username,$sql_password,$sql_table,$session,$uid) = @_;
	my $SQL = qq| SELECT session FROM $sql_table WHERE session = "$session" AND
		id = "$uid" |;
	$dbh = Connect($dsn,$sql_username,$sql_password);
	my $sth = DatabaseQuery($dbh,$SQL);
	my ($db_session) = $sth->fetchrow_array();
	if (!$db_session) {
		$dbh->disconnect();
		return 0;  
	}
	else {	
		my $SQL = qq| update $sql_table set session="NULL" where session = "$session"
				and id = "$uid" |;

		my $sth = DatabaseQuery($dbh,$SQL);
		$dbh->disconnect();
	}
}

################################################################################
# FUNCTION:  SetSessionCookie
# DESCRIPTION: sets session of admin with a cookie
################################################################################
sub SetSessionCookie
{
	my ($session,$id) = @_;
	use CGI qw/:standard/;
	use CGI::Cookie;
	my $cookie1 = new CGI::Cookie(-name=>'session',-value=>$session);
	my $cookie2 = new CGI::Cookie(-name=>'id',-value=>$id);

	print header(-Cookie=>[$cookie1,$cookie2],-type=>"text/html");
}

1;
__END__

=head1 NAME

WWW::Authenticate - Perl extension for authenticating users

=head1 SYNOPSIS

  use WWW::Authenticate;

  # using $username and $password obtained from web page login form
  # authenticate the username/password combo and set a session cookie
  Login($dsn,$sql_username,$sql_password,$sql_table,$username,$password))

  # before allowing the user to do whatever we want to control, retrieve his
  # current session  & user ID number from cookie and validate the session number
  my($session,$uid) = GetSessionCookie();
  if(!CheckAuth($dsn,$sql_username,$sql_password,$sql_table,$session)) {
	# we aren't logged in correctly
  }

	# logout the user
	Logout($dsn,$sql_username,$sql_password,$sql_table,$session,$uid)



=head1 DESCRIPTION

Authenticate provides a method to easily authenticate web site users using
session cookies and a MySQL user database.

Requires the CGI::Cookie module and MySQL.

=head1 AUTHOR

D. Scott Barninger, barninger@fairfieldcomputers.com
Chris Fleizach, chris@fightliteracy.com

Licensed under the GNU General Public License ver. 2.0
 see the accompaning LICENSE file

=head1 SEE ALSO

perl(1).

=cut
