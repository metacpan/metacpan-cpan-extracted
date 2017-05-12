#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use Test::Run::Trap::Obj;
use Test::Run::Plugin::ColorFileVerdicts;

package MyTestRun::Plugin1;

our @ret = ();

# See that this method runs.
sub _init_strap
{
    my ($self, $args) = @_;

    $self->next::method($args);

    push @ret, "_init_strap called";
}

package MyTestRun;

our @ISA = qw(Test::Run::Plugin::ColorFileVerdicts MyTestRun::Plugin1 Test::Run::Obj);

package main;

{
    my $got = Test::Run::Trap::Obj->trap_run(
        {
            class => "MyTestRun",
            args =>
            [
            test_files =>
            [
                "t/sample-tests/one-ok.t",
            ],
            ]
        }
        );

    # TEST
    is_deeply (
        \@MyTestRun::Plugin1::ret,
        ["_init_strap called"],
        "_init_strap of the plugin was called"
    );
}
