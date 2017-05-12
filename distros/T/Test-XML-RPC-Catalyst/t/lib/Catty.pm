package Catty;

use Catalyst qw/Server Server::XMLRPC/;

use strict;
use warnings;

__PACKAGE__->config (name => 'Catty');

__PACKAGE__->setup;

sub foo : XMLRPC {
  my ($self,$c,$arg) = @_;

  $c->stash->{xmlrpc} = $arg;

  return;
}

1;

