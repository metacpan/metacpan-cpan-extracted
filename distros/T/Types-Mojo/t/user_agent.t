#!/usr/bin/env perl

use strict;
use warnings;

use Test::Spec;

use File::Basename;
use lib dirname(__FILE__);

use TestClass;
use Mojo::UserAgent;

describe 'MojoUserAgent' => sub {
    it 'accepts a Mojo::UserAgent object' => sub {
        my $obj = TestClass->new( ua => Mojo::UserAgent->new );
        isa_ok $obj->ua, 'Mojo::UserAgent';
    };
};


runtests if !caller;
