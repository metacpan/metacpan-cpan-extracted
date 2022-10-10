#!/usr/bin/env perl

use strict;
use warnings;

use Benchmark;
use Text::HyperScript::HTML5;

timethis(
    100000,
    sub {
        main( h1('Hi,'), p( 'this is a benchmark of ', a( { href => 'https://metacpan.org/pod/Text::HyperScript' }, 'Text::HyperScript' ), ' module.' ) );
    }
);
