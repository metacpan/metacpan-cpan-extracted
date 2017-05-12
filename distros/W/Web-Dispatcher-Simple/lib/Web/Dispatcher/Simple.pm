package Web::Dispatcher::Simple;
use strict;
use warnings;
our $VERSION = '0.11';

use Carp ();
use Router::Simple;
use Try::Tiny;
use Web::Dispatcher::Simple::Request;
use Web::Dispatcher::Simple::Response;
use Scalar::Util qw(blessed);

my $_ROUTER = Router::Simple->new;

sub import {
    my $caller = caller;

    no strict 'refs';
    no warnings 'redefine';

    *{"${caller}::router"} = \&router;

    my @http_methods = qw/get post put del any/;
    for my $http_method (@http_methods) {
        *{"${caller}\::$http_method"} = sub { goto \&$http_method };
    }

    strict->import;
    warnings->import;
}

sub _stub {
    my $name = shift;
    return sub { Carp::croak("Can't call $name() outside router block") };
}

{
    my @declarations = qw(get post put del any);
    for my $keyword (@declarations) {
        no strict 'refs';
        *$keyword = _stub $keyword;
    }
}

sub router (&) { ## no critic 
    my $block = shift;

    if ($block) {
        no warnings 'redefine';
        local *get  = sub { do_get(@_) };
        local *post = sub { do_post(@_) };
        local *put  = sub { do_put(@_) };
        local *del  = sub { do_del(@_) };
        local *any  = sub { do_any(@_) };
        $block->();

        return sub { dispatch(shift) }
    }
}

# HTTP Methods
sub route {
    my ( $pattern, $code, $methods ) = @_;
    unless ( ref $code eq 'CODE' ) {
        Carp::croak("The logic for $pattern must be CodeRef");
    }

    $_ROUTER->connect(
        $pattern,
        { action => $code },
        { method => [ map { uc $_ } @$methods ] }
    );
}

sub do_any {
    if ( scalar @_ == 4 ) {
        my ( $methods, $pattern, $code ) = @_;
        route( $pattern, $code, $methods );
    }
    else {
        my ( $pattern, $code ) = @_;
        route( $pattern, $code, [ 'GET', 'POST', 'DELETE', 'PUT', 'HEAD' ] );
    }
}

sub do_get {
    my ( $pattern, $code ) = @_;
    route( $pattern, $code, [ 'GET', 'HEAD' ] );
}

sub do_post {
    my ( $pattern, $code ) = @_;
    route( $pattern, $code, ['POST'] );
}

sub do_put {
    my ( $pattern, $code ) = @_;
    route( $pattern, $code, ['PUT'] );
}

sub do_del {
    my ( $pattern, $code ) = @_;
    route( $pattern, $code, ['DELETE'] );
}

# dispatch
sub dispatch {
    my $env = shift;
    if ( my $match = $_ROUTER->match($env) ) {
        my $req = Web::Dispatcher::Simple::Request->new($env);

        # enable configuring
        $req->decode_params();
        return handle_request( $req, $match );
    }
    else {
        return handle_not_found();
    }
}

sub handle_request {
    my ( $req, $match ) = @_;
    my $code = delete $match->{action};
    my $res  = try {
        $code->( $req, $match );
    }
    catch {
        handle_exception($_);
    };
    return psgify_response($res);
}

sub psgify_response {
    my $res = shift;
    my $psgi_res;
    my $res_type = ref($res) || '';
    if ( blessed $res && $res->isa('Plack::Response') ) {
        $res->encode_body;
        $psgi_res = $res->finalize;
    }
    elsif ( $res_type eq 'ARRAY' ) {
        my $response = Web::Dispatcher::Simple::Response->new(@$res);
        $response->encode_body;
        $psgi_res = $response->finalize;
    }
    else {
        Carp::croak("unknown response type: $res_type. The response is $res");
    }
    $psgi_res;
}

sub handle_exception {
    my $e = shift;
    warn "An internal error occured during processing request: $e";
    return internal_server_error($e);
}

sub handle_not_found {
    return not_found();
}

sub not_found {
    [ 404, [], [ 'Not Found' ] ];
}

sub internal_server_error {
    my $e = shift;
    [ 500, [], [ 'Internal Server Error'] ];
}

1;

__END__

=encoding utf-8

=head1 NAME

Web::Dispatcher::Simple - Minimalistic routing sugar for your Plack

=head1 SYNOPSIS

In Web::Dispatcher::Simple, a route is an HTTP method paired with 
an URL matching pattern.  Each route is associated with a code ref: 

  # app.psgi
  use Web::Dispatcher::Simple;
  my $app = router {
    get '/api' => sub {
      my $req = shift;
      my $res = $req->new_response(200);
      $res->body('Hello world');
      $res;
    },
    post '/comment/{id}' => sub {
      my ($req, $args)  = @_;
      my $id = $args->{id};
      my $res = $req->new_response(200);
      $res;
    },
    any [ 'GET', 'POST' ] => '/any' => sub {
        my ( $req, $args ) = @_;
        my $res = $req->new_response(200);
        $res->body('any');
        $res;
    }, 
  };

Route patterns may include named parameters, accessible via the args hash:

  use Web::Dispatcher::Simple;
  my $app = router {
    post '/comment/{id}' => sub {
      my ($req, $args)  = @_;
      my $id = $args->{id};
      my $res = $req->new_response(200);
      $res;
    },
  };


=head1 DESCRIPTION

Web::Dispatcher::Simple is Minimalistic routing sugar for your Plack

=head1 SOURCE AVAILABILITY

This source is in Github:

  http://github.com/dann/p5-web-dispatcher-simple

=head1 CONTRIBUTORS

Many thanks to: woremacx

=head1 AUTHOR

dann E<lt>techmemo@gmail.comE<gt>

=head1 SEE ALSO
L<Router::Simple>, L<Plack>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut1;

