package WebService::Openaura;
use JSON::XS;
use Cache::LRU;
use Net::DNS::Lite;
use Furl;
use URI;
use URI::QueryParam;
use Carp;
use Moo;
use namespace::clean;
our $VERSION = "0.02";


$Net::DNS::Lite::CACHE = Cache::LRU->new( size => 512 );

has 'api_key' => (
    is => 'rw',
    isa => sub { $_[0] },
    required => 1,
    default => sub { $ENV{OPENAURA_API_KEY} },
);

has 'http' => (
    is => 'rw',
    required => 1,
    default  => sub {
        my $http = Furl::HTTP->new(
            inet_aton => \&Net::DNS::Lite::inet_aton,
            agent => 'WebService::Openaura/' . $VERSION,
            headers => [ 'Accept-Encoding' => 'gzip',],
        );
        return $http;
    },
);


sub classic_artists {
    my ($self, $id, $param) = @_;
    return $self->request("classic/artists/$id", $param);
}

sub classic_version {
    my $self = shift;
    return $self->request("classic/version");
}

sub info_artists {
    my ($self, $id, $param) = @_;
    return $self->request("info/artists/$id", $param);
}

sub info_artists_bio {
    my ($self, $id, $param) = @_;
    return $self->request("info/artists/$id/bio", $param);
}

sub info_artists_cover_photo { 
    my ($self, $id, $param) = @_;
    return $self->request("info/artists/$id/cover_photo", $param);
}

sub info_artists_fact_card { 
    my ($self, $id, $param) = @_;
    return $self->request("info/artists/$id/fact_card", $param);
}

sub info_artists_profile_photo { 
    my ($self, $id, $param) = @_;
    return $self->request("info/artists/$id/profile_photo", $param);
}

sub info_artists_release_art { 
    my ($self, $id, $param) = @_;
    return $self->request("info/artists/$id/release_art", $param);
}

sub info_artists_tags { 
    my ($self, $id, $param) = @_;
    return $self->request("info/artists/$id/tags", $param);
}

sub info_version {
    my $self = shift;
    return $self->request("info/version");
}

sub particles_artists { 
    my ($self, $id, $param) = @_;
    return $self->request("particles/artists/$id", $param);
}

sub particles_particle { 
    my ($self, $id, $param) = @_;
    return $self->request("particles/particle/$id", $param);
}

sub particles_sources { 
    my ($self, $id, $param) = @_;
    return $self->request("particles/sources/$id", $param);
}

sub particles_version {
    my $self = shift;
    return $self->request("particles/version");
}

sub search_artists { 
    my ($self, $param) = @_;
    return $self->request("search/artists", $param);
}

sub search_artists_all { 
    my ($self, $param) = @_;
    return $self->request("search/artists_all", $param);
}

sub search_version {
    my $self = shift;
    return $self->request("search/version");
}

sub source_artists { 
    my ($self, $id, $param) = @_;
    return $self->request("source/artists/$id", $param);
}

sub source_sources { 
    my ($self, $id, $param) = @_;
    return $self->request("source/sources/$id", $param);
}

sub source_version {
    my $self = shift;
    return $self->request("source/version");
}


sub request {
    my ( $self, $path, $query_param ) = @_;

    my $query = URI->new;
    $query->query_param( 'api_key', $self->api_key );
    map { $query->query_param( $_, $query_param->{$_} ) } keys %$query_param;

    my ($minor_version, $code, $message, $headers, $content) = 
        $self->http->request(
            scheme => 'http',
            host => 'api.openaura.com',
            path_query => "v1/$path$query",
            method => 'GET',
    );

    if ($path =~ m|search/artists(?:_all)*|) {
        $content =~ s/^(\[.+\])$/{ "artists": $1 }/;
    }
    my $data = decode_json( $content );
    
    if ( defined $data->{results}{error} ) {
        my $type = $data->{results}{error}{type};
        my $message = $data->{results}{error}{message};
        confess "$type: $message";
    } else {
        return $data;
    }
}


1;
__END__

=encoding utf-8

=head1 NAME

WebService::Openaura - A simple and fast interface to the Openaura API

=head1 SYNOPSIS

    use WebService::Openaura;

    my $openaura = new WebService::Openaura(api_key => 'YOUR_API_KEY');
    my $data = $openaura->info_artists_bio(
        '65f4f0c5-ef9e-490c-aee3-909e7ae6b2ab',
        { id_type => 'musicbrainz:gid', }
    );
    $data = $openaura->search_artists({
        q => 'Metallica'
    });


=head1 DESCRIPTION

The module provides a simple interface to the Openaura API. To use this module, you must first sign up at L<http://developer.openaura.com/docs/> to receive an API key.

=head1 METHODS

These methods usage: L<http://developer.openaura.com/docs/>

=head3 classic_artists

=head3 classic_version

=head3 info_artists

=head3 info_artists_bio

=head3 info_artists_cover_photo

=head3 info_artists_fact_card

=head3 info_artists_profile_photo

=head3 info_artists_release_art

=head3 info_artists_tags

=head3 info_version

=head3 particles_artists

=head3 particles_particle

=head3 particles_sources

=head3 particles_version

=head3 search_artists

=head3 search_artists_all

=head3 search_version

=head3 source_artists

=head3 source_sources

=head3 source_version

=head1 SEE ALSO

L<http://developer.openaura.com/docs/>

=head1 LICENSE

Copyright (C) Hondallica.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Hondallica E<lt>hondallica@gmail.comE<gt>

=cut

