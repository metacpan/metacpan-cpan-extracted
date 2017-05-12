#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 8;

my $pkg;

BEGIN {
    $pkg = 'WebService::iThenticate::Request';
    use_ok( $pkg );
}

can_ok( $pkg, qw( new validate _int _boolean _string ) );

diag( 'test constructor' );

my %auth = ( username => 'username',
    password => 'password' );

my $request = WebService::iThenticate::Request->new( { method => 'login',
        auth => \%auth } );

isa_ok( $request, $pkg );

isa_ok( $request->{rpc_request}, 'RPC::XML::request' );

# test an invalid argument

eval { $request = WebService::iThenticate::Request->new( { method => 'document.get',
            auth => \%auth } ) };
like( $@, qr/required arg id/, 'id missing' );

eval { $request = WebService::iThenticate::Request->new( { method => 'document.get',
            auth => \%auth, req_args => { id => 'foo' } } ) };
like( $@, qr/integer/, 'invalid integer' );

eval { $request = WebService::iThenticate::Request->new( { method => 'folder.add',
            auth => \%auth, req_args => {
                name           => 'test',
                description    => 'string',
                folder_group   => 1,
                exclude_quotes => 'oops, not a boolean', } } ) };

like( $@, qr/boolean/, 'invalid boolean' );

eval { $request = WebService::iThenticate::Request->new( { method => 'folder.add',
            auth => \%auth, req_args => {
                name           => 'test',
                description    => 'string',
                folder_group   => 1,
                exclude_quotes => 't', } } ) };

isa_ok( $request, $pkg );

