#!/usr/bin/perl -wT
use strict;

use CGI;
use Socket;

# where do we connect to the Similarity server?  Here:
# note I put in my local host information just to give you an idea.
# you should add your own though if you are using another server
# you need to change the $remote_host and $doc_base
my $remote_host = 'localhost';
my $remote_port = 31135;
my $doc_base = '/var/www/umls_similarity';

my $cgi = CGI->new;

print $cgi->header;


my $input = $cgi->param ('wps') || 'undefined word';

my ($wps, $button) = split/\|/, $input;

print <<"EOB";
<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
                      "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
  <title>Gloss for $wps</title>
  <link rel="stylesheet" href="$doc_base/sim-style.css" type="text/css" />
</head>
<body>
EOB

unless ($wps =~ /[Cc][0-9]+/) { 
    print "<p>Error: bad input word: $wps</p>\n";
    goto SHOW_END;
}

# connect to Similarity server
socket (Server, PF_INET, SOCK_STREAM, getprotobyname ('tcp'));

my $internet_addr = inet_aton ($remote_host) or do {
    print "<p>Could not convert $remote_host to an IP address: $!</p>\n";
    goto SHOW_END;
};

my $paddr = sockaddr_in ($remote_port, $internet_addr);

unless (connect (Server, $paddr)) {
    print "<p>Cannot connect to server $remote_host:$remote_port ($!)</p>\n";
    goto SHOW_END;
}

select ((select (Server), $|=1)[0]);


print Server "g|$button|$wps|\015\012";
print Server "\015\012";

while (my $line = <Server>) {
    last if $line eq "\015\012";
    my ($type, $str) = $line =~ m/^(\S+) (.+)/;
    if ($type eq 'g' or $type eq '1') {
	my ($wps, $gloss) = $str =~ m/([cC][0-9]+) (.*)/;
	my @defs = split/\|/, $gloss;
	print "<dl><dt>$wps</dt>";
	if($#defs <= 0) { 
	    print "<dd>Definition does not exist.\n";
	}
	foreach my $def (@defs) {
	    print "<dd>$def</dd>\n";
	}
	print "</dl>\n";
    }
    elsif ($type eq '!') {
	print "<p>$str</p>\n";
    }
    else {
	print "<p>Error: odd message from server: ($type) $str</p>\n";
    }
}

SHOW_END:

close Server;

print <<'EOH';
</body>
</html>
EOH

__END__

=head1 NAME

wps.cgi - a CGI script implementing the obtaining of the concept definitions 
for the web interface. 

=head1 DESCRIPTION

This script takes two parameter 'button' and 'wps', in which button indicates 
whether the similarity or relatedness is being obtained (SAB or SABDEF) and 
'wps' is a term. The script produces a web page that displays the UMLS 
definition for each possible CUI of the term.

=head1 AUTHORS

 Bridget T. McInnes, University of Minnesota
 bthomson at umn.edu

 Ted Pedersen, University of Minnesota Duluth
 tpederse at d.umn.edu

 Jason Michelizzi

=head1 BUGS

None known.

=head1 COPYRIGHT

Copyright (c) 2010-2011, Bridget T. McInnes, Ted Pedersen and Jason Michelizzi

This program is free software; you may redistribute and/or modify it under the
terms of the GNU General Public License, version 2 or, at your option, any
later version.

=cut

