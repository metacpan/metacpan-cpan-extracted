package WebService::GetSongBPM;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Access to the getsongbpm.com API

our $VERSION = '0.0300';

use Moo;
use strictures 2;
use namespace::clean;

use Carp;
use Mojo::UserAgent;
use Mojo::JSON::MaybeXS;
use Mojo::JSON qw( decode_json );
use Mojo::URL;


has api_key => (
    is       => 'ro',
    required => 1,
);


has base => (
    is      => 'rw',
    default => sub { Mojo::URL->new('https://api.getsongbpm.com') },
);


has artist => (
    is => 'ro',
);


has artist_id => (
    is => 'ro',
);


has song => (
    is => 'ro',
);


has song_id => (
    is => 'ro',
);


has ua => (
    is      => 'rw',
    default => sub { Mojo::UserAgent->new() },
);


sub fetch {
    my ($self) = @_;

    my $type;
    my $lookup;
    my $id;

    if ( $self->artist && $self->song ) {
        $type   = 'both';
        $lookup = 'song:' . $self->song . '+artist:' . $self->artist;
    }
    elsif ( $self->artist or $self->artist_id ) {
        $type   = 'artist';
        $lookup = $self->artist;
        $id     = $self->artist_id;
    }
    elsif ( $self->song or $self->song_id ) {
        $type   = 'song';
        $lookup = $self->song;
        $id     = $self->song_id;
    }
    croak "Can't fetch: No type set"
        unless $type;

    my $path = '';
    my $query = '';

    if ( $self->artist_id or $self->song_id ) {
        $path .= "/$type/";
        $query .= 'api_key=' . $self->api_key . "&id=$id";
    }
    else {
        $path .= '/search/';
        $query .= 'api_key=' . $self->api_key
            . "&type=$type"
            . "&lookup=$lookup";
    }

    my $url = Mojo::URL->new($self->base)->path($path)->query($query);

    my $tx = $self->ua->get($url);

    my $data = _handle_response($tx);

    return $data;
}

sub _handle_response {
    my ($tx) = @_;

    my $data;

    my $res = $tx->result;

    if ( $res->is_success ) {
        $data = decode_json( $res->body );
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

WebService::GetSongBPM - Access to the getsongbpm.com API

=head1 VERSION

version 0.0300

=head1 SYNOPSIS

  use WebService::GetSongBPM;
  my $ws = WebService::GetSongBPM->new(
    api_key => '1234567890abcdefghij',
    artist  => 'van halen',
    song    => 'jump',
  );
  # OR
  $ws = WebService::GetSongBPM->new(
    api_key   => '1234567890abcdefghij',
    artist_id => 'abc123',
  );
  # OR
  $ws = WebService::GetSongBPM->new(
    api_key => '1234567890abcdefghij',
    song_id => 'xyz123',
  );
  my $res = $ws->fetch();
  my $bpm = $res->{song}{tempo};

=head1 DESCRIPTION

C<WebService::GetSongBPM> provides access to L<https://getsongbpm.com/api>.

=head1 ATTRIBUTES

=head2 api_key

Your authorized access key.

=head2 base

The base URL.  Default: https://api.getsongbpm.com

=head2 artist

The artist for which to search.

=head2 artist_id

The artist id for which to search.

=head2 song

The song for which to search.

=head2 song_id

The song id for which to search.

=head2 ua

The user agent.

=head1 METHODS

=head2 new()

  $ws = WebService::GetSongBPM->new(%arguments);

Create a new C<WebService::GetSongBPM> object.

=head2 fetch()

  $r = $w->fetch();

Fetch the results and return them as a HashRef.

=head1 SEE ALSO

L<Moo>

L<Mojo::UserAgent>

L<Mojo::JSON::MaybeXS>

L<Mojo::JSON>

L<https://getsongbpm.com/api>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
