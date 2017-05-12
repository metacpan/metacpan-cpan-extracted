#!/usr/bin/perl

########################################################################
# This is a very simple example of the usage of WWW::Authen::Simple.
# Please see the documentation for further information.
#     ie. perldoc WWW::Authen::Simple
#
########################################################################
# In order to run this script:
#  1)you will need to setup your database tables. Example database
#    scheme's are available in the examples/ subdirectory.
#  2)you will want to add some users and groups. A sample addusers
#    script has been provided in the examples/ subdirectory.
#  3)you'll need to move this to your cgi-bin or mod_perl directory,
#    and make sure that it's executable and readable by your webserver.
#  4)change the globals below to match your situation.
#
########################################################################

my $cookie_domain = 'test.com';
my $db_user = 'test';
my $db_pass = '';
my $db_dbase = 'test';
my $db_driver = 'mysql';
my $db_host = 'localhost';

use strict;
use CGI qw(:standard);
use DBI;
use WWW::Authen::Simple;

my $cgi = new CGI;
my $datasource = join(':', ('dbi',$db_driver,$db_dbase,$db_host));
my $dbi = DBI->connect( $datasource, $db_user, $db_pass )
	or die "Can't connect to $db_driver dbase $db_dbase on $db_host: $DBI::errstr\n";

&main;

sub main
{
	my $auth = WWW::Authen::Simple->new(
		db	=> $dbi,
		cookie_domain	=> $cookie_domain
		);
	my $logout   = $cgi->param('logout');
	my $user     = $cgi->param('user');
	my $password = $cgi->param('password');

	# logout if they send a logout form element.
	$auth->logout() if $logout;
	# login. If they don't supply user/pass, it'll try the cookies
	$auth->login($user,$password);

	# decide what to do
	if ($auth->logged_in())
	{	# they're logged in

		# if they're an admin, give them this page
		if ($auth->in_group('admin'))
		{
			&print_admin_page();

		# if they can write to db1, give them this page
		} elsif ($auth->in_group('db1','w')) {
			&print_write_page();

		# if they can read from db1, give them this page
		} elsif ($auth->in_group('db1','w')) {
			&print_read_page();

		# if they can read/write to db1, give them this page
		} elsif ($auth->in_group('db1','rw')) {
			&print_readwrite_page();

		# otherwise, tell them they are not authorized to access db1
		} else {
			&print_not_authorized();

		}

	} else {
		&print_login_form;
	}
}

sub print_admin_page
{
	print header;
	print <<EOF
<HTML><HEAD></HEAD><BODY>
You are an admin, congrats.
<FORM>
<INPUT TYPE=submit name=logout value=Logout>
</FORM>
</BODY></HTML>
EOF

}

sub print_write_page
{
	print header;
	print <<EOF
<HTML><HEAD></HEAD><BODY>
You are allowed to write to the db1 resource
<FORM>
<INPUT TYPE=submit name=logout value=Logout>
</FORM>
</BODY></HTML>
EOF

}

sub print_read_page
{
	print header;
	print <<EOF
<HTML><HEAD></HEAD><BODY>
You are allowed to read from the db1 resource
<FORM>
<INPUT TYPE=submit name=logout value=Logout>
</FORM>
</BODY></HTML>
EOF

}

sub print_readwrite_page
{
	print header;
	print <<EOF
<HTML><HEAD></HEAD><BODY>
You can both read and write to the db1 resource
<FORM>
<INPUT TYPE=submit name=logout value=Logout>
</FORM>
</BODY></HTML>
EOF

}

sub print_not_authorized
{
	print header;
	print <<EOF
<HTML><HEAD></HEAD><BODY>
<B>You are not authorized to access the db1 resource</B>
<FORM>
<INPUT TYPE=submit name=logout value=Logout>
</FORM>
</BODY></HTML>
EOF

}

sub print_login_form
{
	print header;
	print <<EOF
<HTML><HEAD></HEAD><BODY>
<FORM>
You are not logged in.<BR>
Username: <INPUT TYPE=text name=user><BR>
Password: <INPUT TYPE=password name=password><BR>
<INPUT TYPE=submit value="Login">
</FORM>
</BODY></HTML>
EOF

}


