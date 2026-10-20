#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);
use FindBin ();

use Time::Keeper;
use Time::Keeper::Business;
require "$FindBin::Bin/../eg/japan.pl";

my %want;
open my $fh, '<:encoding(UTF-8)', "$FindBin::Bin/japan-holidays-2016-2027.tsv" or die "japan table: $!";
while (my $line = <$fh>) {
    next if $line =~ /^#/;
    chomp $line;
    my ($date, $name) = split /\t/, $line;
    push @{ $want{ substr $date, 0, 4 } }, [ $date, $name ];
}
my $jp = japan();
for my $year (sort keys %want) {
    my @got = $jp->holidays(year => $year);
    is_deeply([ map { "$_->[0]" } @got ], [ map { $_->[0] } @{ $want{$year} } ], "$year: the dates agree with the Cabinet Office");
    my %name = map { ("$_->[0]" => $_->[1]) } @got;
    my @wrong = grep { $_->[1] ne '休日' && ($name{ $_->[0] } // '') ne $_->[1] } @{ $want{$year} };
    is(scalar @wrong, 0, "$year: and the names, but for the substitute and sandwiched days the list calls 休日") or diag explain \@wrong;
}
my %sandwiched = map { ("$_->[0]" => 1) } grep { $_->[1] eq '休日' } map { $jp->holidays(year => $_) } 2016 .. 2027;
is_deeply([ sort keys %sandwiched ], [qw(2019-04-30 2019-05-02 2026-09-22)], 'the sandwiched days are 30 April and 2 May 2019 and 22 September 2026');
is(scalar(() = $jp->holidays(year => 2015)), 0, 'the set holds from 2016');
my $b = Time::Keeper::Business->new(holidays => japan(), zone => 'Asia/Tokyo');
is($b->business_days_between(Time::Keeper::Date->parse('2019-04-26'), Time::Keeper::Date->parse('2019-05-07')), 1, 'Golden Week 2019 left one business day in eleven: Friday 26 April');

done_testing;
