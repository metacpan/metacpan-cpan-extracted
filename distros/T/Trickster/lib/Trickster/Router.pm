package Trickster::Router;

use strict;
use warnings;
use v5.14;

sub new {
    my ($class) = @_;
    
    return bless {
        routes => {},
        named_routes => {},
    }, $class;
}

sub add_route {
    my ($self, $method, $path, $handler, %opts) = @_;
    
    die "Route handler must be a code reference" unless ref($handler) eq 'CODE';
    
    my $pattern = $self->_compile_route($path);
    
    my $route = {
        path => $path,
        pattern => $pattern,
        handler => $handler,
        params => $pattern->{params} || [],
        name => $opts{name},
        constraints => $opts{constraints} || {},
    };
    
    push @{$self->{routes}{$method}}, $route;
    
    if ($opts{name}) {
        $self->{named_routes}{$opts{name}} = $route;
    }
    
    return $route;
}

sub _compile_route {
    my ($self, $path) = @_;
    
    my @params;
    my $pattern = $path;
    
    # Escape special regex characters except : and *
    $pattern =~ s{([.+?^\${}()\[\]|\\])}{\\$1}g;
    
    # Convert :param to named captures
    $pattern =~ s{:(\w+)}{
        push @params, $1;
        "(?<$1>[^/]+)"
    }ge;
    
    # Convert * to wildcard
    $pattern =~ s{\\\*}{.*}g;
    
    return {
        regex => qr{^$pattern$},
        params => \@params,
    };
}

sub match {
    my ($self, $method, $path) = @_;
    
    my $routes = $self->{routes}{$method} || [];
    
    for my $route (@$routes) {
        if ($path =~ $route->{pattern}{regex}) {
            my %captures = %+;
            
            # Validate constraints
            if ($route->{constraints}) {
                my $valid = 1;
                for my $param (keys %{$route->{constraints}}) {
                    if (exists $captures{$param}) {
                        my $constraint = $route->{constraints}{$param};
                        if (ref($constraint) eq 'Regexp') {
                            $valid = 0 unless $captures{$param} =~ $constraint;
                        } elsif (ref($constraint) eq 'CODE') {
                            $valid = 0 unless $constraint->($captures{$param});
                        }
                    }
                }
                next unless $valid;
            }
            
            return {
                route => $route,
                params => \%captures,
            };
        }
    }
    
    return undef;
}

sub url_for {
    my ($self, $name, %params) = @_;
    
    my $route = $self->{named_routes}{$name};
    return undef unless $route;
    
    my $path = $route->{path};
    
    for my $param (keys %params) {
        $path =~ s{:$param\b}{$params{$param}};
    }
    
    return $path;
}

sub routes {
    my ($self, $method) = @_;
    
    return $method ? ($self->{routes}{$method} || []) : $self->{routes};
}

1;

__END__

=head1 NAME

Trickster::Router - Robust routing engine for Trickster

=head1 SYNOPSIS

    my $router = Trickster::Router->new;
    
    $router->add_route('GET', '/user/:id', sub { ... },
        name => 'user_show',
        constraints => { id => qr/^\d+$/ }
    );
    
    my $match = $router->match('GET', '/user/123');
    my $url = $router->url_for('user_show', id => 123);

=head1 DESCRIPTION

Trickster::Router provides a robust routing engine with parameter
constraints, named routes, and URL generation.

=cut
