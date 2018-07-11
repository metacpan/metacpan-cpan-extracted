package testcases::Web::WebMath;
use strict;
use XAO::Utils;
use XAO::Web;
use Data::Dumper;

use base qw(XAO::testcases::Web::base);

###############################################################################

sub test_all {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Math');

    my %matrix=(
        t01 => {
            args    => { formula => '2+2' },
            expect  => '4',
        },
        t02 => {
            args    => { formula => '2 + {x}', 'value.x' => 2 },
            expect  => '4',
        },
        t03 => {
            args    => { formula => '{x}+ {x} / {y}', 'value.x' => 1, 'value.y' => 2, format => '%.2f' },
            expect  => '1.50',
        },
        t04 => {
            args    => { formula => '{foo}/{bar}-1e2', 'value.foo' => 10, 'value.bar' => 5, format => '%-8.2f' },
            expect  => '-98.00  ',
        },
        t05 => {
            args    => { formula => '{x} + {y} * {z}', 'value.x' => '1', 'value.y' => '2', 'value.z' => '3' },
            expect  => '7',
        },
        t06 => {
            args    => { formula => '{x} + ({y} * {z})', 'value.x' => '1', 'value.y' => '2', 'value.z' => '3' },
            expect  => '7',
        },
        t07 => {
            args    => { formula => '({x} + {y}) * {z}', 'value.x' => '1', 'value.y' => '2', 'value.z' => '3' },
            expect  => '9',
        },
        #
        t10 => {
            args    => { formula => 'sqrt( {ten} )', 'value.ten' => 10.0, format => '%.5f' },
            expect  => '3.16228',
        },
        t11 => {
            args    => { formula => 'min({a},{b})', 'value.a' => 123.45, 'value.b' => '234.5' },
            expect  => '123.45',
        },
        t12 => {
            args    => { formula => 'max({a},{b},{c})', 'value.a' => 3, 'value.b' => '2', 'value.c' => '4' },
            expect  => '4',
        },
        t13 => {
            args    => { formula => 'sum({a},{b},{c})', 'value.a' => 3, 'value.b' => '2', 'value.c' => '4' },
            expect  => '9',
        },
        t14 => {
            args    => { formula => 'abs({a} / {b})', 'value.a' => '-17.34', 'value.b' => '7', format => '%8.4f' },
            expect  => '  2.4771',
        },
        #
        t20 => {
            args    => { formula => 'asdasd' },
            expect  => '',
        },
        t21 => {
            args    => { formula => 'kill(1)', template => '<$RESULT$>:<$ERRCODE$>' },
            expect  => ':FUNCTION',
        },
        t22 => {
            args    => { formula => 'exit(1)', template => '<$RESULT$>:<$ERRCODE$>' },
            expect  => ':FUNCTION',
        },
        t23 => {
            args    => { formula => 'sqrt({x})', 'value.x' => '-4', template => '<$RESULT$>:<$ERRCODE$>' },
            expect  => ':CALCULATE',
        },
        t24 => {
            args    => { formula => '7/({x} + {y})', 'value.x' => '3', 'value.y' => '-3', template => '<$RESULT$>:<$ERRCODE$>' },
            expect  => ':CALCULATE',
        },
        t25 => {
            args    => { formula => '7/({x} + {y})', 'value.x' => '3', 'value.y' => '-3', default => 'NaN' },
            expect  => 'NaN',
        },
    );

    foreach my $tname (sort keys %matrix) {
        dprint "===> $tname";

        my $args=$matrix{$tname}->{'args'};

        my $expect=$matrix{$tname}->{'expect'};

        my $got=$page->expand($args);

        $self->assert($got eq $expect,
                      "Test $tname failed - expected '$expect', got '$got'");
    }
}

###############################################################################
1;
