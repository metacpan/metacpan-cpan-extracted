package t::Util;

use strict;
use warnings;
use Test::PostgreSQL::Docker;
use Data::Dumper;

my $REP = $ENV{PERL_TEST_PG_DOCKER_REP} || 'postgres';
my $TAG = $ENV{PERL_TEST_PG_DOCKER_TAG} || '12-alpine';

sub default_args_for_new {
    return (pgname => $REP, tag => $TAG);
}

sub new_server {
    my ( $class, %opt ) = @_;
    my $obj;

    if ( my $json = $ENV{__PERL_TEST_PG_DOCKER} ) {
        eval { require JSON::PP; 1 };
        $obj = JSON::PP::decode_json($json);
    }

    my $server;
    my %name = (dbowner => 'postgres', dbname => 'test', %opt);
    my $name = join(':', map { $name{$_} } sort qw/dbowner dbname/ );

    if ($obj && $obj->{$name}) {
        return bless { %{$obj->{$name}} }, 'Test::PostgreSQL::Docker';
    }

    $server = Test::PostgreSQL::Docker->new(default_args_for_new(), %opt);

    return $server->run(skip_pull => 1);
}


# PERL5LIB=./lib:./t/lib prove -I./lib -Pt::Util t

sub load {
    eval { require JSON::PP; 1 } or return;
    my $env = $ENV{__PERL_TEST_PG_DOCKER};

    our $loaded_server  = t::Util->new_server();

    print STDERR $@;

    $env = $env ? JSON::PP::decode_json($env) : {};

    my $name = join(':', @{$loaded_server}{sort qw/dbowner dbname/} );

    $ENV{__PERL_TEST_PG_DOCKER} = JSON::PP::encode_json( {
        %$env, $name => {
            map { $_ => $loaded_server->{$_} } qw/docker pgname tag oid dbowner password dbname port host print_docker_error docker_is_running _orig_address/
        }
    }) if $loaded_server;
}


1;
