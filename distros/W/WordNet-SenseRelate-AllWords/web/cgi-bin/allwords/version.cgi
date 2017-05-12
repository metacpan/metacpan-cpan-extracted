#!/usr/bin/perl -w
use IO::Socket;
use CGI;

# change the value of $remote_host variable to the
# ip where you are running allwords server.

my $remote_host='127.0.0.1';
my $remote_port=32323;
my $hostname;

# Mapping from hash-code to version
my %versionMap = ('eOS9lXC6GvMWznF1wkZofDdtbBU' => '3.0', 'LL1BZMsWkr0YOuiewfbiL656+Q4' => '2.1');
my $cgi = CGI->new;
my $filename;
print $cgi->header;
print $cgi->h3("Version information");
$hostname=$ENV{'SERVER_NAME'};

# check if we want to show the version information (version of WordNet, etc.)
my $showversion = $cgi->param ('version');
if ($showversion) 
{
	# connect to allwords server
	 socket (Server, PF_INET, SOCK_STREAM, getprotobyname ('tcp'));

	 my $internet_addr = inet_aton ($remote_host) or do {
		 print "<p>Could not convert $remote_host to an IP address: $!</p>\n";
		 die;
			 };

			 my $paddr = sockaddr_in ($remote_port, $internet_addr);

			 unless (connect (Server, $paddr)) {
				 print "<p>Cannot connect to server $remote_host:$remote_port ($!)</p>\n";
			die;
                 }
select ((select (Server), $|=1)[0]);
print "<html>
<head>
<title>AllWords Version info</title>
</head>
</html>";
die "can't fork: $!" unless defined($kidpid = fork());
# the if{} block runs only in the parent process
    if ($kidpid)
    {
        # copy the socket to CGI output
        while (defined ($line = <Server>))
        {
			if ($line =~ /^v (\S+) (\S+)/) 
			{
				if($1 eq "WordNet") 
				{
		            my $verstring = $versionMap{$2};
		 		    print "<p>$1 version $verstring (hash-code: $2)</p>\n" if(defined($verstring));
					print "<p>$1 hash-code: $2</p>\n" if(!defined($verstring));
				}
				else 
				{
					print "<p>$1 version $2</p>\n";
				}
			}
			elsif ($line =~ m/^! (.*)/) 
			{
				print "<p>$1</p>\n";
			}
		}
		    local $ENV{PATH} = "/usr/local/bin:/usr/bin:/bin:/sbin";
		    my $t_osinfo = `uname -a` || "Couldn't get system information: $!";
		    # $t_osinfo is tainted.  Use it in a pattern match and $1 will
		    # be untainted.
		    $t_osinfo =~ /(.*)/;
		    print "<p>HTTP server: $ENV{HTTP_HOST} ($1)</p>\n";
		    print "<p>SenseRelate::AllWords server: $remote_host</p>\n";

		print "<p><a href=\"http://$hostname/allwords/allwords.html\">Back</a></p>";
        kill("TERM", $kidpid);                  # send SIGTERM to child
    }
    # the else{} block runs only in the child process
    else
    {
		$line="<version information>:\n";
	    print Server $line;
    }
}

=head1 NAME

version.cgi - [Web] CGI script implementing a portion of a web interface 
for WordNet::SenseRelate::AllWords

=head1 DESCRIPTION

This script works in conjunction with allwords_server.pl to provide 
version information for WordNet::SenseRelate::AllWords web interface.
If the user requests version information, this script takes action. 
The script sends request to allwords_server.pl for version information. 
After receiving results from the server, they are displayed to the user.

=head1 AUTHORS

 Varada Kolhatkar, University of Minnesota, Duluth
 kolha002 at d.umn.edu

 Ted Pedersen, University of Minnesota, Duluth
 tpederse at d.umn.edu

This document last modified by : 
$Id: version.cgi,v 1.9 2008/11/05 00:55:55 kvarada Exp $ 

=head1 SEE ALSO

 L<allwords_server.pl> L<README.web.pod>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008, Varada Kolhatkar, Ted Pedersen, Jason Michelizzi

Permission is granted to copy, distribute and/or modify this document
under the terms of the GNU Free Documentation License, Version 1.2
or any later version published by the Free Software Foundation;
with no Invariant Sections, no Front-Cover Texts, and no Back-Cover
Texts.

Note: a copy of the GNU Free Documentation License is available on
the web at L<http://www.gnu.org/copyleft/fdl.html> and is included in
this distribution as FDL.txt.

=cut
