use strict;

use Test;
use XML::SAX::Machines qw( Machine );

my $m;

my $out;

my @tests = (
sub {
    eval { Machine( [ A => undef ] ) };
    ok $@ =~ /undef/ ? "undef passed exception" : $@, "undef passed exception";
},
sub {
    eval { Machine( [ A => '' ] ) };
    ok $@ =~ /empty/i ? "empty string exception" : $@, "empty string exception";
},
sub {
    eval { Machine( [ A => "BlarneyFilter" ] ) };
    ok $@ =~ /BlarneyFilter/ ? "missing filter exception" : $@, "missing filter exception";
},
);

plan tests => scalar @tests;

$_->() for @tests;
