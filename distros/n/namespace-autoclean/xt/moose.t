use strict;
use warnings;

use Test::More;
use Test::Requires { 'Moose' => '()' };
use Module::Runtime 'require_module';

use lib 'xt/lib';

foreach my $package (qw(MooseyDirty MooseyClean MooseyRole MooseyComposer MooseExporter))
{
    require_module($package);
    ok($package->can($_), "can do $package->$_") foreach @{ $package->CAN };
    ok(!$package->can($_), "cannot do $package->$_") foreach @{ $package->CANT };
}

done_testing;
