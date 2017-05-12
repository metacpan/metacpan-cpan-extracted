#!/usr/bin/perl

use strict;
use warnings;

use lib "./t/lib";

use Test::More tests => 2;

use Test::Run::CmdLine::Iface;
use Test::Run::CmdLine::Drivers::CmdLineTest;
use Test::Run::Drivers::CmdLineTest;

{
    local %ENV=%ENV;
    delete $ENV{HARNESS_DRIVER};

    {

        my $iface = Test::Run::CmdLine::Iface->new(
            {
                'driver_class' => "Test::Run::CmdLine::Drivers::CollectPluginsZedBar",
                'driver_plugins' => [qw(ZedField BarFieldWithAccum)],
                'test_files' => [qw(one.t TWO tHREE)],
            }
        );

        my $driver = $iface->_calc_driver();

        # TEST
        is_deeply(
            $driver->backend_plugins(),
            [qw(ZedField BarField)],
            "Testing the plugins' collection - Zed + Bar",
        );
    }

    {
        my $iface = Test::Run::CmdLine::Iface->new(
            {
                'driver_class' => "Test::Run::CmdLine::Drivers::CollectPluginsBarZed",
                'driver_plugins' => [qw(BarFieldWithAccum ZedField)],
                'test_files' => [qw(one.t TWO tHREE)],
            }
        );

        my $driver = $iface->_calc_driver();

        # TEST
        is_deeply(
            $driver->backend_plugins(),
            [qw(BarField ZedField)],
            "Testing the plugins' collection - Bar + Zed",
        );
    }
}

1;

