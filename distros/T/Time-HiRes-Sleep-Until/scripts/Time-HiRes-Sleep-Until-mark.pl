#!/usr/bin/perl
use strict;
use warnings;
use DateTime;
use Time::HiRes::Sleep::Until;

my $mark=shift || 20;

my $su=Time::HiRes::Sleep::Until->new;

do {
  print DateTime->now, "\n"; #do something three times a minute
} while ($su->mark($mark));

__END__

=head1 NAME

Time-HiRes-Sleep-Until-mark.pl - Time::HiRes::Sleep::Until second mark of the clock

=cut
