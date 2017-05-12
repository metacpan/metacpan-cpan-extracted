#!/usr/bin/perl
use strict;
use warnings;
use Zen::Koans qw(get_koan);
use CGI qw(header param);

print header;

my $num = param("n") || param("num");
eval { print get_koan($num)->as_html };
if ($@) { 
    print "Error: $@";
}

