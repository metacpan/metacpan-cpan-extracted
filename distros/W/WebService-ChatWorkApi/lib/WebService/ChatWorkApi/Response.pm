use strict;
use warnings;
package WebService::ChatWorkApi::Response;
use parent "HTTP::Response";
use Carp ( );
use JSON;
use HTTP::Status qw( HTTP_NO_CONTENT );

sub _gen_accessor {
    my $class = shift;
    my $key   = shift;
    no strict "refs";
    *{ "$class\::$key" } = sub { shift->get( $key ) };
}

sub codec { JSON->new }

sub limit { shift->header( "X-RateLimit-Limit" ) }

sub remaining { shift->header( "X-RateLimit-Remaining" ) }

sub reset { shift->header( "X-RateLimit-Reset" ) }

sub _decoded_content { shift->SUPER::decoded_content( @_ ) }

sub decoded_content {
    my $self = shift;

    if ( $self->code == HTTP_NO_CONTENT ) {
        return [ ];
    }

    return $self->{_decoded_content_cache} ||= $self->codec->decode( $self->_decoded_content );
}

sub keys {
    my $self = shift;
    return keys %{ $self->decoded_content };
}

sub values {
    my $self = shift;
    return values %{ $self->decoded_content };
}

sub list {
    my $self = shift;
    return @{ $self->decoded_content };
}

sub get {
    my $self = shift;
    my $key  = shift;
    return $self->decoded_content->{ $key };
}

sub data_hash {
    my $self = shift;
    return %{ $self->decoded_content };
}

sub data { &data_hash }

1;

__END__
=encoding utf8

=head1 NAME

WebService::ChatWorkApi::Response - isa specific response class of response of ChatWork REST API

=head1 SYNOPSIS

  use Data::Dumper;
  use WebService::ChatWorkApi::Response;
  my $res = $ua->get( "/me" );
  bless $res, "WebService::ChatWorkApi::Response";
  warn Dumper $res->decoded_content;

=head1 DESCRIPTION

This module provides a few methods to represent ChatWork REST API spec.

Two most things are:

1. response is a JSON
2. 204 No Content at response list is empty (Not []).
