package Trickster;

use strict;
use warnings;
use v5.14;

our $VERSION = '0.01';

use Plack::Request;
use Plack::Response;
use Scalar::Util qw(blessed);
use Trickster::Request;
use Trickster::Response;
use Trickster::Router;
use Trickster::Exception;
use Trickster::Logger;

sub new {
    my ($class, %opts) = @_;
    
    my $self = bless {
        router => Trickster::Router->new,
        middleware => [],
        error_handler => undef,
        logger => $opts{logger} || Trickster::Logger->new(level => 'info'),
        debug => $opts{debug} || 0,
        %opts,
    }, $class;
    
    return $self;
}

sub get    { shift->_add_route('GET', @_) }
sub post   { shift->_add_route('POST', @_) }
sub put    { shift->_add_route('PUT', @_) }
sub patch  { shift->_add_route('PATCH', @_) }
sub delete { shift->_add_route('DELETE', @_) }
sub any    { 
    my ($self, $methods, $path, $handler, %opts) = @_;
    for my $method (@$methods) {
        $self->_add_route($method, $path, $handler, %opts);
    }
    return $self;
}

sub _add_route {
    my ($self, $method, $path, $handler, %opts) = @_;
    
    $self->{router}->add_route($method, $path, $handler, %opts);
    
    return $self;
}

sub middleware {
    my ($self, $mw) = @_;
    push @{$self->{middleware}}, $mw;
    return $self;
}

sub error_handler {
    my ($self, $handler) = @_;
    $self->{error_handler} = $handler;
    return $self;
}

sub logger {
    my ($self, $logger) = @_;
    $self->{logger} = $logger if $logger;
    return $self->{logger};
}

sub url_for {
    my ($self, $name, %params) = @_;
    return $self->{router}->url_for($name, %params);
}

sub routes {
    my ($self, $method) = @_;
    return $self->{router}->routes($method);
}

sub to_app {
    my ($self) = @_;
    
    my $app = sub {
        my ($env) = @_;
        
        my $req = Trickster::Request->new($env);
        my $res = Trickster::Response->new(404);
        my $psgi_response;
        
        eval {
            my $method = $req->method;
            my $path = $req->path_info;
            
            my $match = $self->{router}->match($method, $path);
            
            if ($match) {
                $req->env->{'trickster.params'} = $match->{params};
                $req->env->{'trickster.route'} = $match->{route};
                
                my $result = $match->{route}{handler}->($req, $res);
                
                # Handle different return types
                if (blessed($result) && ($result->isa('Plack::Response') || $result->isa('Trickster::Response'))) {
                    $res = $result;
                } elsif (ref($result) eq 'ARRAY') {
                    $psgi_response = $result;
                } elsif (defined $result) {
                    require Encode;
                    $res->body(Encode::encode_utf8($result));
                    $res->status(200) if $res->status == 404;
                }
            } else {
                # No route matched
                $res->status(404);
                $res->content_type('text/plain');
                $res->body('Not Found');
            }
        };
        
        # Return early if we have a PSGI response
        return $psgi_response if $psgi_response;
        
        if ($@) {
            my $error = $@;
            
            $self->{logger}->error("Request error: $error");
            
            # Handle Trickster exceptions
            if (blessed($error) && $error->isa('Trickster::Exception')) {
                if ($self->{error_handler}) {
                    return $self->{error_handler}->($error, $req, $res);
                }
                
                $res = Trickster::Response->new;
                
                # Return JSON for API requests
                if ($req->header('Accept') && $req->header('Accept') =~ /application\/json/) {
                    return $res->json($error->as_hash, $error->status)->finalize;
                }
                
                require Encode;
                $res->status($error->status);
                $res->content_type('text/plain');
                $res->body(Encode::encode_utf8($error->message));
                
                return $res->finalize;
            }
            
            # Handle other errors
            if ($self->{error_handler}) {
                return $self->{error_handler}->($error, $req, $res);
            }
            
            require Encode;
            $res = Trickster::Response->new(500);
            $res->content_type('text/plain');
            
            if ($self->{debug}) {
                $res->body(Encode::encode_utf8("Internal Server Error: $error"));
            } else {
                $res->body("Internal Server Error");
            }
        }
        
        return $res->finalize;
    };
    
    # Apply middleware in reverse order
    for my $mw (reverse @{$self->{middleware}}) {
        $app = $mw->($app);
    }
    
    return $app;
}

1;

__END__

=head1 NAME

Trickster - A modern, battle-tested micro-framework for Perl web applications

=head1 SYNOPSIS

    use Trickster;
    
    my $app = Trickster->new;
    
    $app->get('/', sub {
        my ($req, $res) = @_;
        return "Hello, World!";
    });
    
    $app->get('/user/:id', sub {
        my ($req, $res) = @_;
        my $id = $req->env->{'trickster.params'}{id};
        return "User ID: $id";
    });
    
    $app->to_app;

=head1 DESCRIPTION

Trickster is a modern micro-framework for building web applications in Perl.
It emphasizes simplicity, PSGI compatibility, and production readiness while
respecting CPAN traditions.

=head1 METHODS

=head2 new(%options)

Creates a new Trickster application instance.

=head2 get($path, $handler)

Registers a GET route.

=head2 post($path, $handler)

Registers a POST route.

=head2 put($path, $handler)

Registers a PUT route.

=head2 patch($path, $handler)

Registers a PATCH route.

=head2 delete($path, $handler)

Registers a DELETE route.

=head2 middleware($middleware)

Adds PSGI middleware to the application.

=head2 error_handler($handler)

Sets a custom error handler.

=head2 to_app()

Returns a PSGI application code reference.

=head1 AUTHOR

Trickster Contributors

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
