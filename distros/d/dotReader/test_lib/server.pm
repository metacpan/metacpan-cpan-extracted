package test_lib::server;

require('./util/anno_server');
use Test::HTTP::Server::Simple;
our @ISA = qw(Test::HTTP::Server::Simple dtRdr::anno_server);

use constant USE_PORT => 8086; # needs to be dynamic to run in parallel

sub new {
  my $self = shift;
  my (%args) = @_;
  $self->SUPER::new(
    port => $self->USE_PORT,
    %args
  );
}

# vim:ts=2:sw=2:et:sta
