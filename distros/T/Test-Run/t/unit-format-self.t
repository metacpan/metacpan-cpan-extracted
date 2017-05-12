#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

package MyClass;

use Moose;

extends ('Test::Run::Base');

package main;

{
    my $obj = MyClass->new();

    # TEST
    is (
        $obj->_format_self(
            (\"Hello %(name)s! Welcome to %(country)s!"),
            { name => "Sophie", country => "Israel", },
        ),
        "Hello Sophie! Welcome to Israel!",
        "_format_self works fine with extra args."
    );
}

