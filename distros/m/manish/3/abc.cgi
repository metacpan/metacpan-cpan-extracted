#!/usr/bin/perl -w
 
use strict;
use CGI qw(:standard);
use CGI::Carp;
	# Use the DBI module
use DBI;
#CGI::use_named_parameters(1);
 
my ($server, $sock, $host);
 
my $output = new CGI;
$server = param('server') or $server = '';
 
# Prepare the MySQL DBD driver
my $driver = DBI->install_driver('mysql');
 
	my @databases = $driver->func($server, '_ListDBs');
 
# If @databases is undefined we assume
# that means that the host does not have
# a running MySQL server. However, there could be other reasons
# for the failure. You can find a complete error message by
# checking $DBI::errmsg.
if (not @databases) {
        print header, start_html('title'=>"Information on $server",
        'BGCOLOR'=>'white');
        print <<END_OF_HTML;
<H1>$server</h1>
$server does not appear to have a running mSQL server.
</body></html>
END_OF_HTML
        exit(0);
}
 
       print header, start_html('title'=>"Information on $host", 
                                'BGCOLOR'=>'white');
       print <<END_OF_HTML;
<H1>$host</h1>
<p>
$host\'s connection is on socket $sock.
<p>
Databases:<br>
<UL>
END_OF_HTML
foreach (@databases) {
        print "<LI>$_\n";
}
print <<END_OF_HTML;
</ul>
</body></html>
END_OF_HTML
exit(0)


