#!/usr/bin/env perl

use Test::More tests => 12;

use lib '../lib';
use lib 'lib';
use lib 't/lib';

use Test::Wiretap;
use IO::Capture::Stdout; # local copy if not installed on system
use IO::Capture::Stderr; # ditto

sub _std_of {
  my ($class, $code) = @_;
  my $capture = $class->new;
  $capture->start;
  local $@;
  eval { $code->() };
  $capture->stop;
  die $@ if $@; 
  return join "\n", $capture->read;
}

sub stderr_of { return _std_of('IO::Capture::Stderr', @_) }
sub stdout_of { return _std_of('IO::Capture::Stdout', @_) }
sub assertion_of {
  my ($code) = @_;
  local $@;
  eval { $code->() };
  return $@;
}

{
  package SomePackage;
  sub function { 1 }
}

# bad arguments to ->new
# this is mostly testing that we delegate this stuff to our Test::Resub
{
  my $error = assertion_of(sub {
    my $wt = Test::Wiretap->new({
      name => 'SomePackage::function',
      call => 'dikaryophase-Muse-descended',
    });
    SomePackage::function();    # silence warnings about not being called
  });

  like( $error, qr/dikaryophase-Muse-descended/, 'error propagates up' );
  like( $error, qr/10-error-reporting.t/, "error is from caller's perspective" );

  $error = assertion_of(sub {
    my $wt = Test::Wiretap->new({
      name => 'SomePackage->function',     # not a function name!
    });
  });

  like( $error, qr/SomePackage->function/, 'bad function name gets noticed' );
  like( $error, qr/10-error-reporting.t/, "error is from caller's perspective" );

  # warnings about not getting called
  my $failure = stdout_of(sub {
    my $wt = Test::Wiretap->new({
      name => 'SomePackage::function',
    });
  });
  like( $failure, qr/not ok 1000/, "Test::Resub's error makes it through" );
  unlike( $failure, qr/Test::Wiretap/, "from perspective of caller" );
}

# can't ->return_values or ->return_contexts if you don't say 'capture'
{
  my $wt = Test::Wiretap->new({
    name => 'SomePackage::function',
    # no 'capture'
  });

  SomePackage::function();

  my $warning = stderr_of(sub { $wt->return_values });
  like( $warning, qr/'capture'/ );
  like( $warning, qr/return values/, 'error about ->return_values w/o capture' );
  unlike( $warning, qr/Test::Wiretap/, "caller's perspective" );

  $warning = stderr_of(sub { $wt->return_contexts });
  like( $warning, qr/'capture'/ );
  like( $warning, qr/return contexts/, 'error about ->return_contexts w/o capture' );
  unlike( $warning, qr/Test::Wiretap/, "caller's perspective" );
}
