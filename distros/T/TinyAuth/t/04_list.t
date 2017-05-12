#!/usr/bin/perl

use strict;
use vars qw{$VERSION};
BEGIN {
	$|       = 1;
	$^W      = 1;
	$VERSION = '0.98';
}

use Test::More tests => 16;

use File::Spec::Functions ':ALL';
use YAML::Tiny;
use t::lib::Test;
use t::lib::TinyAuth;





#####################################################################
# Show the user list as a regular user (i.e. an error)

SCOPE: {
	my $instance = t::lib::TinyAuth->new( "04_list.cgi" );

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
# Show the list (successfully) as an admin

SCOPE: {
	local $ENV{HTTP_COOKIE} = 'e=adamk@cpan.org;p=foo';
	my $instance = t::lib::TinyAuth->new( "04_list.cgi" );

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
<h2>Account List</h2>
<b>adamk\@cpan.org</b><br />
foo\@bar.com<br />
foo\@one.com<br />

</body>
</html>

END_HTML
}
