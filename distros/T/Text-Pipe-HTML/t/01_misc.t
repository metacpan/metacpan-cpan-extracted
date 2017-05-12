#!/usr/bin/env perl
use warnings;
use strict;
use Text::Pipe;
use HTML::Entities;
use Test::More tests => 3;
my $enc_pipe  = Text::Pipe->new('HTML::EncodeEntities');
my $dec_pipe  = Text::Pipe->new('HTML::DecodeEntities');
my $idem_pipe = $dec_pipe | $enc_pipe;
my $s1        = my $s2 = "V&aring;re norske tegn b&oslash;r &aelig;res";
decode_entities($s1);
is($dec_pipe->filter($s2),  $s1, 'decode entities');
is($enc_pipe->filter($s1),  $s2, 'encode entities');
is($idem_pipe->filter($s2), $s2, 'decode + encode again');
