#!/usr/bin/env perl

use warnings;
use strict;

use pokemon_go_server_status;
use Getopt::Long;

$|=1;

sub usage {
    print STDERR "usage: ".$0."\n";
    print STDERR "       [--help]\n\n";
    exit 1;
}

sub main {
    my $help = 0;
    my $text;
    my $line;

    if(!GetOptions(
	    "help|h" => \$help )) {
	usage();
    }
    if($help) {
	usage();
    }
    
    print get_server_status(), "\n";
}

&main;
