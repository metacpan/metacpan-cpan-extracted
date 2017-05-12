#!/usr/bin/env perl
use Test::More tests => 6;
use Web::API::Mapper;

my $api = Test::API->new;
my $routes = Web::API::Mapper->auto_route( $api , { prefix => 'foo' } );

ok( $routes->{get} );
ok( $routes->{post} );
ok( $routes->{any} );

my $m = Web::API::Mapper->new( "/foo" => $routes );
ok( $m );
my $ret = $m->dispatch( '/foo/get/id' , { data => 'John' } );

is_deeply( $ret->{args} , { data => 'John' } );
is( ref($ret->{self}) , 'Test::API' );

package Test::API;

sub new { bless {} , shift; }

sub foo_get_id {
    my ($self,$args) = @_;
    return {  
        self => $self,
        args => $args,
    };
}

sub foo_set_id {

}

1;
