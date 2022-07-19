#!perl -T

use strict;
use warnings;
use Test::More;
use Try::Tiny;

# always test these modules can load
my @modules = qw(
    WebFetch::Output::TT
);

# count tests
plan tests => int(@modules);

# test loading modules
foreach my $mod (@modules) {
    use_ok($mod);
}

require WebFetch;
diag( "Testing WebFetch::Output::TT $WebFetch::Output::TT::VERSION, Perl $], $^X" );
