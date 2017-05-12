#!/usr/bin/perl -w
use strict;

use Test::More tests => 2;

BEGIN {
  # Choose a nonannoying HTML displayer:
  $ENV{PERL_HTML_DISPLAY_CLASS} = 'HTML::Display::Dump';
  # Disable all ReadLine functionality
  $ENV{PERL_RL} = 0;
  use_ok('WWW::Mechanize::Shell');
};

my $s = WWW::Mechanize::Shell->new( 'test', rcfile => undef, warnings => undef );

# Now test
eval { $s->cmd('browse'); };
is($@, "", "Browsing without requesting anything does not crash the shell");

