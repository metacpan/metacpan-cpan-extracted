#! perl -I. -w
use t::Test::abeltje;

use Test::Pod::Coverage;

Test::Warnings->import(':no_end_test');

my @ignore_words = sort {
    length($b) <=> length($a) ||
    $a cmp $b
} map {chomp($_); $_} <DATA>;

all_pod_coverage_ok(
    {
        also_private => [ qr/^BUILD$/ ],
        trustme => \@ignore_words,
    }
);

__DATA__
