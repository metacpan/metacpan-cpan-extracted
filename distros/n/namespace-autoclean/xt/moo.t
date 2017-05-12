use strict;
use warnings;

use Test::More;
use Test::Requires { 'Moo' => '()' };
use Module::Runtime 'require_module';

use lib 'xt/lib';

foreach my $package (qw(MooyDirty MooyClean MooyRole MooyComposer))
{
    require_module($package);
    ok($package->can($_), "can do $package->$_") foreach @{ $package->CAN };
    ok(!$package->can($_), "cannot do $package->$_") foreach @{ $package->CANT };
}

done_testing;
