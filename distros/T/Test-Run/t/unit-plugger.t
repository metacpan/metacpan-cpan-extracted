#!/usr/bin/perl

use strict;
use warnings;

use lib "./t/lib";

use Test::More tests => 2;

package MyClass;

use Moose;

extends ('Test::Run::Base::PlugHelpers');

package main;

{
    my $class =
        Test::Run::Base::Plugger->new(
            {
                base => "MyClass::Base",
                into => "MyClass::Into",
            }
        );

    # TEST
    ok ($class, "Object was instantiated");

    eval {
    $class->add_plugins([qw(I::DONT::Know::This::Module::Oh::Really::AMB_FDF)]);
    };

    my $Err = $@;

    # TEST
    ok ($Err, "An error was thrown");
}

