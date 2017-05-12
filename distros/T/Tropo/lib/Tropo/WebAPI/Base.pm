package Tropo::WebAPI::Base;

# ABSTRACT: Base class for Web-API part of Tropo API

use strict;
use warnings;

use Moo;
use Types::Standard qw(HashRef);
use Class::Method::Modifiers qw(install_modifier);

has attr => (
    is      => 'rw',
    isa     => HashRef,
    default => sub { {} },
);

sub register {
    my $class = caller;
    
    install_modifier( $class, 'around', 'has', sub {
        my $orig  = shift;
        my $name  = shift;
        my %attrs = @_;
        
        $orig->( $name, @_, trigger => sub {
            my $self = shift;
            
            $self->{attr}->{$name}  = $attrs{isa};
        } );
    });
}

sub to_hash {
    my ($self) = @_;
    
    my %hash;
    
    ATTR:
    for my $attr ( keys %{ $self->attr } ) {
        my $method = $self->can( $attr );
        
        next ATTR if !$method;
        
        my $value  = $self->$method();
        
        if (
         !defined $value
         || ( ref $value eq 'ARRAY' and !defined $value->[0] ) 
         || ( ref $value eq 'HASH' and !keys %{$value} )
        ) {
            next ATTR;
        }
        
        $hash{$attr} = $value;
    }
    
    return \%hash;
}

1;

__END__

=pod

=head1 NAME

Tropo::WebAPI::Base - Base class for Web-API part of Tropo API

=head1 VERSION

version 0.16

=head1 AUTHOR

Renee Baecker <module@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
