#!/usr/bin/perl

use strict;
use warnings;

use lib "./t/lib";

use Test::More tests => 1;
use Test::Run::Trap::Obj;

package MyPersonClass;

use Moose;

has 'name' => (is => "rw", isa => "Str");
has 'favourite_dish' => (is => "rw", isa => "Str");

sub print_info
{
    my $self = shift;

    print "<<My name is " . $self->name() . " and I like " . $self->favourite_dish(). ">>\n";
}

package main;

{
    my $got = Test::Run::Trap::Obj->trap_run({
            class => "MyPersonClass",
            args =>
            [
                name => "Sophie",
                favourite_dish => "Apples",
            ],
            run_func => "print_info",
        });

    # TEST
    $got->field_like("stdout",
        qr{\Q<<My name is Sophie and I like Apples>>\E},
        "Testing setting run_func() to something.",
    );
}
