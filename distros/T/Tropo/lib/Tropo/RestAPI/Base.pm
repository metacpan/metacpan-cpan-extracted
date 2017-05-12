package Tropo::RestAPI::Base;

# ABSTRACT: Base class for REST-API part of Tropo

use strict;
use warnings;

use Moo;

use HTTP::Tiny;
use Types::Standard qw(Str InstanceOf Bool);
use URI::Escape qw(uri_escape_utf8);

our $VERSION = 0.03;

has url => (
    is      => 'ro',
    isa     => Str,
    default => sub { 'https://api.tropo.com/1.0/' },
);

has ua => (
    is      => 'ro',
    isa     => InstanceOf['HTTP::Tiny'],
    default => sub { HTTP::Tiny->new( agent => 'Perl Tropo API/' . $VERSION ) },
);

has err => (
    is  => 'rw',
    isa => Str,
);

has redirect => (
    is      => 'ro',
    isa     => Bool,
    default => sub { 0; },
);

sub get {
    my ($self, $url, $params) = @_;
    
    return if !$url;
    
    my $params_string = _get_params_string( $params );
    my $response      = $self->ua->get( $url . '?' . $params_string );
    
    return $response;
}

sub post {
    my ($self, $url, $params) = @_;
    
    return if !$url;
    
    my $params_string = _get_params_string( $params );
    my $response      = $self->ua->post(
        $url,
        {
            content => $params_string,
            headers => { 'content-type' => 'application/x-www-form-urlencoded' },
        },
    );
    
    return $response;
}

sub _get_params_string {
    my ($params) = @_;
    
    return '' if !$params || ref $params ne 'HASH';
    
    my @params;
    while( my @pair = each %{ $params } ) {
        push @params, join "=", map { uri_escape_utf8( $_ ) } @pair;
    }
    
    return join '&', @params;
}
    

1;

__END__

=pod

=head1 NAME

Tropo::RestAPI::Base - Base class for REST-API part of Tropo

=head1 VERSION

version 0.16

=head1 AUTHOR

Renee Baecker <module@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
