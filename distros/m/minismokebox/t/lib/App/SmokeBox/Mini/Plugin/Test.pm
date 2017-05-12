package App::SmokeBox::Mini::Plugin::Test;

use strict;
use warnings;
use Test::More;
use POE;

our $VERSION = '0.20';

sub init {
  my $package = shift;
  my $config  = shift;
  ok( $config, 'Got called with a config' );
  POE::Session->create(
     package_states => [
        $package => [qw(_start sbox_perl_info sbox_smoke sbox_stop)],
     ],
  );
}

sub _start {
  my ($kernel,$session) = @_[KERNEL,SESSION];
  $kernel->refcount_increment( $session->ID, __PACKAGE__ );
  return;
}

sub sbox_perl_info {
  my ($version,$archname) = @_[ARG0,ARG1];
  ok( $version, 'Got version info' );
  ok( $archname, 'Got archname info' );
  diag("v$version $archname\n");
  return;
}

sub sbox_stop {
  my ($kernel,$session,@stats) = @_[KERNEL,SESSION,ARG0..$#_];
  is( scalar @stats, 8, 'Got the right number of stats entries' );
  $kernel->refcount_decrement( $session->ID, __PACKAGE__ );
  return;
}

sub sbox_smoke {
  my ($kernel,$data) = @_[KERNEL,ARG0];
  ok( $data, 'Got some data, dude' );
  diag($data->{job}->module(), "\n");
  return;
}

1;

__END__
