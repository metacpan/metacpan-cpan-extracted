#!perl -T

use strict;
use warnings;
use Test::More;
use Try::Tiny;

# always test these modules can load
my @modules = qw(
    WebFetch::Input::Atom
);

# count tests
plan tests => int(@modules);

# test loading modules
foreach my $mod (@modules) {
    use_ok($mod);
}

require WebFetch::Input::Atom;
diag( "Testing WebFetch::Input::Atom $WebFetch::Input::Atom::VERSION, Perl $], $^X" );
