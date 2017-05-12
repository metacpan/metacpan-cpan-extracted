#!/usr/bin/perl

# Test promotion to administrator

use strict;
use vars qw{$VERSION};
BEGIN {
	$|       = 1;
	$^W      = 1;
	$VERSION = '0.98';
}

use Test::More tests => 40;

use File::Spec::Functions ':ALL';
use YAML::Tiny;
use Email::Send::Test;
use t::lib::Test;
use t::lib::TinyAuth;

$ENV{SCRIPT_NAME} = '/cgi-bin/foobar';





#####################################################################
# Try to the actions as a (forbidden) regular user

SCOPE: {
	my $instance = t::lib::TinyAuth->new(  "08_delete1.cgi" );

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
<h2>Only administrators are allowed to do that</h2>
</body>
</html>

END_HTML
}

SCOPE: {
	my $instance = t::lib::TinyAuth->new(  "08_delete2.cgi" );

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
<h2>Only administrators are allowed to do that</h2>
</body>
</html>

END_HTML
}









#####################################################################
# Show the "Delete which users" page

SCOPE: {
	$ENV{HTTP_COOKIE} = 'e=adamk@cpan.org;p=foo';
	my $instance = t::lib::TinyAuth->new( "08_delete1.cgi" );

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
<h2>Select Account(s) to Delete</h2>
<form name="f" action="$ENV{SCRIPT_NAME}">
<input type="hidden" name="a" value="e">
<b><label><input type="checkbox" name="_" value="adamk\@cpan.org" disabled />adamk\@cpan.org</label></b><br />
<label><input type="checkbox" name="e" value="foo\@bar.com" />foo\@bar.com</label><br />
<label><input type="checkbox" name="e" value="foo\@one.com" />foo\@one.com</label><br />

<input type="submit" name="s" value="Delete">
</form>
</body>
</html>

END_HTML
}





#####################################################################
# Delete one user

SCOPE: {
	my $instance = t::lib::TinyAuth->new( "08_delete2.cgi" );

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
<h1>Action Completed</h1>
<h2>Deleted account foo\@bar.com</h2>
</body>
</html>

END_HTML
}





#####################################################################
# Delete multiple users

SCOPE: {
	my $instance = t::lib::TinyAuth->new( "08_delete3.cgi" );

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
<h1>Action Completed</h1>
<h2>Deleted account foo\@bar.com<br />Deleted account foo\@one.com</h2>
</body>
</html>

END_HTML
}
