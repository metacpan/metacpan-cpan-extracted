#!/usr/bin/env perl

use strict;
use warnings;

use Test::Spec;

use File::Basename;
use lib dirname(__FILE__);

use TestClass;
use Mojo::File;

describe 'MojoFileList' => sub {
    it 'accepts a Mojo::Collection object' => sub {
        my $obj = TestClass->new( fl => Mojo::Collection->new(Mojo::File->new(__FILE__)) );
        isa_ok $obj->fl, 'Mojo::Collection';
        is_deeply $obj->fl->to_array, [__FILE__];
    };

    it 'coerces an arrayref' => sub {
        my $obj = TestClass->new( fl => [Mojo::File->new(__FILE__)] );
        isa_ok $obj->fl, 'Mojo::Collection';
        is_deeply $obj->fl->to_array, [__FILE__];
    };

    it 'coerces an arrayref of strings' => sub {
        my $obj = TestClass->new( fl => [__FILE__] );
        isa_ok $obj->fl, 'Mojo::Collection';
        is_deeply $obj->fl->to_array, [__FILE__];
        isa_ok $obj->fl->to_array->[0], 'Mojo::File';
    };
};


runtests if !caller;
