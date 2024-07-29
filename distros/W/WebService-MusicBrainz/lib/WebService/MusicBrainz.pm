package WebService::MusicBrainz;

use strict;
use Mojo::Base -base;
use WebService::MusicBrainz::Request;

our $VERSION = '1.0.7';

has 'request';
has valid_resources =>
    sub { [ 'area', 'artist', 'discid', 'label', 'recording', 'release', 'release-group' ] };
has relationships => sub {
    my $rels = [
        'area-rels',          'artist-rels', 'event-rels',     'instrument-rels',
        'label-rels',         'place-rels',  'recording-rels', 'release-rels',
        'release-group-rels', 'series-rels', 'url-rels',       'work-rels'
    ];
    return $rels;
};

# inc subqueries
our %subquery_map = (
    _modifiers    => [qw(discids media isrcs artist-credits various-artists)],
    _misc         => [qw(aliases annotation tags ratings user-tags user-ratings)],
    artist        => [qw(recordings releases release-groups works)],
    discid        => [qw(artists artist-credits collections labels recordings release-groups)],
    label         => [qw(releases)],
    recording     => [qw(artists releases)],
    release       => [qw(artists collections labels recordings release-groups)],
    'release-group' => [qw(artists releases)],
);

has search_fields_by_resource => sub {
    my %search_fields;

    $search_fields{area} = [
        'aid', 'alias', 'area', 'begin', 'comment', 'end', 'ended', 'sortname',
        'iso', 'iso1',  'iso2', 'iso3',  'type'
    ];
    $search_fields{artist} = [
        'area',   'beginarea', 'endarea',  'arid',    'artist', 'artistaccent',
        'alias',  'begin',     'comment',  'country', 'end',    'ended',
        'gender', 'ipi',       'sortname', 'tag',     'type'
    ];
    $search_fields{discid} = ['discid'];
    $search_fields{label}  = [
        'alias',    'area',  'begin', 'code',  'comment',     'country',
        'end',      'ended', 'ipi',   'label', 'labelaccent', 'laid',
        'sortname', 'type',  'tag'
    ];
    $search_fields{recording} = [
        'arid',            'artist',        'artistname',    'creditname',
        'comment',         'country',       'date',          'dur',
        'format',          'isrc',          'number',        'position',
        'primarytype',     'puid',          'qdur',          'recording',
        'recordingaccent', 'reid',          'release',       'rgid',
        'rid',             'secondarytype', 'status',        'tid',
        'trnum',           'tracks',        'tracksrelease', 'tag',
        'type',            'video'
    ];
    $search_fields{'release-group'} = [
        'arid',        'artist',  'comment',      'creditname',
        'primarytype', 'rgid',    'releasegroup', 'releasegroupaccent',
        'releases',    'release', 'reid',         'secondarytype',
        'status',      'tag',     'type'
    ];
    $search_fields{release} = [
        'arid',       'artist',        'artistname',    'asin',
        'barcode',    'catno',         'comment',       'country',
        'creditname', 'date',          'discids',       'discidsmedium',
        'format',     'laid',          'label',         'lang',
        'mediums',    'primarytype',   'puid',          'quality',
        'reid',       'release',       'releaseaccent', 'rgid',
        'script',     'secondarytype', 'status',        'tag',
        'tracks',     'tracksmedium',  'type'
    ];
    $search_fields{work}
        = [ 'alias', 'arid', 'artist', 'comment', 'iswc', 'lang', 'tag', 'type', 'wid', 'work',
        'workaccent' ];

    return \%search_fields;
};

sub is_valid_subquery {
    my $self       = shift;
    my $resource   = shift;
    my $subqueries = shift;

    return unless ($resource);

    my $resource_map = $subquery_map{$resource};
    return if ( !$resource_map );

    my %valid_fields = map { $_ => 1 } (
        @$resource_map,
        @{ $subquery_map{_modifiers} },
        @{ $subquery_map{_misc} },
        @{ $self->relationships }
    );

    foreach my $subquery (@$subqueries) {
        return if ( !$valid_fields{$subquery} );
    }

    return 1;
}

sub search {
    my $self            = shift;
    my $search_resource = shift;
    my $search_query    = shift;

    $self->request( WebService::MusicBrainz::Request->new() );

    if ( !grep /^$search_resource$/, @{ $self->valid_resources() } ) {
        die "Not a valid resource for search ($search_resource)";
    }

    $self->request()->search_resource($search_resource);

    if ( exists $search_query->{mbid} ) {
        $self->request()->mbid( $search_query->{mbid} );
        delete $search_query->{mbid};
    }

    if ( exists $search_query->{discid} ) {
        $self->request()->discid( $search_query->{discid} );
        delete $search_query->{discid};
    }

    my $inc_subqueries = delete $search_query->{inc};
    # only use "inc" parameters when a specific MBID or DISCID is given
    if ( ( $self->request()->mbid() or $self->request()->discid() ) and $inc_subqueries ) {
        $inc_subqueries = [$inc_subqueries] if ( !ref $inc_subqueries );

        if ( $self->is_valid_subquery( $search_resource, $inc_subqueries ) ) {
            $self->request()->inc($inc_subqueries);
        } else {
            my $subquery_str = join ", ", @$inc_subqueries;
            die "Not a valid \"inc\" subquery ($subquery_str) for resource: $search_resource";
        }
    }

    if ( exists $search_query->{fmt} ) {
        $self->request()->format( $search_query->{fmt} );
        delete $search_query->{fmt};
    }

    if ( exists $search_query->{offset} ) {
        $self->request()->offset( $search_query->{offset} );
        delete $search_query->{offset};
    }

    foreach my $search_field ( keys %{$search_query} ) {
        if ( !grep /^$search_field$/, @{ $self->search_fields_by_resource->{$search_resource} } ) {
            die "Not a valid search field ($search_field) for resource \"$search_resource\"";
        }
    }

    $self->request->query_params($search_query);

    my $request_result = $self->request()->result();

    return $request_result;
}

=head1 NAME

WebService::MusicBrainz

=head1 SYNOPSIS

    use WebService::MusicBrainz;

    my $mb = WebService::MusicBrainz->new();

    my $result = $mb->search($resource => { $search_key => 'search value' });
    my $result = $mb->search($resource => { $search_key => 'search value', fmt => 'json' });  # fmt => 'json' is default

    my $result_dom = $mb->search($resource => { $search_key => 'search value', fmt => 'xml' });

=head1 DESCRIPTION

API to search the musicbrainz.org database

=head1 VERSION

Version 1.0 and future releases are not backward compatible with pre-1.0 releases.  This is a complete re-write using version 2.0 of the MusicBrainz API and Mojolicious.

=head1 METHODS

=head2 new

 my $mb = WebService::MusicBrainz->new();

=head2 search

 my $result_list = $mb->search($resource => { param1 => 'value1' });

 my $result = $mb->search($resource => { mbid => 'mbid' });

 my $result_more = $mb->search($resource => { mbid => 'mbid', inc => 'extra stuff' });

 Valid values for $resource are:  area, artist, event, instrument, label, recording, release, release-group, series, work, url
The default is to return decoded JSON as a perl data structure.  Specify format => 'xml' to return the results as an instance of Mojo::DOM.

=head3 Search by MBID

  my $result = $mb->search($resource => { mbid => 'xxxxxx' });

The "inc" search parameter is only allowed when searching for any particular "mbid".

=head3 Search area

  my $area_list_results = $mb_ws->search(area => { iso => 'US-OH' });
  my $area_list_results = $mb_ws->search(area => { area => 'cincinnati' });
  my $area_list_results = $mb_ws->search(area => { alias => 'new york' });
  my $area_list_results = $mb_ws->search(area => { sortname => 'new york' });
  my $area_list_results = $mb_ws->search(area => { area => 'new york', type => 'city' });

  my $area_result = $mb_ws->search(area => { mbid => '0573177b-9ff9-4643-80bc-ed2513419267' });
  my $area_result = $mb_ws->search(area => { mbid => '0573177b-9ff9-4643-80bc-ed2513419267', inc => 'area-rels' });

=head3 Search artist

 # JSON example
 my $artists = $mb->search(artist => { artist => 'Ryan Adams' });
 my $artists = $mb->search(artist => { artist => 'Ryan Adams', type => 'person' });

 my $artist_country = $artists->{artists}->[0]->{country};

 # XML example
 my $artists = $mb->search(artist => { artist => 'Ryan Adams', type => 'person', fmt => 'xml' });

 my $artist_country = $artists->at('country')->text;

 # find this particular artist
 my $artist = $mb->search(artist => { mbid => '5c2d2520-950b-4c78-84fc-78a9328172a3' });

 # find this particular artist and include release and artist relations (members of the band)
 my $artist = $mb->search(artist => { mbid => '5c2d2520-950b-4c78-84fc-78a9328172a3', inc => ['releases','artist-rels'] });

 # artists that started in Cincinnati
 my $artists = $mb->search(artist => { beginarea => 'Cincinnati' });

=head3 Search label

 my $labels = $mb->search(label => { label => 'Death' });

=head3 Search recording

 my $recordings = $mb->search(recording => { artist => 'Taylor Swift' });

=head3 Search release

 my $releases = $mb->search(release => { release => 'Love Is Hell', status => 'official' });
 print "RELEASE COUNT: ", $releases->{count}, "\n";

=head1 DEBUG

Set environment variable MUSICBRAINZ_DEBUG=1

=over 1

=item

The URL that is generated for the search will output to STDOUT.

=item

The formatted output (JSON or XML) will be output to STDOUT

=back

=head1 AUTHOR

=over 4

=item Bob Faist <bob.faist@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2017 by Bob Faist

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

https://musicbrainz.org/doc/MusicBrainz_API

=cut

1;
