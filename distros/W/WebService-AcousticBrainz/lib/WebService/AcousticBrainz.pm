package WebService::AcousticBrainz;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Access to the AcousticBrainz API

our $VERSION = '0.0401';

use Moo;
use strictures 2;
use namespace::clean;

use Carp;
use Mojo::UserAgent;
use Mojo::JSON::MaybeXS;
use Mojo::JSON qw( decode_json );
use Mojo::URL;
use Try::Tiny;


has base => (
    is      => 'rw',
    default => sub { Mojo::URL->new('https://acousticbrainz.org/api/v1') },
);


has ua => (
    is      => 'rw',
    default => sub { Mojo::UserAgent->new() },
);


sub fetch {
    my ( $self, %args ) = @_;

    my $query;
    if ( $args{query} ) {
        $query = join '&', map { "$_=$args{query}->{$_}" } keys %{ $args{query} };
    }

    croak 'No mbid provided' unless $args{mbid};
    croak 'No endpoint provided' unless $args{endpoint};

    my $url = $self->base . '/'. $args{mbid} . '/'. $args{endpoint};
    $url .= '?' . $query
        if $query;

    my $tx = $self->ua->get($url);

    my $data = _handle_response($tx);

    return $data;
}

sub _handle_response {
    my ($tx) = @_;

    my $data;

    my $res = $tx->result;

    if ( $res->is_success ) {
        my $body = $res->body;
        try {
            $data = decode_json( $res->body );
        }
        catch {
            croak $body, "\n";
        }
    }
    else {
        croak "Connection error: ", $res->message;
    }

    return $data;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::AcousticBrainz - Access to the AcousticBrainz API

=head1 VERSION

version 0.0401

=head1 SYNOPSIS

  use WebService::AcousticBrainz;

  my $w = WebService::AcousticBrainz->new;

  my $r = $w->fetch(
    mbid     => 'c51f788f-f2ac-4d4e-aa72-205f002b8752',
    endpoint => 'low-level',
    query    => { n => 2 },
  );

=head1 DESCRIPTION

C<WebService::AcousticBrainz> provides access to the L<https://acousticbrainz.org/data> API.

=head1 ATTRIBUTES

=head2 base

The base URL.  Default: https://acousticbrainz.org/api/v1

=head2 ua

The user agent.

=head1 METHODS

=head2 new()

  $w = WebService::AcousticBrainz->new;

Create a new C<WebService::AcousticBrainz> object.

=head2 fetch()

  $r = $w->fetch(%arguments);

Fetch the results given a B<mbid> (MusicBrainz recording ID), B<endpoint> and
optional B<query> arguments.

=head1 SEE ALSO

L<Moo>

L<Mojo::UserAgent>

L<Mojo::JSON>

L<Mojo::JSON::MaybeXS>

L<https://acousticbrainz.org/data>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
