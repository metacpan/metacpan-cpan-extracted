#!/usr/bin/env perl

use strict;
use warnings;

use Test::Spec;

use File::Basename;
use lib dirname(__FILE__);

use TestClass;
use Mojo::Collection;
use Types::Mojo qw(MojoCollection);

describe 'MojoCollection' => sub {
    it 'accepts a Mojo::Collection object' => sub {
        my $obj = TestClass->new( coll => Mojo::Collection->new(qw(a b)) );
        isa_ok $obj->coll, 'Mojo::Collection';
        is_deeply $obj->coll->to_array, [qw/a b/];
    };

    it 'coerces an arrayref' => sub {
        my $obj = TestClass->new( coll => [qw/a b/] );
        isa_ok $obj->coll, 'Mojo::Collection';
        is_deeply $obj->coll->to_array, [qw/a b/];
    };

    it 'parameterizned with "Int" to accept only integers' => sub {
        my $check  = MojoCollection["Int"];
        my $return = $check->(Mojo::Collection->new(1..10));
        ok $return;

        my $error = '';
        my $str_return;
        eval {
            $str_return = $check->( Mojo::Collection->new('a') );
        } or $error = $@;

        ok !$str_return;
        like $error, qr/did not pass/;

        $error = '';
        my $mix_return;

        eval {
            $mix_return = $check->( Mojo::Collection->new(1, 2, 3, 'a') );
        } or $error = $@;

        ok !$mix_return;
        like $error, qr/did not pass/;
    };

    it '"ints" accept only integers -> ok' => sub {
        my $error = '';
        eval {
            my $obj = TestClass->new( ints => [1..3] );
        } or $error = $@;

        is $error, '';
    };

    it '"ints" accept only integers -> fails' => sub {
        my $error = '';
        eval {
            my $obj = TestClass->new( ints => [1..3,'a'] );
        } or $error = $@;

        like $error, qr/did not pass/;
    };
};


runtests if !caller;
