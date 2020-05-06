#!/usr/bin/perl
use strict;
use warnings;
use Time::HiRes qw{time};
use DateTime;
use Time::HiRes::Sleep::Until;
use DateTime::Format::Strptime;

my $seconds   = shift // 1; #try negatives too
my $later     = CORE::time + $seconds;
my $su        = Time::HiRes::Sleep::Until->new;
my $formatter = DateTime::Format::Strptime->new(pattern=>q{%FT%T.%3N});

printf "%s: Start\n", DateTime->from_epoch(epoch=>time, formatter=>$formatter);
my $slept     = $su->epoch($later);
printf "%s: Slept: %s\n", DateTime->from_epoch(epoch=>time, formatter=>$formatter), $slept;

__END__

=head1 NAME

Time-HiRes-Sleep-Until-epoch.pl - Time::HiRes::Sleep::Until epoch example

=cut
