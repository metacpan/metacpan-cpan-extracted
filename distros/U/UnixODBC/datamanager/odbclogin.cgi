#!/usr/bin/perl -w

use UnixODBC (':all');
use UnixODBC::BridgeServer;
use RPC::PlClient;

my ($host, $dsn) = ($ENV{'REQUEST_URI'} =~ /hostdsn=(.*)--(.*)/);
$dsn =~ s/\+/ /g;

my $styleheader = <<END_OF_HEADER;
Content-Type: text/html

<!DOCTYPE html
	PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US">
<head><title>Untitled Document</title>
<style type="text/css">
A {color: blue}
TEXTAREA {background-color: transparent}
DIV.dsnlist {margin-left: 2}
DIV.tablelist {margin-left: 4}
DIV.loginmsg {margin-left: 10}
</style>
</head>
<body bgcolor="white" text="blue">
<center>
<h1><img src="/icons/odbc.gif" hspace="5">
Please log in:</h1>
</center>
END_OF_HEADER

my $end_html = <<END_HTML;
</body>
</html>
END_HTML

no warnings;
my $form = <<ENDOFFORM;
<form action="/cgi-bin/datamanager.cgi" target="dsns">
 <table align="center" cellpadding="10">
  <tr>
   <td>
    <label>User Name:</label><br>
    <input type="text" name="username" value=""><br>
    <label>Password:</label><br>
    <input type="password" name="password" value=""><br>
    <label>Host Name:</label><br>
    <input type="text" name="host" value="$host"><br>
    <label>Data Source:</label><br>
    <input type="text" name="dsn" value="$dsn"><br>
  </td>
 </tr>
 <tr>
  <td>
    <center><input type="submit" name="submit" value="Log In"></center>
  </td>
 </tr>
</table>
</form>
ENDOFFORM
use warnings;

print $styleheader;
print $form;
print $end_html;

