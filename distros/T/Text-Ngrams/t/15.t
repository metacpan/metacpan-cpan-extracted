#!/usr/bin/perl

use Test::More tests => 2;
BEGIN { use_ok("Text::Ngrams", qw(encode_S decode_S)) }
require 't/auxfunctions.pl';

use strict;

my $ng = Text::Ngrams->new( type => "byte", windowsize=>5);
$ng->process_text('abc');
#$ng->to_string(spartan=>1, 'out' => 't/15.out');
isn('t/15.out',$ng->to_string(spartan=>1, 'out' => 't/15.out'));
