#!/usr/bin/perl -w
use strict;
use lib './inc';
use IO::Catch;

use File::Temp qw( tempfile );
our ($_STDOUT_, $_STDERR_);

# pre-5.8.0's warns aren't caught by a tied STDERR.
tie *STDOUT, 'IO::Catch', '_STDOUT_' or die $!;
tie *STDERR, 'IO::Catch', '_STDERR_' or die $!;

use Test::More tests => 7;

# Disable all ReadLine functionality
$ENV{PERL_RL} = 0;

use_ok('WWW::Mechanize::Shell');

sub command_ok {
  my ($command,$expected,$name) = @_;
  my $s = WWW::Mechanize::Shell->new( 'test', rcfile => undef, warnings => undef );
  $s->agent->get("file:t/17-eval-multiline.t");
  eval { $s->cmd($command) };
  is($@,"","$name does not crash")
      or diag "Crash on '$command'";
  is($_STDERR_,undef,"$name produces no warnings");
  is($_STDOUT_,$expected,"$name produces the desired output")
      or diag "Command: '$command'";
  undef $_STDOUT_;
  undef $_STDERR_;
};

command_ok('eval "Hello",
 " World"', "Hello World\n","Multiline eval");
command_ok('eval "Hello from ",
 $self->agent->uri || ""', "Hello from file:t/17-eval-multiline.t\n","Multiline eval substitution");
