#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 3;
use blib;

my $capture;
my $no_ics = 0;

{
  eval { require IO::Capture::Stdout; };
  $no_ics = 1, last if $@;

  # printf() not tied in IO::Capture::Stdout at time of writing

  unless (defined &IO::Capture::Tie_STDx::PRINTF)
  {
    *IO::Capture::Tie_STDx::PRINTF = sub
    {
      my $self   = shift;
      my $format = shift;
      $self->PRINT( sprintf( $format, @_ ) );
    };
  }
  $capture = IO::Capture::Stdout->new();
  $capture->start;
}


END
{
  SKIP: {
    skip "IO::Capture::Stdout not installed", 1 if $no_ics;
    use File::Basename;
    my $prog = basename($0);
    my $first = qr/\s*[\d.]+ Timeticker for $prog starting/;
    my $last  = qr/\s*[\d.]+ Timeticker for $prog finishing/;
    $capture->stop;
    like(join('', $capture->read), qr/^$first\n\s*[\d.]+ TEST\n$last$/,
         'Output');
  }
}

BEGIN { use_ok("Time::TimeTick") }

my $t_e_installed;
BEGIN {
  $t_e_installed = eval 'require Test::Exception' and Test::Exception->import;
}

SKIP: {
  $t_e_installed or timetick("TEST"), skip "Test::Exception not installed", 1;
  lives_ok { timetick("TEST") }
}


