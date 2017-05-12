use strict;
use warnings;

use Test::More tests => 1;

use File::Spec;

use Test::Run::Trap::Obj;

BEGIN
{
    $SIG{__WARN__} = sub { die $_[0] };
}

package MyTestRun;

use Moose;
extends("Test::Run::Obj");

use MRO::Compat;


sub _init_strap
{
    my ($self, $args) = @_;
    $self->next::method($args);

    my $test_file = $args->{test_file};

    if ($test_file =~ /\.mok\z/)
    {
        $self->Strap()->Test_Interpreter(
            "$^X " .
            File::Spec->catfile(
                File::Spec->curdir(), "t", "data", "interpreters",
                "wrong-mini-ok.pl"
            ).
            " "
        );
        $self->Strap()->Switches("");
        $self->Strap()->Switches_Env("");
    }
}

package main;

{
    my $got = Test::Run::Trap::Obj->trap_run({
            class => "MyTestRun",
            args =>
            [
                test_files =>
                [
                    "t/sample-tests/simple",
                    "t/sample-tests/success1.mok",
                ],
            ],
        });

    # TEST
    $got->field_unlike("stderr", qr/sprintf/,
        "No warning for undefined sprintf argument was emitted."
    );
}

