# Test::NoXS tests
use strict;

use Test::More;
use Module::Implementation;

plan tests => 5;

require_ok('Test::NoXS');

# Scalar::Util actually bootstraps List::Util
eval "use Test::NoXS qw( Class::Load::XS DB_File)";

is( $@, q{}, "told Test::NoXS not to load XS for Class::Load::XS or DB_File" );

my $use_CL = "use Class::Load";

eval $use_CL;

is( Module::Implementation::implementation_for("Class::Load"),
    "PP", "Class::Load using PP" );

my $use_F = "use Fcntl qw( LOCK_EX )";

eval $use_F;

is( $@, q{}, "'$use_F' successful" );

ok( defined *main::LOCK_EX{CODE}, "function LOCK_EX imported (i.e. XS loaded)" );

#silence warning
LOCK_EX();

