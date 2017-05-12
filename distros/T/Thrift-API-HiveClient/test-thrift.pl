#!/usr/bin/env perl
use lib 'lib';
use Data::Dumper;
use Try::Tiny;
use Thrift::API::HiveClient;
#use Moose;

my ($host, $port) = (localhost => 10000);
 
try sub {
  my $client = Thrift::API::HiveClient->new( host => $host, port => $port );
  $client->connect;
  print "Connected\n";
  $client->execute(
    q{ create table if not exists t_foo (foo STRING, bar STRING) }
  );
  $client->execute('show tables');
  print Dumper $client->fetchAll;
  print Dumper $client->getClusterStatus;
  print Dumper $client->get_fields( 'default', 't_foo');
},
catch sub {
  print "ZOMG\n";
  print Dumper($_);
  exit 1;
};

