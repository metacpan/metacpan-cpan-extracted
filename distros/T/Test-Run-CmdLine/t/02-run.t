#!/usr/bin/perl

use strict;
use warnings;

use lib "./t/lib";

use Test::More tests => 5;

use Test::Run::CmdLine::Iface;
use Test::Run::CmdLine::Drivers::CmdLineTest;
use Test::Run::Drivers::CmdLineTest;

{
    local %ENV=%ENV;
    delete $ENV{HARNESS_DRIVER};

    {
        my $iface = Test::Run::CmdLine::Iface->new();

        # TEST
        is ($iface->driver_class(), "Test::Run::CmdLine::Drivers::Default",
            "Right default driver_class");

    }

    {
        local $ENV{HARNESS_DRIVER} = "Foo::Bar";
        my $iface = Test::Run::CmdLine::Iface->new();

        # TEST
        is ($iface->driver_class(), "Foo::Bar",
            "Right driver_class set from ENV");
    }

    {
        local @Test::Run::CmdLine::Drivers::CmdLineTest::ISA;
        local @Test::Run::Drivers::CmdLineTest::ISA;
        my $iface = Test::Run::CmdLine::Iface->new(
            {
                'driver_class' => "Test::Run::CmdLine::Drivers::CmdLineTest",
                'test_files' => [qw(one.t TWO tHREE)],
            }
        );
        # TEST
        is ($iface->driver_class(), "Test::Run::CmdLine::Drivers::CmdLineTest",
            "Right driver_class set from ENV");

        my $got = $iface->run();
        # TEST
        is_deeply($got, +{'tested' => [qw(one.t TWO tHREE)] },
            "Returns what you want.");
    }
    {
        local @Test::Run::CmdLine::Drivers::CmdLineTest::ISA;
        local @Test::Run::Drivers::CmdLineTest::ISA;
        my $iface = Test::Run::CmdLine::Iface->new(
            {
                'driver_plugins' => [qw(FooField BarField StupidRunTests)],
                'test_files' => [qw(one.t TWO tHREE)],
            }
        );

        my $got = $iface->run();
        # TEST
        is_deeply($got,
            +{'tested' => [qw(one.t TWO tHREE)],
              'foo' => "myfoo",
              'bar' => "habar sheli",
            },
            "Returns what you want.");

    }
}

1;

