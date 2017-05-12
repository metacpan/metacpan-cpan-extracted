#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw(lib ../lib);
use WWW::Google::Time;

@ARGV
    or die "Use: perl $0 'location of time'\n";

my $t = WWW::Google::Time->new;

$t->get_time(shift)
    or die $t->error;

printf "It is %s, %s (%s) %s %s, %s in %s\n",
    @{ $t->data }{qw/
        day_of_week  time  time_zone  month  month_day  year  where
    /};

if ( $ENV{RELEASE_TESTING} ) {
    for ( qw/day_of_week  time  time_zone  month  month_day  year where/ ) {
        print "Key `$_`: ${\$t->data->{$_}}\n";
    }
}


=pod

Usage: perl time.pl 'location of time'

=cut