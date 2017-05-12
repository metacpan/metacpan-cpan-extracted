use strict;
use warnings;

use Test::More;
use Module::Runtime 'require_module';

use lib 'xt/lib';

foreach my $package (qw(Dirty SubDirty Clean SubClean ExporterModule SubExporterModule))
{
    require_module($package);
    ok($package->can($_), "can do $package->$_") foreach @{ $package->CAN };
    ok(!$package->can($_), "cannot do $package->$_") foreach @{ $package->CANT };
}

ok(!exists($INC{'Class/MOP.pm'}), 'Class::MOP has not been loaded');

done_testing;
