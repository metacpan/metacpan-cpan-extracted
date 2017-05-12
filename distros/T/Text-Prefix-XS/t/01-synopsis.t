#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Text::Prefix::XS;

my @haystacks = qw(
    garbage
    blarrgh
    FOO-stuff
    meh
    AA-ggrr
    AB-hi!
);

my @prefixes = qw(AAA AB FOO FOO-BAR);

my $search = prefix_search_create( map uc($_), @prefixes );

my %seen_hash;

foreach my $haystack (@haystacks) {
    if(my $prefix = prefix_search($search, $haystack)) {
        $seen_hash{$prefix}++;
    }
}

ok($seen_hash{'FOO'} == 1);

%seen_hash = ();
#Compare to:
my $re = join('|', map quotemeta $_, @prefixes);
$re = qr/^($re)/;

foreach my $haystack (@haystacks) {
    my ($match) = ($haystack =~ $re);
    if($match) {
        $seen_hash{$match}++;
    }
}
ok($seen_hash{'FOO'} == 1);

#Super fast:

my $match_results = prefix_search_multi($search, @haystacks);
ok(grep $_ eq 'FOO-stuff', @{ $match_results->{FOO} });
done_testing();
