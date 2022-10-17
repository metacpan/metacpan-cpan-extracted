package WWW::Spotify;

use Moo 2.002004;

our $VERSION = '0.011';

use Data::Dumper      qw( Dumper );
use IO::CaptureOutput qw( capture );
use JSON::Path        ();
use JSON::MaybeXS     qw( decode_json );
use MIME::Base64      qw( encode_base64 );
use Types::Standard   qw( Bool InstanceOf Int Str );

has 'oauth_authorize_url' => (
    is      => 'rw',
    isa     => Str,
    default => 'https://accounts.spotify.com/authorize'
);

has 'oauth_token_url' => (
    is      => 'rw',
    isa     => Str,
    default => 'https://accounts.spotify.com/api/token'
);

has 'oauth_redirect_uri' => (
    is      => 'rw',
    isa     => Str,
    default => 'http://www.spotify.com'
);

has 'oauth_client_id' => (
    is      => 'rw',
    isa     => Str,
    default => $ENV{SPOTIFY_CLIENT_ID} || q{}
);

has 'oauth_client_secret' => (
    is      => 'rw',
    isa     => Str,
    default => $ENV{SPOTIFY_CLIENT_SECRET} || q{}
);

has 'current_oath_code' => (
    is      => 'rw',
    isa     => Str,
    default => q{}
);

has 'current_access_token' => (
    is      => 'rw',
    isa     => Str,
    default => q{}
);

has 'result_format' => (
    is      => 'rw',
    isa     => Str,
    default => 'json'
);

has 'grab_response_header' => (
    is      => 'rw',
    isa     => Int,
    default => 0
);

has 'results' => (
    is      => 'rw',
    isa     => Int,
    default => '15'
);

has 'debug' => (
    is      => 'rw',
    isa     => Bool,
    default => 0
);

has 'uri_scheme' => (
    is      => 'rw',
    isa     => Str,
    default => 'https'
);

has 'current_client_credentials' => (
    is      => 'rw',
    isa     => Str,
    default => q{}
);

has 'force_client_auth' => (
    is      => 'rw',
    isa     => Bool,
    default => 0
);

has uri_hostname => (
    is      => 'rw',
    isa     => Str,
    default => 'api.spotify.com'
);

has uri_domain_path => (
    is      => 'rw',
    isa     => Str,
    default => 'api'
);

has call_type => (
    is  => 'rw',
    isa => Str
);

has auto_json_decode => (
    is      => 'rw',
    isa     => Int,
    default => 0
);

has auto_xml_decode => (
    is      => 'rw',
    isa     => Int,
    default => 0
);

has last_result => (
    is      => 'rw',
    isa     => Str,
    default => q{}
);

has last_error => (
    is      => 'rw',
    isa     => Str,
    default => q{}
);

has response_headers => (
    is      => 'rw',
    isa     => Str,
    default => q{}
);

has problem => (
    is      => 'rw',
    isa     => Str,
    default => q{}
);

has ua => (
    is      => 'ro',
    isa     => InstanceOf ['LWP::UserAgent'],
    handles => { _mech => 'clone' },
    lazy    => 1,
    default => sub {
        require WWW::Mechanize;
        WWW::Mechanize->new( autocheck => 0 );
    },
);

my %api_call_options = (
    '/v1/albums/{id}' => {
        info   => 'Get an album',
        type   => 'GET',
        method => 'album'
    },

    '/v1/albums?ids={ids}' => {
        info   => 'Get several albums',
        type   => 'GET',
        method => 'albums',
        params => [ 'limit', 'offset' ]
    },

    '/v1/albums/{id}/tracks' => {
        info   => q{Get an album's tracks},
        type   => 'GET',
        method => 'albums_tracks'
    },

    '/v1/artists/{id}' => {
        info   => 'Get an artist',
        type   => 'GET',
        method => 'artist'
    },

    '/v1/artists?ids={ids}' => {
        info   => 'Get several artists',
        type   => 'GET',
        method => 'artists'
    },

    '/v1/artists/{id}/albums' => {
        info   => q{Get an artist's albums},
        type   => 'GET',
        method => 'artist_albums',
        params => [ 'limit', 'offset', 'country', 'album_type' ]
    },

    '/v1/artists/{id}/top-tracks?country={country}' => {
        info   => q{Get an artist's top tracks},
        type   => 'GET',
        method => 'artist_top_tracks',
        params => ['country']
    },

    '/v1/artists/{id}/related-artists' => {
        info   => q{Get an artist's top tracks},
        type   => 'GET',
        method => 'artist_related_artists',

        # params => [ 'country' ]
    },

    # adding q and type to url unlike example since they are both required
    '/v1/search?q={q}&type={type}' => {
        info   => 'Search for an item',
        type   => 'GET',
        method => 'search',
        params => [ 'limit', 'offset', 'q', 'type' ]
    },

    '/v1/tracks/{id}' => {
        info   => 'Get a track',
        type   => 'GET',
        method => 'track'
    },

    '/v1/tracks?ids={ids}' => {
        info   => 'Get several tracks',
        type   => 'GET',
        method => 'tracks'
    },

    '/v1/users/{user_id}' => {
        info   => q{Get a user's profile},
        type   => 'GET',
        method => 'user'
    },

    '/v1/me' => {
        info   => q{Get current user's profile},
        type   => 'GET',
        method => 'me'
    },

    '/v1/users/{user_id}/playlists' => {
        info   => q{Get a list of a user's playlists},
        type   => 'GET',
        method => 'user_playlist'
    },

    '/v1/users/{user_id}/playlists/{playlist_id}' => {
        info   => 'Get a playlist',
        type   => 'GET',
        method => q{}
    },

    '/v1/browse/featured-playlists' => {
        info   => 'Get a list of featured playlists',
        type   => 'GET',
        method => 'browse_featured_playlists'
    },

    '/v1/browse/new-releases' => {
        info   => 'Get a list of new releases',
        type   => 'GET',
        method => 'browse_new_releases'
    },

    '/v1/users/{user_id}/playlists/{playlist_id}/tracks' => {
        info   => q{Get a playlist's tracks},
        type   => 'POST',
        method => q{}
    },

    '/v1/users/{user_id}/playlists' => {
        info   => 'Create a playlist',
        type   => 'POST',
        method => q{}
    },

    '/v1/users/{user_id}/playlists/{playlist_id}/tracks' => {
        info   => 'Add tracks to a playlist',
        type   => 'POST',
        method => q{}
    }
);

my %method_to_uri = ();

foreach my $key ( keys %api_call_options ) {
    next if $api_call_options{$key}->{method} eq q{};
    $method_to_uri{ $api_call_options{$key}->{method} } = $key;
}

sub send_post_request {
    my $self       = shift;
    my $attributes = shift;

    # we will need do some auth nere

}

sub send_get_request {

    # need to build the URL here
    my $self = shift;

    my $attributes = shift;

    my $uri_params = q{};

    if ( defined $attributes->{extras}
        and ref $attributes->{extras} eq 'HASH' ) {
        my @tmp = ();

        foreach my $key ( keys %{ $attributes->{extras} } ) {
            push @tmp, "$key=$attributes->{extras}{$key}";
        }
        $uri_params = join( '&', @tmp );
    }

    if ( exists $attributes->{format}
        && $attributes->{format} =~ /json|xml|xspf|jsonp/ ) {
        $self->result_format( $attributes->{format} );
        delete $attributes->{format};
    }

    # my $url = $self->build_url_base($call_type);
    my $url;
    if ( $attributes->{method} eq 'query_full_url' ) {
        $url = $attributes->{url};
    }
    else {

        $url = $self->uri_scheme();

        # the ://
        $url .= '://';

        # the domain
        $url .= $self->uri_hostname();

        my $path = $method_to_uri{ $attributes->{method} };
        if ($path) {

            warn "raw: $path" if $self->debug();

            if ( $path =~ /search/ && $attributes->{method} eq 'search' ) {
                $path =~ s/\{q\}/$attributes->{q}/;
                $path =~ s/\{type\}/$attributes->{type}/;
            }
            elsif ( $path =~ m/\{id\}/ && exists $attributes->{params}{id} ) {
                $path =~ s/\{id\}/$attributes->{params}{id}/;
            }
            elsif ( $path =~ m/\{ids\}/ && exists $attributes->{params}{ids} )
            {
                $path =~ s/\{ids\}/$attributes->{params}{ids}/;
            }

            if ( $path =~ m/\{country\}/ ) {
                $path =~ s/\{country\}/$attributes->{params}{country}/;
            }

            if ( $path =~ m/\{user_id\}/
                && exists $attributes->{params}{user_id} ) {
                $path =~ s/\{user_id\}/$attributes->{params}{user_id}/;
            }

            if ( $path =~ m/\{playlist_id\}/
                && exists $attributes->{params}{playlist_id} ) {
                $path
                    =~ s/\{playlist_id\}/$attributes->{params}{playlist_id}/;
            }

            warn "modified: $path\n" if $self->debug();
        }

        $url .= $path;
    }

    # now we need to address the "extra" attributes if any
    if ($uri_params) {
        my $start_with = '?';
        if ( $url =~ /\?/ ) {
            $start_with = '&';
        }
        $url .= $start_with . $uri_params;
    }

    warn "$url\n" if $self->debug;
    local $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
    my $mech = $self->_mech;

    if (   $attributes->{client_auth_required}
        || $self->force_client_auth() != 0 ) {

        if ( $self->current_access_token() eq q{} ) {
            warn "Needed to get access token\n" if $self->debug();
            $self->get_client_credentials();
        }
        $mech->add_header(
            'Authorization' => 'Bearer ' . $self->current_access_token() );
    }

    $mech->get($url);

    if ( $self->grab_response_header() == 1 ) {
        $self->_set_response_headers($mech);
    }
    return $self->format_results( $mech->content );

}

sub _set_response_headers {
    my $self = shift;
    my $mech = shift;

    my $hd;
    capture { $mech->dump_headers(); } \$hd;

    $self->response_headers($hd);
    return;
}

sub format_results {
    my $self    = shift;
    my $content = shift;

    # want to store the result in case
    # we want to interact with it via a helper method
    $self->last_result($content);

    # FIX ME / TEST ME
    # vefify both of these work and return the *same* perl hash

    # when / how should we check the status? Do we need to?
    # if so then we need to create another method that will
    # manage a Sucess vs. Fail request

    if ( $self->auto_json_decode && $self->result_format eq 'json' ) {
        return decode_json $content;
    }

    if ( $self->auto_xml_decode && $self->result_format eq 'xml' ) {

        # FIX ME
        require XML::Simple;
        my $xs = XML::Simple->new();
        return $xs->XMLin($content);
    }

    # results are not altered in this cass and would be either
    # json or xml instead of a perl data structure

    return $content;
}

sub get_oauth_authorize {
    my $self = shift;

    if ( $self->current_oath_code() ) {
        return $self->current_oauth_code();
    }

    my $grant_type = 'authorization_code';
    local $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
    my $client_and_secret
        = $self->oauth_client_id() . ':' . $self->oauth_client_secret();
    my $encoded = encode_base64($client_and_secret);
    chomp($encoded);
    $encoded =~ s/\n//g;
    my $url = $self->oauth_authorize_url();

    my @parts;

    $parts[0] = 'response_type=code';
    $parts[1] = 'redirect_uri=' . $self->oauth_redirect_uri;

    my $params = join( '&', @parts );
    $url = $url . '?client_id=' . $self->oauth_client_id() . "&$params";

    $self->ua->get($url);

    return $self->ua->content;
}

sub get_client_credentials {
    my $self  = shift;
    my $scope = shift;

    if ( $self->current_access_token() ne q{} ) {
        return $self->current_access_token();
    }
    if ( $self->oauth_client_id() eq q{} ) {
        die "need to set the client oauth parameters\n";
    }

    my $grant_type = 'client_credentials';
    local $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
    my $mech = $self->_mech;
    my $client_and_secret
        = $self->oauth_client_id() . ':' . $self->oauth_client_secret();
    my $encoded = encode_base64($client_and_secret);
    my $url     = $self->oauth_token_url();

    # $url .= "?grant_type=client_credentials";
    # my $url = $self->oauth_authorize_url();
    # grant_type=client_credentials
    my $extra = {
        grant_type => $grant_type

            #code => 'code',
            #redirect_uri => $self->oauth_redirect_uri
    };
    if ($scope) {
        $extra->{scope} = $scope;
    }

    chomp($encoded);
    $encoded =~ s/\n//g;
    $mech->add_header( 'Authorization' => 'Basic ' . $encoded );

    $mech->post( $url, [$extra] );
    my $content = $mech->content();

    if ( $content =~ /access_token/ ) {
        warn "setting access token\n" if $self->debug();

        my $result = decode_json $content;

        if ( $result->{'access_token'} ) {
            $self->current_access_token( $result->{'access_token'} );
        }
    }
}

sub get_access_token {

    # cheap oauth code for now

    my $self       = shift;
    my $grant_type = 'authorization_code';
    my $scope      = shift;

    my @scopes = (
        'playlist-modify',       'playlist-modify-private',
        'playlist-read-private', 'streaming',
        'user-read-private',     'user-read-email'
    );

    if ($scope) {

        # make sure it is valid
        my $good_scope = 0;
        foreach my $s (@scopes) {
            if ( $scope eq $s ) {
                $good_scope = 1;
                last;
            }
        }
        if ( $good_scope == 0 ) {

            # clear the scope, it doesn't
            # look valid
            $scope = q{};
        }

    }

    $grant_type ||= 'authorization_code';

    # need to authorize first??

    local $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
    my $client_and_secret
        = $self->oauth_client_id() . ':' . $self->oauth_client_secret();

    print $client_and_secret , "\n";
    print $grant_type ,        "\n";
    my $encoded = encode_base64($client_and_secret);
    print $encoded , "\n";

    my $url = $self->oauth_token_url;
    print $url , "\n";
    my $extra = {
        grant_type   => $grant_type,
        code         => 'code',
        redirect_uri => $self->oauth_redirect_uri
    };
    if ($scope) {
        $extra->{scope} = $scope;
    }

    my $mech = $self->_mech;
    $mech->add_header( 'Authorization' => 'Basic ' . $encoded );

    $mech->post( $url, [$extra] );

    print $mech->content(), "\n";
}

sub get {

    # This seemed like a simple enough method
    # but everything I tried resulted in unacceptable
    # trade offs and explict defining of the structures
    # The new method, which I hope I remember when I
    # revisit it, was to use JSON::Path
    # It is an awesome module, but a little heavy
    # on dependencies.  However I would not have been
    # able to do this in so few lines without it

    # Making a generalization here
    # if you use a * you are looking for an array
    # if you don't have an * you want the first 1 (or should I say you get the first 1)

    my ( $self, @return ) = @_;

    # my @return = @_;

    my @out;

    my $result = decode_json $self->last_result();

    my $search_ref = $result;

    warn Dumper($result) if $self->debug();

    foreach my $key (@return) {
        my $type = 'value';
        if ( $key =~ /\*\]/ ) {
            $type = 'values';
        }

        my $jpath = JSON::Path->new("\$.$key");

        my @t_arr = $jpath->$type($result);

        if ( $type eq 'value' ) {
            push @out, $t_arr[0];
        }
        else {
            push @out, \@t_arr;
        }
    }
    if (wantarray) {
        return @out;
    }
    else {
        return $out[0];
    }

}

sub build_url_base {

    # first the uri type
    my $self      = shift;
    my $call_type = shift || $self->call_type();

    my $url = $self->uri_scheme();

    # the ://
    $url .= '://';

    # the domain
    $url .= $self->uri_hostname();

    # the path
    if ( $self->uri_domain_path() ) {
        $url .= '/' . $self->uri_domain_path();
    }

    return $url;
}

#- may want to move this at some point

sub query_full_url {
    my $self                 = shift;
    my $url                  = shift;
    my $client_auth_required = shift || 0;
    return $self->send_get_request(
        {
            method               => 'query_full_url',
            url                  => $url,
            client_auth_required => $client_auth_required
        }
    );
}

#-- spotify specific methods

sub album {
    my $self = shift;
    my $id   = shift;

    return $self->send_get_request(
        {
            method => 'album',
            params => { 'id' => $id }
        }
    );
}

sub albums {
    my $self = shift;
    my $ids  = shift;

    if ( ref($ids) eq 'ARRAY' ) {
        $ids = join_ids($ids);
    }

    return $self->send_get_request(
        {
            method => 'albums',
            params => { 'ids' => $ids }
        }
    );

}

sub join_ids {
    my $array = shift;
    return join( ',', @$array );
}

sub albums_tracks {
    my $self     = shift;
    my $album_id = shift;
    my $extras   = shift;

    return $self->send_get_request(
        {
            method => 'albums_tracks',
            params => { 'id' => $album_id },
            extras => $extras
        }
    );

}

sub artist {
    my $self = shift;
    my $id   = shift;

    return $self->send_get_request(
        {
            method => 'artist',
            params => { 'id' => $id }
        }
    );

}

sub artists {
    my $self    = shift;
    my $artists = shift;

    if ( ref($artists) eq 'ARRAY' ) {
        $artists = join_ids($artists);
    }

    return $self->send_get_request(
        {
            method => 'artists',
            params => { 'ids' => $artists }
        }
    );

}

sub artist_albums {
    my $self      = shift;
    my $artist_id = shift;
    my $extras    = shift;

    return $self->send_get_request(
        {
            method => 'artist_albums',
            params => { 'id' => $artist_id },
            extras => $extras
        }
    );

}

sub artist_top_tracks {
    my $self      = shift;
    my $artist_id = shift;
    my $country   = shift;

    return $self->send_get_request(
        {
            method => 'artist_top_tracks',
            params => {
                'id'      => $artist_id,
                'country' => $country
            }
        }
    );

}

sub artist_related_artists {
    my $self      = shift;
    my $artist_id = shift;
    my $country   = shift;

    return $self->send_get_request(
        {
            method => 'artist_related_artists',
            params => { 'id' => $artist_id }

                #            'country' => $country
                #          }
        }
    );

}

sub me {
    my $self = shift;
    return;
}

sub next_result_set {
    my $self   = shift;
    my $result = shift;
    return;
}

sub previous_result_set {
    my $self   = shift;
    my $result = shift;
    return;
}

sub search {
    my $self   = shift;
    my $q      = shift;
    my $type   = shift;
    my $extras = shift;

    # looks like search now requires auth
    # we will force authentication but need to
    # reset this to the previous value since not
    # all requests require auth
    my $old_force_client_auth = $self->force_client_auth();
    $self->force_client_auth(1);

    my $params = {
        method => 'search',
        q      => $q,
        type   => $type,
        extras => $extras

    };

    my $response = $self->send_get_request($params);

    # reset auth to what it was before to avoid overly chatty
    # requests
    $self->force_client_auth($old_force_client_auth);
    return $response;
}

sub track {
    my $self = shift;
    my $id   = shift;
    return $self->send_get_request(
        {
            method => 'track',
            params => { 'id' => $id }
        }
    );
}

sub browse_featured_playlists {
    my $self   = shift;
    my $extras = shift;

    # locale
    # country
    # limit
    # offset

    return $self->send_get_request(
        {
            method               => 'browse_featured_playlists',
            extras               => $extras,
            client_auth_required => 1
        }
    );
}

sub browse_new_releases {
    my $self   = shift;
    my $extras = shift;

    # locale
    # country
    # limit
    # offset

    return $self->send_get_request(
        {
            method               => 'browse_new_releases',
            extras               => $extras,
            client_auth_required => 1
        }
    );
}

sub tracks {
    my $self   = shift;
    my $tracks = shift;

    if ( ref($tracks) eq 'ARRAY' ) {
        $tracks = join_ids($tracks);
    }

    return $self->send_get_request(
        {
            method => 'tracks',
            params => { 'ids' => $tracks }
        }
    );

}

sub user {
    my $self    = shift;
    my $user_id = shift;
    return $self->send_get_request(
        {
            method => 'user',
            params => { 'user_id' => $user_id }
        }
    );

}

sub user_playlist {
    my $self = shift;
    return;
}

sub user_playlist_add_tracks {
    my $self = shift;
    return;
}

sub user_playlist_create {
    my $self = shift;
    return;
}

sub user_playlists {
    my $self = shift;
    return;
}

1;

=pod

=encoding UTF-8

=head1 NAME

WWW::Spotify - Spotify Web API Wrapper

=head1 VERSION

version 0.011

=head1 SYNOPSIS

    use WWW::Spotify ();

    my $spotify = WWW::Spotify->new();

    my $result;

    $result = $spotify->album('0sNOF9WDwhWunNAHPD3Baj');

    # $result is a json structure, you can operate on it directly
    # or you can use the "get" method see below

    $result = $spotify->albums( '41MnTivkwTO3UUJ8DrqEJJ,6JWc4iAiJ9FjyK0B59ABb4,6UXCm6bOO4gFlDQZV5yL37' );

    $result = $spotify->albums_tracks( '6akEvsycLGftJxYudPjmqK',
    {
        limit => 1,
        offset => 1

    }
    );

    $result = $spotify->artist( '0LcJLqbBmaGUft1e9Mm8HV' );

    my $artists_multiple = '0oSGxfWSnnOXhD2fKuz2Gy,3dBVyJ7JuOMt4GE9607Qin';

    $result = $spotify->artists( $artists_multiple );

    $result = $spotify->artist_albums( '1vCWHaC5f2uS3yhpwWbIA6' ,
                        { album_type => 'single',
                          # country => 'US',
                          limit   => 2,
                          offset  => 0
                        }  );

    $result = $spotify->track( '0eGsygTp906u18L0Oimnem' );

    $result = $spotify->tracks( '0eGsygTp906u18L0Oimnem,1lDWb6b6ieDQ2xT7ewTC3G' );

    $result = $spotify->artist_top_tracks( '43ZHCT0cAZBISjO8DG9PnE', # artist id
                                            'SE' # country
                                            );

    $result = $spotify->search(
                        'tania bowra' ,
                        'artist' ,
                        { limit => 15 , offset => 0 }
    );

    $result = $spotify->user( 'glennpmcdonald' );

    # public play interaction example
    # NEED TO SET YOUR o_auth client_id and secret for these to work

    $spotify->browse_featured_playlists( country => 'US' );

    my $link = $spotify->get('playlists.items[*].href');

    # $link is an arrayfef of the all the playlist urls

    foreach my $for_tracks (@{$link}) {
        # make sure the links look valid
        next if $for_tracks !~ /spotify\/play/;
        $spotify->query_full_url($for_tracks,1);
        my $pl_name = $spotify->get('name');
        my $tracks  = $spotify->get('tracks.items[*].track.id');
        foreach my $track (@{$tracks}) {
                print "$track\n";
            }
        }

=head1 DESCRIPTION

Wrapper for the Spotify Web API.

https://developer.spotify.com/web-api/

Have access to a JSON viewer to help develop and debug. The Chrome JSON viewer is
very good and provides the exact path of the item within the JSON in the lower left
of the screen as you mouse over an element.

=head1 CONSTRUCTOR ARGS

=head2 ua

You may provide your own user agent object to the constructor.  This should be
a L<LWP:UserAgent> or a subclass of it, like L<WWW::Mechanize>. If you are
using L<WWW::Mechanize>, you may want to set autocheck off.  To get extra
debugging information, you can do something like this:

    use LWP::ConsoleLogger::Easy qw( debug_ua );
    use WWW::Mechanize ();
    use WWW::Spotify ();

    my $mech = WWW::Mechanize->new( autocheck => 0 );
    debug_ua( $mech );
    my $spotify = WWW::Spotify->new( ua => $mech )

=head1 METHODS

=head2 auto_json_decode

When true results will be returned as JSON instead of a perl data structure

    $spotify->auto_json_decode(1);

=head2 auto_xml_decode

When true results will be returned as JSON instead of a perl data structure

    $spotify->auto_xml_decode(1);

=head2 get

Returns a specific item or array of items from the JSON result of the
last action.

    $result = $spotify->search(
                        'tania bowra' ,
                        'artist' ,
                        { limit => 15 , offset => 0 }
    );

 my $image_url = $spotify->get( 'artists.items[0].images[0].url' );

JSON::Path is the underlying library that actually parses the JSON.

=head2 query_full_url( $url , [needs o_auth] )

Results from some calls (playlist for example) return full urls that can be in their entirety. This method allows you
make a call to that url and use all of the o_auth and other features provided.

    $spotify->query_full_url( "https://api.spotify.com/v1/users/spotify/playlists/06U6mm6KPtPIg9D4YGNEnu" , 1 );

=head2 album

equivalent to /v1/albums/{id}

    $spotify->album('0sNOF9WDwhWunNAHPD3Baj');

used album vs albums since it is a singular request

=head2 albums

equivalent to /v1/albums?ids={ids}

    $spotify->albums( '41MnTivkwTO3UUJ8DrqEJJ,6JWc4iAiJ9FjyK0B59ABb4,6UXCm6bOO4gFlDQZV5yL37' );

or

    $spotify->albums( [ '41MnTivkwTO3UUJ8DrqEJJ',
                        '6JWc4iAiJ9FjyK0B59ABb4',
                        '6UXCm6bOO4gFlDQZV5yL37' ] );

=head2 albums_tracks

equivalent to /v1/albums/{id}/tracks

    $spotify->albums_tracks('6akEvsycLGftJxYudPjmqK',
    {
        limit => 1,
        offset => 1

    }
    );

=head2 artist

equivalent to /v1/artists/{id}

    $spotify->artist( '0LcJLqbBmaGUft1e9Mm8HV' );

used artist vs artists since it is a singular request and avoids collision with "artists" method

=head2 artists

equivalent to /v1/artists?ids={ids}

    my $artists_multiple = '0oSGxfWSnnOXhD2fKuz2Gy,3dBVyJ7JuOMt4GE9607Qin';

    $spotify->artists( $artists_multiple );

=head2 artist_albums

equivalent to /v1/artists/{id}/albums

    $spotify->artist_albums( '1vCWHaC5f2uS3yhpwWbIA6' ,
                        { album_type => 'single',
                          # country => 'US',
                          limit   => 2,
                          offset  => 0
                        }  );

=head2 artist_top_tracks

equivalent to /v1/artists/{id}/top-tracks

    $spotify->artist_top_tracks( '43ZHCT0cAZBISjO8DG9PnE', # artist id
                                 'SE' # country
                                            );

=head2 artist_related_artists

equivalent to /v1/artists/{id}/related-artists

    $spotify->artist_related_artists( '43ZHCT0cAZBISjO8DG9PnE' );

=head2 search

equivalent to /v1/search?type=album (etc)

    $spotify->search(
                        'tania bowra' ,
                        'artist' ,
                        { limit => 15 , offset => 0 }
    );

=head2 track

equivalent to /v1/tracks/{id}

    $spotify->track( '0eGsygTp906u18L0Oimnem' );

=head2 tracks

equivalent to /v1/tracks?ids={ids}

    $spotify->tracks( '0eGsygTp906u18L0Oimnem,1lDWb6b6ieDQ2xT7ewTC3G' );

=head2 browse_featured_playlists

equivalent to /v1/browse/featured-playlists

    $spotify->browse_featured_playlists();

requires OAuth

=head2 browse_new_releases

equivalent to /v1/browse/new-releases

requires OAuth

    $spotify->browse_new_releases

=head2 force_client_auth

Boolean

will pass authentication (OAuth) on all requests when set

    $spotify->force_client_auth(1);

=head2 user

equivalent to /user

=head2 oauth_client_id

needed for requests that require OAuth, see Spotify API documentation for more information

    $spotify->oauth_client_id('2xfjijkcjidjkfdi');

Can also be set via environment variable, SPOTIFY_CLIENT_ID

=head2 oauth_client_secret

needed for requests that require OAuth, see Spotify API documentation for more information

    $spotify->oauth_client_secret('2xfjijkcjidjkfdi');

Can also be set via environment variable, SPOTIFY_CLIENT_SECRET

=head1 THANKS

Paul Lamere at The Echo Nest / Spotify

All the great Perl community members that keep Perl fun

=head1 AUTHOR

Aaron Johnson <aaronjjohnson@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Aaron Johnson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Spotify Web API Wrapper

