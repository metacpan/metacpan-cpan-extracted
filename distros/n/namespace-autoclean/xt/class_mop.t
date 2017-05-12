use strict;
use warnings;

use Test::More;
use Test::Requires 'Class::MOP';
use Module::Runtime 'require_module';

use lib 'xt/lib';

foreach my $package (qw(ClassMOPDirty ClassMOPClean))
{
    require_module($package);
    ok($package->can($_), "can do $package->$_") foreach @{ $package->CAN };
    ok(!$package->can($_), "cannot do $package->$_") foreach @{ $package->CANT };
}

ok(!exists($INC{'Moose.pm'}), 'Moose has not been loaded');

done_testing;
