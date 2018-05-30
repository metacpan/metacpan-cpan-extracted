package WebService::AcousticBrainz;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Access to the AcousticBrainz API

our $VERSION = '0.0103';

use Moo;
use strictures 2;
use namespace::clean;

use Carp;
use Mojo::UserAgent;
use Mojo::JSON::MaybeXS;
use Mojo::JSON qw( decode_json );


has base => (
    is      => 'ro',
    default => sub { 'https://acousticbrainz.org/api/v1' },
);


sub fetch {
    my ( $self, %args ) = @_;

    my $query;
    if ( $args{query} ) {
        $query = join '&', map { "$_=$args{query}->{$_}" } keys %{ $args{query} };
    }

    my $ua = Mojo::UserAgent->new;

    my $url = $self->base . '/'. $args{mbid} . '/'. $args{endpoint};
    $url .= '?' . $query
        if $query;

    my $tx = $ua->get($url);

    my $data = _handle_response($tx);

    return $data;
}

sub _handle_response {
    my ($tx) = @_;

    my $data;

    if ( my $res = $tx->success ) {
        my $body = $res->body;
        if ( $body =~ /{/ ) {
            $data = decode_json( $res->body );
        }
        else {
            croak $body, "\n";
        }
    }
    else {
        my $err = $tx->error;
        croak "$err->{code} response: $err->{message}"
            if $err->{code};
        croak "Connection error: $err->{message}";
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

version 0.0103

=head1 SYNOPSIS

  use WebService::AcousticBrainz;
  my $w = WebService::AcousticBrainz->new;
  my $r = $w->fetch(
    mbid     => '96685213-a25c-4678-9a13-abd9ec81cf35',
    endpoint => 'low-level',
    query    => { n => 2 },
  );

=head1 DESCRIPTION

C<WebService::AcousticBrainz> provides access to the L<https://acousticbrainz.org/data> API.

=head1 ATTRIBUTES

=head2 base

The base URL.  Default: https://acousticbrainz.org/api/v1

=head1 METHODS

=head2 new()

  $x = WebService::AcousticBrainz->new;

Create a new C<WebService::AcousticBrainz> object.

=head2 fetch()

  $r = $w->fetch(%arguments);

Fetch the results given the B<mbid> (MusicBrainz ID), B<endpoint> and optional
B<query> arguments.

=head1 SEE ALSO

L<Moo>

L<Mojo::UserAgent>

L<Mojo::JSON>

L<Mojo::JSON::MaybeXS>

L<https://acousticbrainz.org/data>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
