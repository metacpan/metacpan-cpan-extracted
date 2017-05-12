#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

package MyClass;

use Moose;

extends ('Test::Run::Base::PlugHelpers');

package main;

{
    my $obj = MyClass->new();
    eval
    {
        $obj->register_pluggable_helper(
            {
                id => "foo",
                base => "MyClass::Foo",
            },
        );
    };

    my $Err = $@;

    # TEST
    like ($Err, qr{\A\s*'?"collect_plugins_method" not specified},
        "Missing collect_plugins_method",
    );
}

{
    my $obj = MyClass->new();
    eval
    {
        $obj->register_pluggable_helper(
            {
                base => "MyClass::Sophie",
                collect_plugins_method => "collector",
            },
        );
    };

    my $Err = $@;

    # TEST
    like ($Err, qr{\A\s*'?"id" not specified},
        "Missing id",
    );
}

{
    my $obj = MyClass->new();
    eval
    {
        $obj->register_pluggable_helper(
            {
                id => "quux",
                collect_plugins_method => "collector",
            },
        );
    };

    my $Err = $@;

    # TEST
    like ($Err, qr{\A\s*'?"base" not specified},
        "Missing id",
    );
}

{
    my $obj = MyClass->new();
    $obj->register_pluggable_helper(
        {
            id => "foo",
            base => "MyClass::Foo",
            collect_plugins_method => "collector",
        },
    );

    my $result;
    eval
    {
        $result = $obj->create_pluggable_helper_obj({id => "unknown"});
    };
    my $Err = $@;

    # TEST
    like ($Err, qr{\AUnknown Pluggable Helper ID},
        "Missing collect_plugins_method",
    );
}
