#!/usr/bin/perl
##
#
# copyright 2001 D. Scott Barninger <barninger@fairfieldcomputers.com>
# licensed under the GNU General Public License ver. 2.0
# see the accompaning LICENSE file
##

use strict;
use CGI;
use WWW::Authenticate;

################################################################################
# Configuration Section
################################################################################
my $database = "";
my $host = "localhost";
my $sql_username = "";
my $sql_password = "";
my $sql_table = "auth_test";
my $program_name = "cgi_authenticate.cgi";

################################################################################

my $query = new CGI;
my $dsn = "DBI:mysql:database=$database;host=$host";

Main();

sub Main {
	my $action = $query->param('action');
	if($action eq "Login") {
		my $username = $query->param("username");
		my $password = $query->param("password");
		if (!Login($dsn,$sql_username,$sql_password,$sql_table,$username,$password)) {
			ResultScreen("Login did not succeed.");
		}
		else {
			ResultScreen("Login succeeded.");
		}
	}
	elsif($action eq "CheckAuth") {
		my ($session,$uid) = GetSessionCookie();
		if(!CheckAuth($dsn,$sql_username,$sql_password,$sql_table,$session)) {
			ResultScreen("Authentication did not succeed.");
		}
		else {
			ResultScreen("Authentication succeeded.");
		}
	}
	elsif($action eq "Logout") {
		my ($session,$uid) = GetSessionCookie();
		if(!Logout($dsn,$sql_username,$sql_password,$sql_table,$session,$uid)) {
			ResultScreen("LogOut did not succeed.");
		}
		else {
			LoginScreen();
		}
	}
	else {
		LoginScreen();
	}
}


sub LoginScreen {
	print "Content-type: text/html \n\n";
	print qq|
	<html>
	<head>
	<title> WWW::Authenticate Test Script</title>
	</head>
	<body>
	<form method="post" action="$program_name" enctype="multi-part/form-data">
	<input type="hidden" name="action" value="Login">
	<table border="0">
		<tr>
			<td colspan="2" align="center">Login</td>
		</tr>
		<tr>
			<td>User Name:</td>
			<td><input type="text" name="username"></td>
		</tr>
		<tr>
			<td>Password:</td>
			<td><input type="password" name="password"></td>
		</tr>
		<tr>
			<td colspan="2"><input type="submit" value="Submit"></td>
		</tr>
	</table>
	</form>
	</body>
	</html>
|;
}

sub ResultScreen {
	my ($message,$header) = @_;

	print "Content-type: text/html \n\n";

	print qq|
	<html>
	<head>
	<title> WWW::Authenticate Test Script</title>
	</head>
	<body>
	<p>$message</p>
	<form method="post" action="$program_name" enctype="multi-part/form-data">
	<input type="hidden" name="action" value="CheckAuth">
	<input type="submit" value="Check Authorization">
	</form>
	<form method="post" action="$program_name" enctype="multi-part/form-data">
	<input type="hidden" name="action" value="Logout">
	<input type="submit" value="LogOut">
   </form>
	</body>
	</html>|;
}
