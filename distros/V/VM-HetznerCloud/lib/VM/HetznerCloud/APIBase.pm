package VM::HetznerCloud::APIBase;

# ABSTRACT: Base class for all entity classes

use v5.24;

use Carp;
use Moo;
use Mojo::UserAgent;
use Mojo::Util qw(url_escape);
use Types::Mojo qw(:all);
use Types::Standard qw(Str);

use VM::HetznerCloud::Schema;

use Mojo::Base -strict, -signatures;

our $VERSION = '0.0.3'; # VERSION

has token    => ( is => 'ro', isa => Str, required => 1 );
has host     => ( is => 'ro', isa => MojoURL["https?"], default => sub { 'https://api.hetzner.cloud' }, coerce => 1 );
has base_uri => ( is => 'ro', isa => Str, default => sub { 'v1' } );

has client   => (
    is      => 'ro',
    lazy    => 1,
    isa     => MojoUserAgent,
    default => sub {
        Mojo::UserAgent->new,
    }
);

sub _request ( $self, $partial_uri, $params = {}, $param_def = {}, $opts = {} ) {

    my ($validated_params, @errors) = VM::HetznerCloud::Schema->validate(
        $opts->{oid},
        $params,
    );

    $validated_params ||= {};

    if ( @errors ) {
        croak 'Invalid parameters';
    }

    my $method = delete $opts->{type} // 'get';
    my $sub    = $self->client->can(lc $method);

    if ( !$sub ) {
        croak sprintf 'Invalid request method %s', $method;
    }

    $partial_uri ||= '';
    $partial_uri =~ s{:(?<mandatory>\w+)\b}{ ( delete $validated_params->{path}->{$+{mandatory}} ) // '' }xmsge;
    $partial_uri =~ s{\A/}{};

    my $query = join '&', map{
        $_ . '=' . url_escape(  delete $validated_params->{query}->{$_} )
    } grep {
        $param_def->{$_}->{in} eq 'query' && $validated_params->{query}->{$_}
    }sort keys $param_def->%*;

    my %request_opts;
    if ( $params->%* ) {
        %request_opts = ( json => $validated_params->{body} );
    }

    my $uri = join '/', 
        $self->host, 
        $self->base_uri,
        $self->endpoint,
        ( $partial_uri ? $partial_uri : () );

    $uri .= '?' . $query if $query;

    my $tx = $self->client->$method(
        $uri,
        {
            Authorization => 'Bearer ' . $self->token,
        },
        %request_opts,
    );

    my $response = $tx->res;

    say STDERR $tx->req->to_string if $ENV{VM_HETZNERCLOUD_DEBUG};
    say STDERR $tx->res->to_string if $ENV{VM_HETZNERCLOUD_DEBUG};

    return if $response->is_error;
    return $response->json;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

VM::HetznerCloud::APIBase - Base class for all entity classes

=head1 VERSION

version 0.0.3

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
