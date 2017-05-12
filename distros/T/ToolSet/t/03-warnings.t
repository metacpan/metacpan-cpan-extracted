use strict;
use lib '.';
use Test::More tests => 2;

local $^W = 0; # Module::Build enables global warnings -- we need them off

#--------------------------------------------------------------------------#
# Harness to capture warnings
#--------------------------------------------------------------------------#

my $warning = '';

# store warnings
local $SIG{__WARN__} = sub {
    $warning = shift;
};

# return and clear
sub check_warning {
    my $val = $warning;
    $warning = '';
    return $val;
}

#--------------------------------------------------------------------------#
# Test warning propogation
#--------------------------------------------------------------------------#

# Catch warning
require t::Sample::HasWarnings;
like(
    check_warning(),
    qr/^Argument "" isn't numeric in addition/,
    "Warnings propogate when set_warnings(1)"
);

# Ignore warning
require t::Sample::IgnoreWarnings;
is( check_warning(), q{}, "Warnings don't propogate when set_warnings(0)" );

