#!/usr/bin/perl -T

# t/02parser.t
#  Tries to parse a sample page
#
# $Id: 02parser.t 8624 2009-08-18 05:26:06Z FREQUENCY@cpan.org $

use strict;
use warnings;

use Test::More tests => 10;

use WebService::UWO::Directory::Student;

# This embedded HTML is Copyright (c) the University of Western Ontario. It is
# believed that its use here constitutes fair use; however, it will be removed
# upon request.
my $html = << '__END__';
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2//EN">

<HTML>
<HEAD><TITLE>Search Results</TITLE>
</HEAD>
<BODY bgcolor="#FFFFFF">
<table width="100%" cellspacing="0" cellpadding="0" border="0">
<tr>
<td width="20%"><a href="http://www.uwo.ca/"><IMG src="http://www.uwo.ca/westerndir/images/tower-small.gif" border="0" ALT="UWO logo" align="left"></a>
</td>
<td valign="top" align="left"><font size="7"><b>Directory</b></font>
<br><font="3"><em>The</em> University <em>of</em> Western Ontario</font></td>

</tr>
</table>
<p>
<table width="100%" bgcolor="#6000099" cellspacing="0" cellpadding="0"
border="0">
<tr>
<td height="30" width="15%" align="center">&nbsp;</td>
<td height="30" width="14%" align="center"><a href="http://www.uwo.ca/westerndir/index.html"><b><font color="#FFFFFF">Home</b></font></a></td>
<td height="30" width="14%" align="center"><a href="http://www.uwo.ca/westerndir/index-people.html"><font color="#FFFFFF"><b>Faculty/Staff </b></font></a></td>
<td height="30" width="14%" align="center"><a href="http://www.uwo.ca/westerndir/index-student.html"><font color="#FFFFFF"><b>Students</b></font></a></td>
<td height="30" width="14%" align="center"><a href="http://www.uwo.ca/westerndir/index-dept.html"><font color="#FFFFFF"><b>Department</b></font></a></td>
<td height="30" width="14%" align="center"><a href="http://www.uwo.ca/westerndir/help/index.html"><font color="#FFFFFF"><b>Help</b></a></font></td>
<td height="30" width="15%">&nbsp;</td>

</tr>
</table>
<P>

Student directory is maintained by the Office of the Registrar.

<HR>
<PRE>
Results of search for test,:

    Full Name: Testa,Christine Ann
       E-mail: <A HREF="mailto:ctesta@uwo.ca">ctesta@uwo.ca</A>
Registered In: Faculty of Social Science

    Full Name: Test,Continuing
       E-mail: <A HREF="mailto:ctest@uwo.ca">ctest@uwo.ca</A>
Registered In: Faculty of Graduate Studies

</PRE>
<p>
<table width="100%" bgcolor="#6000099" cellspacing="0" cellpadding="0"
border="0">

<tr>
<td height="30" width="15%" align="center">&nbsp;</td>
<td height="30" width="14%" align="center"><a href="http://www.uwo.ca/westerndir/index.html"><b><font color="#FFFFFF">Home</b></font></a></td>
<td height="30" width="14%" align="center"><a href="http://www.uwo.ca/westerndir/index-people.html"><font color="#FFFFFF"><b>Faculty/Staff </b></font></a></td>
<td height="30" width="14%" align="center"><a href="http://www.uwo.ca/westerndir/index-student.html"><font color="#FFFFFF"><b>Students</b></font></a></td>
<td height="30" width="14%" align="center"><a href="http://www.uwo.ca/westerndir/index-dept.html"><font color="#FFFFFF"><b>Department</b></font></a></td>
<td height="30" width="14%" align="center"><a href="http://www.uwo.ca/westerndir/help/index.html"><font color="#FFFFFF"><b>Help</b></a></font></td>
<td height="30" width="15%">&nbsp;</td>
</tr>
</table>
<p>
<center>

<ADDRESS>
<font size="-1">
This service is provided by 
<A href="http://www.uwo.ca/its/">Information Technology Services 
(ITS)</a> at 
<br><A href="http://www.uwo.ca/">The University of Western
Ontario</A>.
&nbsp;&nbsp;
Maintained by <A href="mailto:accting@uwo.ca">
Computer Accounts Office</a>, March 23, 2005.

</font>
</address>
</center>
</BODY>

</HTML>
__END__

my $res = WebService::UWO::Directory::Student::_parse(\$html);

is(ref($res), 'ARRAY', 'Parser returns array reference');
is(scalar(@{$res}), 2, 'Two elements parsed');

my $t = shift(@{$res});
is($t->{given_name}, 'Christine Ann', 'Parse first name (0)');
is($t->{last_name}, 'Testa', 'Parse last name (0)');
is($t->{email}, 'ctesta@uwo.ca', 'Parse email (0)');
is($t->{faculty}, 'Faculty of Social Science', 'Parse faculty (0)');

$t = shift(@{$res});
is($t->{given_name}, 'Continuing', 'Parse first name (1)');
is($t->{last_name}, 'Test', 'Parse last name (1)');
is($t->{email}, 'ctest@uwo.ca', 'Parse email (1)');
is($t->{faculty}, 'Faculty of Graduate Studies', 'Parse faculty (1)');
