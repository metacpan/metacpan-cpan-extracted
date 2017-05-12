#!/usr/bin/perl -w
use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use strict;
print header;
print start_html();
my $ctype=param('mani');
#while($ctype=[^a-z0-9A-Z])
$ctype = ucfirst($ctype);
#my $valstr=ucfirst($ctype);
#$dr=sprintf "$ctype";
print "$ctype";
print "\n";
print end_html;


