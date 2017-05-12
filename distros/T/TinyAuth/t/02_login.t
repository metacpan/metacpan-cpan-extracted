#!/usr/bin/perl

use strict;
use vars qw{$VERSION};
BEGIN {
	$|       = 1;
	$^W      = 1;
	$VERSION = '0.98';
}

use Test::More tests => 45;

use File::Spec::Functions ':ALL';
use YAML::Tiny;
use t::lib::Test;
use t::lib::TinyAuth;

$ENV{SCRIPT_NAME} = '/cgi-bin/foobar';





#####################################################################
# Normal Index Page

SCOPE: {
	my $instance = t::lib::TinyAuth->new( "02_login1.cgi" );

	# Run the instance
	is( $instance->run, 1, '->run ok' );

	# Check the output
	cgi_cmp( $instance->stdout, <<"END_HTML", '->stdout returns as expect' );
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">

<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<title>TinyAuth $VERSION</title>
</head>

<body>
<h2>User</h2>
<p><a href="$ENV{SCRIPT_NAME}?a=f">I forgot my password</a></p>
<p><a href="$ENV{SCRIPT_NAME}?a=c">I want to change my password</a></p>
<h2>Admin</h2>
<form method="post" name="f" action="$ENV{SCRIPT_NAME}">
<p>Email</p>
<p><input type="text" name="E" size="30"></p>
<p>Password</p>
<p><input type="password" name="P" size="30"></p>
<p><input type="submit" name="s" value="Login"></p>
</form>
<hr>
<p><i>Powered by <a href="http://search.cpan.org/perldoc?TinyAuth">TinyAuth</a></i></p>
</body>
</html>
END_HTML
}





#####################################################################
# Login

SCOPE: {
	my $instance = t::lib::TinyAuth->new( "02_login2.cgi" );

	# Was an admin user found and set?
        ok( $instance->user, 'Admin user set' );
        isa_ok( $instance->user, 'Authen::Htpasswd::User' );

	# Run the instance
	is( $instance->run, 1, '->run ok' );

	# Check the output
	cgi_cmp( $instance->stdout, <<"END_HTML", '->stdout returns as expect' );
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">

<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<title>TinyAuth $VERSION</title>
</head>

<body>
<h2>User</h2>
<p><a href="$ENV{SCRIPT_NAME}?a=f">I forgot my password</a></p>
<p><a href="$ENV{SCRIPT_NAME}?a=c">I want to change my password</a></p>
<h2>Admin</h2>
<p><a href="$ENV{SCRIPT_NAME}?a=n">Add a new account</a></p>
<p><a href="$ENV{SCRIPT_NAME}?a=l">List all accounts</a></p>
<p><a href="$ENV{SCRIPT_NAME}?a=d">Delete an account</a></p>
<p><a href="$ENV{SCRIPT_NAME}?a=m">Promote an account</a></p>
<p><a href="$ENV{SCRIPT_NAME}?a=o">Logout</a></p>
<hr>
<p><i>Powered by <a href="http://search.cpan.org/perldoc?TinyAuth">TinyAuth</a></i></p>
</body>
</html>

END_HTML
}





#####################################################################
# Bad Login

SCOPE: {
	my $instance = t::lib::TinyAuth->new( "02_login4.cgi" );
	is( $instance->user, undef, '->user is not set' );

	# Run the instance
	is( $instance->run, 1, '->run ok' );

	# Check the output
	cgi_cmp( $instance->stdout, <<"END_HTML", '->stdout returns as expect' );
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">

<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<title>TinyAuth $VERSION</title>
</head>

<body>
<h1>Error</h1>
<h2>Incorrect password</h2>
</body>
</html>

END_HTML
}





#####################################################################
# Normal Index Page

SCOPE: {
	$ENV{HTTP_COOKIE} = 'e=adamk@cpan.org;p=foo';
	my $instance = t::lib::TinyAuth->new( "02_login1.cgi" );

	# Run the instance
	is( $instance->run, 1, '->run ok' );

	# Check the output
	cgi_cmp( $instance->stdout, <<"END_HTML", '->stdout returns as expect' );
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">

<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<title>TinyAuth $VERSION</title>
</head>

<body>
<h2>User</h2>
<p><a href="$ENV{SCRIPT_NAME}?a=f">I forgot my password</a></p>
<p><a href="$ENV{SCRIPT_NAME}?a=c">I want to change my password</a></p>
<h2>Admin</h2>
<p><a href="$ENV{SCRIPT_NAME}?a=n">Add a new account</a></p>
<p><a href="$ENV{SCRIPT_NAME}?a=l">List all accounts</a></p>
<p><a href="$ENV{SCRIPT_NAME}?a=d">Delete an account</a></p>
<p><a href="$ENV{SCRIPT_NAME}?a=m">Promote an account</a></p>
<p><a href="$ENV{SCRIPT_NAME}?a=o">Logout</a></p>
<hr>
<p><i>Powered by <a href="http://search.cpan.org/perldoc?TinyAuth">TinyAuth</a></i></p>
</body>
</html>
END_HTML
}









#####################################################################
# Logout

SCOPE: {
	my $instance = t::lib::TinyAuth->new( "02_login3.cgi" );

	# Was an admin user found and set?
	# (This time via the cookies)
        ok( $instance->user, 'Admin user set' );
        isa_ok( $instance->user, 'Authen::Htpasswd::User' );

	# Run the instance
	is( $instance->run, 1, '->run ok' );

	# Check the output
	cgi_cmp( $instance->stdout, <<"END_HTML", '->stdout returns as expect' );
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">

<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<title>TinyAuth $VERSION</title>
</head>

<body>
<h2>User</h2>
<p><a href="$ENV{SCRIPT_NAME}?a=f">I forgot my password</a></p>
<p><a href="$ENV{SCRIPT_NAME}?a=c">I want to change my password</a></p>
<h2>Admin</h2>
<form method="post" name="f" action="$ENV{SCRIPT_NAME}">
<p>Email</p>
<p><input type="text" name="E" size="30"></p>
<p>Password</p>
<p><input type="password" name="P" size="30"></p>
<p><input type="submit" name="s" value="Login"></p>
</form>
<hr>
<p><i>Powered by <a href="http://search.cpan.org/perldoc?TinyAuth">TinyAuth</a></i></p>
</body>
</html>
END_HTML
}
