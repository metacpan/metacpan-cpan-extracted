#!/usr/bin/env perl

use strict;
use Warnings::Version '5.22';
use feature 'refaliasing';

my @aoh = ( {foo => 'bar'}, {baz => 'quux'});
for \my %h (@aoh) { my @keys = keys %h; }
