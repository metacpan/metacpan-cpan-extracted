use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Module::Runtime 'require_module';

use lib 'xt/lib';

foreach my $package (qw(Overloader))
{
    require_module($package);
    ok($package->can($_), "can do $package->$_") foreach @{ $package->CAN };
    ok(!$package->can($_), "cannot do $package->$_") foreach @{ $package->CANT };

    my $obj = $package->new(val => 42);

    is("$obj", '42', 'string overload works');
    is($obj + 1, 43, 'numeric overload works');
}

done_testing;
