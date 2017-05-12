#!/usr/bin/perl -w
use strict;
use lib './inc';
use IO::Catch;

use vars qw( @comments $_STDOUT_ $_STDERR_ );

# pre-5.8.0's warns aren't caught by a tied STDERR.
tie *STDOUT, 'IO::Catch', '_STDOUT_' or die $!;
tie *STDERR, 'IO::Catch', '_STDERR_' or die $!;

BEGIN { @comments = ( "#", "# a test", "#eval 1", "# eval 1", "## eval 1" )};

# Disable all ReadLine functionality
$ENV{PERL_RL} = 0;

use Test::More tests => 1 + scalar @comments * 3;
SKIP: {
#skip "Can't load Term::ReadKey without a terminal", 1 + scalar @comments * 3
#  unless -t STDIN;
#eval { require Term::ReadKey; Term::ReadKey::GetTerminalSize(); };
#if ($@) {
#  no warnings 'redefine';
#  *Term::ReadKey::GetTerminalSize = sub {80,24};
#  diag "Term::ReadKey seems to want a terminal";
#};

use_ok('WWW::Mechanize::Shell');

my $s = WWW::Mechanize::Shell->new( 'test', rcfile => undef, warnings => undef );

for (@comments) {
  $_STDOUT_ = "";
  $_STDERR_ = "";
  eval { $s->cmd($_); };
  is($@,"","Comment '$_' produces no error");
  is($_STDOUT_,"","Comment '$_' produces no output");
  is($_STDERR_,"","Comment '$_' produces no error output");
};

};


