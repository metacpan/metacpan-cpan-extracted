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
require t::Sample::SWC;
like( check_warning(), qr/^We can carp/, "ToolSet::SWC carping works" );

eval "use t::Sample::SWCError; ";

like(
    "$@",
    qr/^Global symbol "\$var" requires explicit package name/,
    "ToolSet::SWC sets strict"
);

