package Zabbix::Reporter::Web::Plugin::Selftest;
{
  $Zabbix::Reporter::Web::Plugin::Selftest::VERSION = '0.07';
}
BEGIN {
  $Zabbix::Reporter::Web::Plugin::Selftest::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: Zabbix Server Selftest

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
# use Try::Tiny;
use IO::Socket::INET;

# extends ...
extends 'Zabbix::Reporter::Web::Plugin';
# has ...
has 'zabbix_server_address' => (
   'is'     => 'ro',
   'isa'    => 'Str',
   'lazy'   => 1,
   'builder'   => '_init_zabbix_server_address',
);
# with ...
# initializers ...
sub _init_fields { return [qw()]; }

sub _init_alias { return 'healthcheck'; }

sub _init_zabbix_server_address { return 'localhost'; }

# your code here ...
sub execute {
   my $self = shift;
   my $request = shift;

   my $body;
   my $status = 200;

   if($self->_check_db_ping()) {
      $body .= "OK - DB Connection is working\n";
   } else {
      $body .= "ERROR - DB connection not working!\n";
      $status = 503;
   }

   # Make sure there were any event during the last 5 minutes
   if($self->_check_db_count('SELECT COUNT(*) FROM events WHERE clock >= UNIX_TIMESTAMP(NOW())-300')) {
      $body .= "OK - Some events during the last 5 minutes\n";
   } else {
      $body .= "ERROR - No events during the last 5 minutes\n";
      $status = 503;
   }

   # Make sure there was at least on trigger event in the last 24h
   if($self->_check_db_count('SELECT COUNT(*) FROM triggers AS t WHERE t.lastchange > UNIX_TIMESTAMP(NOW() - INTERVAL 1 DAY)')) {
      $body .= "OK - Some events during the last 5 minutes\n";
   } else {
      $body .= "ERROR - No events during the last 5 minutes\n";
      $status = 503;
   }


   # Make sure the server process is listening on port 10051
   if($self->_check_open_port(10051)) {
      $body .= "OK - Server is listening on port 10051\n";
   } else {
      $body .= "ERROR - Server is not listening on port 10051\n";
      $status = 503;
   }

    return [ $status, [
      'Content-Type', 'text/plain',
      'Cache-Control', 'no-store, private', # no caching for the selftest
    ], [$body] ];
}

sub _check_open_port {
   my $self = shift;
   my $port = shift || 10051;

   my $sock = IO::Socket::INET::->new(
      Proto    => 'tcp',
      PeerAddr => $self->zabbix_server_address(),
      PeerPort => $port,
      Timeout  => 10,
   );

   if($sock) {
      close($sock);
      return 1;
   }

   return;
}

sub _check_db_ping {
   my $self = shift;

   if($self->zr()->dbh()->ping()) {
      return 1;
   }

   return;
}

sub _check_db_count {
   my $self = shift;
   my $sql  = shift;

   if(!$sql) {
      return;
   }

   my $sth = $self->zr()->dbh()->prepare($sql);
   if(!$sth) {
      return;
   }
   if(!$sth->execute()) {
      return;
   }
   my $count = $sth->fetchrow_array();

   if($count > 0) {
      return 1;
   }

   return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Zabbix::Reporter::Web::Plugin::Selftest - Zabbix Server Selftest

=head1 METHODS

=head2 execute

Perform an Zabbix Server Selftest/Healthcheck

=head1 NAME

Zabbix::Reporter::Web::API::Plugin::Selftest - Perform an Zabbix Server Selftest

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
