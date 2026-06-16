use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Moo; 1 } or plan skip_all => "Moo not installed";
}

use Test::MockModule;

# Plain (non-Moo) package
{
    package PlainPkg; ## no critic (Modules::RequireFilenameMatchesPackage)
    sub new { bless {}, shift }
}

# Moo package
{
    package MooPkg; ## no critic (Modules::RequireFilenameMatchesPackage)
    use Moo;
    has answer => (is => 'ro', default => 42);
    sub greet { 'real_greet' }
}

# A Moo class must NOT be treated as a Moose/Mouse MOP class: _meta_for
# returns undef so mocking falls back to plain symbol-table replacement.
# Pre-fix this either returns a truthy Moo::HandleMoose::FakeMetaClass
# (Moose installed) or throws inside Moo::HandleMoose (Moose absent).
is(Test::MockModule::_meta_for('MooPkg'), undef, "Moo package returns undef meta");

is(Test::MockModule::_meta_for('PlainPkg'), undef, "plain package returns undef");
is(Test::MockModule::_meta_for(undef), undef, "undef package returns undef");
is(Test::MockModule::_meta_for(''), undef, "empty package returns undef");
is(Test::MockModule::_meta_for('Does::Not::Exist'), undef, "nonexistent package returns undef");

done_testing;
