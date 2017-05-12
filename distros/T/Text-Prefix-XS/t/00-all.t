#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Text::Prefix::XS;
use Test::Deep qw(cmp_details deep_diag);

use Digest::SHA1 qw(sha1_hex);

my $STRING_COUNT = 5;
my $TERM_COUNT = 5;
my $PREFIX_MIN = 5;
my $PREFIX_MAX = 15;

my @strings = map substr(sha1_hex($_),0, 30), (0..$STRING_COUNT);

my @terms;
while(@terms < $TERM_COUNT) {
    my $str = $strings[int(rand($STRING_COUNT))];
    my $prefix = substr($str, 0, 
        int(rand($PREFIX_MAX - $PREFIX_MIN)) + $PREFIX_MIN);
    if(!grep $_ eq $prefix, @terms) {
        push @terms, $prefix;
    }
}

my %re_seen_hash;
@terms = sort { length $b <=> length $a || $a cmp $b } @terms;
my $BIG_RE = join '|', 
    map quotemeta, @terms;


$BIG_RE = qr/^($BIG_RE)/;

my $re_matches = 0;

foreach my $str (@strings) {
    my ($match) = ($str =~ $BIG_RE);
    if($match) {
        $re_seen_hash{$match}++;
        $re_matches++;
    }
}


my $xs_matches = 0;
my %xs_seen_hash;
my $xs_search = prefix_search_build(\@terms);
foreach my $str (@strings) {
    my $match = prefix_search($xs_search, $str);
    
    if($match) {
        $xs_seen_hash{$match}++;
        $xs_matches++;
    }
}

is($xs_matches, $re_matches, "Regex and XS return same amount of matches ($xs_matches)");
my ($they_match,$stack) = cmp_details(\%xs_seen_hash, \%re_seen_hash);
ok($they_match, "Match results are identical");
if(!$they_match) {
    diag deep_diag($stack);
    use Data::Dumper;
    print Dumper(\%xs_seen_hash);
    print Dumper(\%re_seen_hash);
    print Dumper(\@terms);
    print Dumper(\@strings);
}

my $match_hash = prefix_search_multi($xs_search, @strings);
%xs_seen_hash = ();
$xs_matches = 0;

while (my ($pfix,$matches) = each %$match_hash) {
    $xs_seen_hash{$pfix} = scalar @$matches;
    $xs_matches++;
}
is($xs_matches, $re_matches, "Got expected number of matches from multi()");

done_testing();