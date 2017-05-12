#!/usr/bin/perl -w
use strict;
use lib './inc';
use IO::Catch;
use File::Temp qw( tempfile );

# pre-5.8.0's warns aren't caught by a tied STDERR.
tie *STDOUT, 'IO::Catch', '_STDOUT_' or die $!;

use Test::More tests => 2;

# Disable all ReadLine functionality
$ENV{PERL_RL} = 0;

SKIP: {
#skip "Can't load Term::ReadKey without a terminal", 2
#  unless -t STDIN;
#eval { require Term::ReadKey; Term::ReadKey::GetTerminalSize(); };
#if ($@) {
#  no warnings 'redefine';
#  *Term::ReadKey::GetTerminalSize = sub {80,24};
#  diag "Term::ReadKey seems to want a terminal";
#};

use_ok('WWW::Mechanize::Shell');

# Silence all warnings
my $s = WWW::Mechanize::Shell->new( 'test', rcfile => undef, warnings => undef );

eval {
  $s->cmd('this_command_does_not_exist');
};
is($@,"","An unknown command does not crash the shell");
};


