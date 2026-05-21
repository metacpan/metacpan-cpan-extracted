use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Moose; 1 } or plan skip_all => "Moose not installed";
    eval { require Mouse; 1 } or plan skip_all => "Mouse not installed";
}

use Test::MockModule;

# Plain (non-Moose) package
{
    package PlainPkg; ## no critic (Modules::RequireFilenameMatchesPackage)
    sub new { bless {}, shift }
}

# Moose package
{
    package MoosePkg; ## no critic (Modules::RequireFilenameMatchesPackage)
    use Moose;
}

# Mouse package
{
    package MousePkg; ## no critic (Modules::RequireFilenameMatchesPackage)
    use Mouse;
}

is(Test::MockModule::_meta_for('PlainPkg'), undef, "plain package returns undef");
ok(Test::MockModule::_meta_for('MoosePkg'), "Moose package returns truthy meta");
isa_ok(Test::MockModule::_meta_for('MoosePkg'), 'Class::MOP::Class', "Moose meta type");
ok(Test::MockModule::_meta_for('MousePkg'), "Mouse package returns truthy meta");
isa_ok(Test::MockModule::_meta_for('MousePkg'), 'Mouse::Meta::Class', "Mouse meta type");
is(Test::MockModule::_meta_for(undef), undef, "undef package returns undef");
is(Test::MockModule::_meta_for(''), undef, "empty package returns undef");
is(Test::MockModule::_meta_for('Does::Not::Exist'), undef, "nonexistent package returns undef");

done_testing;
