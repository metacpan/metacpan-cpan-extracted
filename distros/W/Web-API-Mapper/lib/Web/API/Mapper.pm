package Web::API::Mapper;
use warnings;
use strict;
use Any::Moose;
use Web::API::Mapper::RuleSet;

our $VERSION = '0.04';

has route => ( is => 'rw' );

# post dispatcher
has post => ( is => 'rw' , default => sub { return Web::API::Mapper::RuleSet->new; } );

# get dispatcher
has get => ( is => 'rw' , default => sub { return Web::API::Mapper::RuleSet->new; } );

has any => ( is => 'rw' , default => sub { return Web::API::Mapper::RuleSet->new; } );

has fallback => ( is => 'rw' , isa => 'CodeRef' , default => sub {  sub {  } } );

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    if ( ! ref $_[0] && ref $_[1] eq 'HASH') {
        my $base = shift @_;
        my $route = shift @_;
        $class->$orig( base => $base , route => $route , @_);
    } else {
        $class->$orig(@_);
    }
};


sub BUILD {
    my ( $self , $args ) = @_;
    my $route = $args->{route};
    my $base  = $args->{base};
    $self->post( Web::API::Mapper::RuleSet->new( $base ,  $route->{post} ) ) if $route->{post};
    $self->get(Web::API::Mapper::RuleSet->new( $base , $route->{get} )) if $route->{get};
    $self->any(Web::API::Mapper::RuleSet->new( $base , $route->{any} )) if $route->{any};
}

sub mount {
    my ($self,$base,$route) = @_;
    for ( qw(post get any) ) {
        $self->$_->mount( $base => $route->{$_} ) if $route->{$_};
    }
    return $self;
}

sub auto_route {
    my ($class,$caller_package,$options) = @_;
    my $caller_class = ref $caller_package ? ref $caller_package : $caller_package;
    $options ||= {};
    my $routetype = $options->{type} || 'any';
    my $routes = {
        post => [],
        get => [],
        any => [],
    };
    no strict 'refs';
    while( my ($funcname,$b) = each %{ $caller_class . '::' } ) {
        next if $options->{prefix} && $funcname !~ /^@{[ $options->{prefix} ]}/;
        next if $options->{regexp} && $funcname !~ $options->{regexp};
        next if ! defined &$b;
        my $path = $funcname;
        $path =~ tr{_}{/};  # translate _ to /
        $path =~ s/^@{[ $options->{prefix} ]}//g if $options->{prefix};  # strip prefix if prefix defined.
        push @{ $routes->{ $routetype } }, $path , sub { return $b->( $caller_package , @_ ); };
    }
    return $routes;
}

sub dispatch {
    my ( $self, $path, $args ) = @_;

#     my $base = $self->base;
#     $path =~ s{^/$base/}{} if $base;

    my $ret;

    $ret = $self->any->dispatch( $path , $args );
    return $ret if $ret;

    $ret = $self->post->dispatch( $path , $args );
    return $ret if $ret;

    $ret = $self->get->dispatch( $path , $args );
    return $ret if $ret;

    return $self->fallback->( $args ) if $self->fallback;
    return;
}

1;
__END__

=head1 NAME

Web::API::Mapper - L<Web::API::Mapper> is an API (Application Programming Interface) convergence class for mapping/dispatching 
API to web frameworks.

=head1 SYNOPSIS

    package YourService;
    use Any::Moose;

    sub route { {
        post => [
            '/bar/(\d+)' => sub { my $args = shift;  return $1;  }
        ]
        get =>  [ 
            ....
        ]
    } }

    package main;

    my $service = YourService->new;
    my $serviceA = OtherService->new;
    $service->connect( ... );

    my $m = Web::API::Mapper->new
            ->mount( '/foo' => $service->route )
            ->mount( '/a' => $serviceA->route );

    my $ret = $m->post->dispatch( '/foo/bar' , { ... args ... } );
    my $ret = $m->get->dispatch(  '/foo/bar' );
    my $ret = $m->dispatch( '/foo/bar' , { args ... } );

    $m->post->mount( '/foo' , [ '/subpath/to' => sub {  ....  } ]);
    $m->mount( '/fb' => {  post => [  ... ] , get => [  ... ] }  )->mount( ... );

To generate API routing table automatically, see test file F<t/auto-router.t>:


#!/usr/bin/env perl
    use Test::More tests => 6;
    use Web::API::Mapper;

    my $api = Test::API->new;
    my $routes = Web::API::Mapper->auto_route( $api , { prefix => 'foo' } );

    ok( $routes->{get} );
    ok( $routes->{post} );
    ok( $routes->{any} );

    # The $routes will be:
    # {
    #     post => [ ],
    #     get => [ ],
    #     any => [
    #         '/get/id' => sub { DUMMY }
    #         '/get/id' => sub { DUMMY }
    #     ]
    # }

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


=head1 DESCRIPTION

L<Web::API::Mapper> is an API (Application Programming Interface) convergence class for mapping/dispatching 
API to web frameworks.

This module is for reducing class coupling of web services on web frameworks.

Web frameworks are always changing, and one day you will need to migrate your code to 
the latest web framework. If your code heavily depends on your framework,
it's pretty hard to migrate and it takes time.

by using L<Web::API::Mapper> you can simply seperate service application and framework.
you can simply mount these api service like Twitter ... etc, and dispatch paths
to these services.

L<Web::API::Mapper> is using L<Path::Dispatcher> for dispatching.

=head1 TODO

=for 4 

=item Provide service classes for mounting.

=item Provide mounter for web frameworks.

=back

=head1 ROUTE SPEC

API Provider can provide a route hash reference for dispatching rules.

=for 4

=item post => [ '/path/to/(\d+)' => sub {  } , ... ]

=item get => [  '/path/to/(\d+)' => sub {  } , ... ]

=item fallback => sub {    }

=back

=head1 ACCESSORS

=head2 route

=head2 post

is a L<Web::API::Mapper::RuleSet> object.

=head2 get

is a L<Web::API::Mapper::RuleSet> object.

=head2 fallback

is a CodeRef, fallback handler.

=head1 FUNCTIONS

=head2 mount

=head2 dispatch

=head2 auto_route( Class|Object $api , HashRef $options  )

Auto generate API routing table for object|class.

You can use C<prefix> or C<regexp> to filter methods.

underscores will be translated to slash F</>. for example, foo_get_id will be /get/id.

=head3 Options

=for 4

=item prefix => qq|prefix_|

Get methods by prefix, and strip the prefix.

=item regexp => qr/.../

Filter methods by a regular expression pattern.

=item type => post|get|any

Handler type, can be C<post>, C<get> and C<any>.

=back

=head1 EXAMPLE

    package Twitter::API;

    sub route { {
        post => [
            '/timeline/add/' => sub { my $args = shift;  .... },
            '/timeline/remove/' => sub { ... },
        ],
        get => [
            '/timeline/get/(\w+)' => sub {  my $args = shift;  .... return $1 },
        ],
    } }

    package main;

    # This will add rule path to /twitter/timeline/add/  ... etc
    my $m = Web::API::Mapper->new( '/twitter' => Twitter::API->route );
    $m->mount(  '/basepath' , {  post => [  ... ] } );
    $m->post->mount( '/basepath' , [  ...  ]  );
    $m->dispatch( '/path/to' , { args ... } );

    1;

For example, if you are in Dancer:

    #!/usr/bin/perl
    use Dancer;
    use JSON;

    our $m = Web::API::Mapper->new
        ->mount( '/twitter' => Twitter::API->route )
        ->mount( '/basepath' , { post => [  ... ] } );

    any '/api/*' => sub {
        return encode_json( $m->dispatch( $1 , params ) );
    };

    # request for '/api/twitter/timeline/add' to run!

    dance;

And one day you want another applciation in Mojo:

    use Mojolicious::Lite;
    get '/api/*' => sub {
        my $self = shift;
        return $self->render(  $m->dispatch( $1 , $self->params ) );
    };
    app->start;

=head1 AUTHOR

Cornelius E< cornelius.howl at gmail.com >

=head1 LICENSE

Perl

=cut
