#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use lib "./t/lib";

use Cwd;
use File::Spec;

use List::Util ();

use Test::Run::CmdLine::Iface;
use Test::Run::CmdLine::Drivers::CmdLineTest;
use Test::Run::Drivers::CmdLineTest;


my $abs_cur = getcwd();
my $yaml_test_file =
    File::Spec->catfile($abs_cur, "t", "data", "yaml-test.yml")
    ;

{
    local %ENV=%ENV;
    delete $ENV{HARNESS_DRIVER};
    local $ENV{"TEST_RUN_YAML_TEST"} = $yaml_test_file;

    {

        my $iface = Test::Run::CmdLine::Iface->new(
            {
                'driver_class' => "Test::Run::CmdLine::Drivers::CollectPluginsZedBar",
                'driver_plugins' => [qw(YamlTest)],
                'test_files' => [qw(one.t TWO tHREE)],
            }
        );

        my $driver = $iface->_calc_driver();

        my $backend_args = $driver->get_backend_args();
        my $value = {};
        BACKEND_ARGS:
        for (my $idx = 0 ; $idx < @$backend_args ; $idx+= 2)
        {
            if ($backend_args->[$idx] eq "yaml_test")
            {
                $value = $backend_args->[$idx+1];
                last BACKEND_ARGS;
            }
        }

        # TEST
        is_deeply(
            $value,
            {
                first => "John",
                'last' => "Locke",
                'profession' => "philosopher",
            },
            "Testing that the value was found and is OK.",
        );
    }
}

1;

