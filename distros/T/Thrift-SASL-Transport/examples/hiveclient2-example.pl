#!/usr/bin/perl

use 5.14.2;
use strict;
use warnings;

# use the SASL thrift transport to talk to a hiveserver2 instance with kerberos
# auth enabled

use Data::Dumper;

# Since the Krb5 and SASL docs are as clear (to me and possibly others) as a
# black hole, here is a sample script that does work (CDH4.4 + Kerberos auth)

# part 1: getting a TGT and TGSs from scratch. You could also use kinit and
# skip this.

use Authen::Krb5;
Authen::Krb5::init_context();

my $user = $ENV{'USER'} . '@YOUR.REALM';
print "Password for $user: ";
my $password = <STDIN>;
chomp $password;

my $auth_ctx     = Authen::Krb5::AuthContext->new or die;
my $client_princ = Authen::Krb5::parse_name( $user ) or die;
my $cred_cache   = Authen::Krb5::cc_default() or die;

# this will destroy and recreate the default cache
$cred_cache->initialize($client_princ);
my $cred_princ = $cred_cache->get_principal;

my $client_cred = Authen::Krb5::get_init_creds_password( $client_princ, $password );
$cred_cache->store_cred($client_cred);

my $srv_host = 'your.hive.server2.fqdn';
my $req = Authen::Krb5::mk_req( $auth_ctx, 0, 'hive', $srv_host, undef, $cred_cache );

# part 2: use the crendentials cache we just created and pass it to the
# SASL-enabled hive client

use Authen::SASL qw(XS);
my $sasl = Authen::SASL->new( mechanism => 'GSSAPI');

use Thrift::Socket;
use Thrift::BufferedTransport;
use Thrift::SASL::Transport;
use Thrift::API::HiveClient2;

my $socket = Thrift::Socket->new( $srv_host, 10000 );
my $strans = Thrift::SASL::Transport->new( Thrift::BufferedTransport->new($socket), $sasl );

my $hive = Thrift::API::HiveClient2->new(
    _socket    => $socket,
    _transport => $strans,
);

my $rh = $hive->execute("show tables");

$Data::Dumper::Indent = 0;
print Dumper( $hive->fetch( $rh, 1000 ) );

