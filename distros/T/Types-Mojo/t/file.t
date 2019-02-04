#!/usr/bin/env perl

use strict;
use warnings;

use Test::Spec;

use File::Basename;
use lib dirname(__FILE__);

use TestClass;
use Mojo::File;

describe 'MojoFile' => sub {
    it 'accepts a Mojo::File object' => sub {
        my $obj = TestClass->new( file => Mojo::File->new(__FILE__) );
        isa_ok $obj->file, 'Mojo::File';
        is $obj->file->basename, basename(__FILE__);
    };

    it 'coerces a string' => sub {
        my $obj = TestClass->new( file => __FILE__ );
        isa_ok $obj->file, 'Mojo::File';
        is $obj->file->basename, basename(__FILE__);
    };
};


runtests if !caller;
