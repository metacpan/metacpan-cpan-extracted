#!perl -T

use strict;
use warnings;
use Test::More;
use Readonly;

# constants
Readonly::Scalar my $main_class => "TimeZone::Solar";

# always test these modules can load
Readonly::Array my @submodules => qw(
);
Readonly::Array my @modules => ( $main_class, map { $main_class . "::" . $_ } @submodules );

# count tests
plan tests => int(@modules);

# test loading modules
foreach my $mod (@modules) {
    require_ok($mod);
}

{
    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    eval "require $main_class";
    diag( "Testing  $main_class " . $main_class->version() . ", Perl $], $^X" );
}
