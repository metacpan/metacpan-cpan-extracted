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
use Email::Send::Test;
use t::lib::Test;
use t::lib::TinyAuth;





#####################################################################
# Show the "I forgot my password" form

SCOPE: {
	my $instance = t::lib::TinyAuth->new( '05_change1.cgi' );

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
<h2>You want to change your password</h2>
<p>I just need to know a few things to do that</p>
<form method="post" name="f">
<input type="hidden" name="a" value="p">
<table border="0" cellpadding="0" cellspacing="0">
<tr><td>
<p>What is your email address?</p>
<p>What is your current password?</p>
<p>Type in the new password you want&nbsp;&nbsp;</p>
<p>Type it again to prevent mistakes</p>
</td><td>
<p><input type="text" name="e" size="30"></p>
<p><input type="password" name="p" size="30"></p>
<p><input type="password" name="n" size="30"></p>
<p><input type="password" name="c" size="30"></p>
</td></tr>
</table>
<p>Hit the button when you are ready to go <input type="submit" name="s" value="Change my password"></p>
</form>
<script language="JavaScript">
document.f.e.focus();
</script>
</body>
</html>

END_HTML
}





#####################################################################
# Request a bad password

SCOPE: {
	my $instance = t::lib::TinyAuth->new( "05_change2.cgi" );

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
<h2>Your password has been changed</h2>
</body>
</html>

END_HTML
}
