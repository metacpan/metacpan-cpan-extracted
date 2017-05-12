
package WebService::Pinterest::Spec;
$WebService::Pinterest::Spec::VERSION = '0.1';
use strict;
use warnings;

use Moose::Role;

use Carp qw(carp croak);
use Params::Validate qw(:all);
use Data::Validate::URI qw(is_web_uri is_https_uri);
use Regexp::Common qw(list balanced);
use List::MoreUtils qw(all none);

use WebService::Pinterest::X;

use namespace::autoclean;

our @ENDPOINT_SPECS = (
    {
        type       => 'plain',
        endpoint   => [ GET => '/oauth' ],
        parameters => {
            response_type => { spec => 'response-code' },
            client_id     => { spec => 'client-id' },
            state         => { spec => 'any', optional => 1 },
            scope         => { spec => 'permission-list' },
            redirect_uri  => { spec => 'https-uri' },

        },
    },
    {
        type       => 'plain',
        endpoint   => [ POST => '/v1/oauth/token' ],
        parameters => {
            grant_type    => { spec => 'grant-type' },
            client_id     => { spec => 'client-id' },
            client_secret => { spec => 'any' },
            code          => { spec => 'any' },
        },
    },
    {
        type       => 'plain',
        endpoint   => [ GET => '/v1/oauth/inspect' ],
        parameters => {
            client_id    => { spec => 'client-id' },
            access_token => { spec => 'access-token' },

        },
    },

    # Users
    # https://developers.pinterest.com/docs/api/users/#fetch-user-data
    {
        endpoint => [ GET => '/v1/me/' ],
        object   => 'user',
        resource => 'me',
    },
    {
        endpoint => [ GET => '/v1/me/boards/' ],
        object   => 'board',
        resource => [ 'my/boards', 'me/boards' ],
    },
    {
        endpoint => [ GET => '/v1/me/boards/suggested/' ],
        object   => 'board',
        resource => [ 'my/suggested/boards', 'me/boards/suggested' ],
    },
    {
        endpoint => [ GET => '/v1/me/likes/' ],
        object   => 'pin',
        type     => '+cursor',
        resource => [ 'my/likes', 'me/likes' ],
    },
    {
        endpoint => [ GET => '/v1/me/pins/' ],
        object   => 'pin',
        type     => '+cursor',
        resource => [ 'my/pins', 'me/pins' ],
    },

    # hinted at https://developers.pinterest.com/docs/api/overview/#user-errors
    {
        endpoint   => [ GET => '/v1/users/:user' ],
        object     => 'user',
        parameters => {
            user => { spec => 'user-uid' },
        },
        resource => 'user',
    },

    # https://developers.pinterest.com/docs/api/users/#search-user-data
    {
        endpoint   => [ GET => '/v1/me/search/boards/' ],
        object     => 'board',
        parameters => {
            query => { spec => 'any' },
        },
        type     => '+cursor',
        resource => [ 'search/my/boards', 'me/search/boards' ],
    },
    {
        endpoint   => [ GET => '/v1/me/search/pins/' ],
        object     => 'board',
        parameters => {
            query => { spec => 'any' },
        },
        type     => '+cursor',
        resource => [ 'search/my/pins', 'me/search/pins' ],
    },

    # https://developers.pinterest.com/docs/api/users/#create-follow-data
    {
        endpoint   => [ POST => '/v1/me/following/boards/' ],
        object     => 'board',
        parameters => {
            board => { spec => 'board-uid' },
        },
        resource => [ 'my/following/board', 'me/following/board' ],
    },
    {
        endpoint   => [ POST => '/v1/me/following/users/' ],
        object     => 'user',
        parameters => {
            user => { spec => 'user-uid' },
        },
        resource => [ 'my/following/user', 'me/following/user' ],
    },

    # https://developers.pinterest.com/docs/api/users/#fetch-follow-data
    {
        endpoint => [ GET => '/v1/me/followers/' ],
        object   => 'user',
        type     => '+cursor',
        resource => [ 'my/followers', 'me/followers' ],
    },
    {
        endpoint => [ GET => '/v1/me/following/boards/' ],
        object   => 'board',
        type     => '+cursor',
        resource => [ 'my/following/boards', 'me/following/boards' ],
    },
    {
        endpoint => [ GET => '/v1/me/following/interests/' ],
        object   => 'interest',
        type     => '+cursor',
        resource => [
            'my/following/interests', 'me/following/interests', 'my/interests'
        ],
    },
    {
        endpoint => [ GET => '/v1/me/following/users/' ],
        object   => 'user',
        type     => '+cursor',
        resource => [ 'my/following/users', 'me/following/users' ],
    },

    # https://developers.pinterest.com/docs/api/users/#remove-follow-data
    {
        endpoint   => [ DELETE => '/v1/me/following/boards/:board/' ],
        object     => 'board',
        parameters => {
            board => { spec => 'board-uid' },
        },
        resource => [ 'my/following/board', 'me/following/board' ],
    },
    {
        endpoint   => [ DELETE => '/v1/me/following/users/:user/' ],
        object     => 'user',
        parameters => {
            user => { spec => 'user-uid' },
        },
        resource => [ 'my/following/user', 'me/following/user' ],
    },

    # https://developers.pinterest.com/docs/api/boards/#create-boards
    {
        endpoint   => [ POST => '/v1/boards/' ],
        object     => 'board',
        parameters => {
            name        => { spec => 'any' },
            description => { spec => 'any', optional => 1 },
        },
        resource => 'board',
    },

    # https://developers.pinterest.com/docs/api/boards/#fetch-board-data
    {
        endpoint   => [ GET => '/v1/boards/:board/' ],
        object     => 'board',
        parameters => {
            board => { spec => 'board-uid' },
        },
        resource => 'board',
    },
    {
        endpoint   => [ GET => '/v1/boards/:board/pins/' ],
        object     => 'pin',
        parameters => {
            board => { spec => 'board-uid' },
        },
        resource => 'board/pins',
    },

    # https://developers.pinterest.com/docs/api/boards/#edit-boards
    {
        endpoint   => [ PATCH => '/v1/boards/:board/' ],
        object     => 'board',
        parameters => {
            board       => { spec => 'board-uid' },
            name        => { spec => 'any', optional => 1, },
            description => { spec => 'any', optional => 1 },
        },
        resource => 'board',
    },

    # https://developers.pinterest.com/docs/api/boards/#delete-boards
    {
        endpoint   => [ DELETE => '/v1/boards/:board/' ],
        object     => 'board',
        parameters => {
            board => { spec => 'board-uid' },
        },
        resource => 'board',
    },

    # https://developers.pinterest.com/docs/api/pins/#create-pins
    {
        endpoint   => [ POST => '/v1/pins/' ],
        object     => 'pin',
        parameters => {
            board        => { spec => 'board-uid' },
            note         => { spec => 'any', },
            link         => { spec => 'web-uri', optional => 1 },
            image_url    => { spec => 'web-uri', optional => 1 },
            image_base64 => { spec => 'web-uri', optional => 1 },
            image        => { spec => 'upload', optional => 1 },
            ## FIXME implement one-of-three requirement
        },
        resource => 'pin',
    },

    # https://developers.pinterest.com/docs/api/pins/#fetch-pins
    {
        endpoint   => [ GET => '/v1/pins/:pin/' ],
        object     => 'pin',
        parameters => {
            pin => { spec => 'pin-uid' },
        },
        resource => 'pin',
    },

    # https://developers.pinterest.com/docs/api/pins/#edit-pins
    {
        endpoint   => [ PATCH => '/v1/pins/:pin/' ],
        object     => 'pin',
        parameters => {
            pin   => { spec => 'pin-uid' },
            board => { spec => 'board-uid', optional => 1 },
            note  => { spec => 'any', optional => 1 },
            link  => { spec => 'web-uri', optional => 1 },
        },
        resource => 'pin',
    },

    # https://developers.pinterest.com/docs/api/pins/#delete-pins
    {
        endpoint   => [ DELETE => '/v1/pins/:pin/' ],
        object     => 'pin',
        parameters => {
            pin => { spec => 'pin-uid' },
        },
        resource => 'pin',
    },
);

my %IS_PERMISSION = map { $_ => 1 } qw(
  read_public
  write_public
  read_relationships
  write_relationships
);

sub is_pinterest_permission_list {
    my $suspect = shift;
    return 1 if defined $suspect && length($suspect) == 0;    # None
    return all { $IS_PERMISSION{$_} } split( ',', $suspect );
}

sub is_pinterest_response_code {
    my $suspect = shift;
    return 1 if defined $suspect && ( $suspect eq 'code' );
    return 0;
}

sub is_pinterest_grant_type {
    my $suspect = shift;
    return 1 if defined $suspect && ( $suspect eq 'authorization_code' );
    return 0;
}

my %FIELDS_FOR = (
    'user' => [
        'id',  'username',   'first_name', 'last_name',
        'bio', 'created_at', 'counts',     'image',
    ],
    'board' => [
        'id',      'name',       'url',    'description',
        'creator', 'created_at', 'counts', 'image',
    ],
    'pin' => [
        'id',     'link',       'url',         'creator',
        'board',  'created_at', 'note',        'color',
        'counts', 'media',      'attribution', 'image',
        'metadata',
    ],
    'interest' => [ 'id', 'name' ],
);

# $predicate_sub = make_pinterest_fields_validator($object);
sub make_pinterest_fields_validator {
    my $object = shift;
    my $fields = $FIELDS_FOR{$object}
      or croak "Can't find fields for '$object'";
    my %field_map = map { $_ => 1 } @$fields;

    my $re_oneof  = '(?:' . join( '|', map quotemeta, @$fields ) . ')';
    my $re_field  = "$re_oneof$RE{balanced}";
    my $re_fields = qr/$RE{list}{-pat => $re_field}/;

    return sub {
        shift() =~ $re_fields;
    };
}

# spec x predicate
my %PREDICATE_FOR = (

    'any'       => sub { length( shift() ) > 0 },
    'https-uri' => \&is_https_uri,
    'web-uri'   => \&is_web_uri,
    'pinterest:response-code' => \&is_pinterest_response_code,
    'pinterest:grant-type'    => \&is_pinterest_grant_type,
    'pinterest:client-id'     => sub { shift() =~ qr/^[a-zA-Z0-9]+$/ },
    'pinterest:pin-uid'       => sub { shift() =~ qr/^[a-zA-Z0-9_-]+$/ },
    'pinterest:user-uid'      => sub { shift() =~ qr/^[a-zA-Z0-9]+$/ },
    'pinterest:board-uid' =>
      sub { shift() =~ qr{^[a-z0-9]+/[a-z0-9\-]+$|^[0-9]+$} },
    'pinterest:user-fields'     => make_pinterest_fields_validator('user'),
    'pinterest:board-fields'    => make_pinterest_fields_validator('board'),
    'pinterest:pin-fields'      => make_pinterest_fields_validator('pin'),
    'pinterest:interest-fields' => make_pinterest_fields_validator('interest'),
    'pinterest:permission-list' => \&is_pinterest_permission_list,
    'pinterest:limit' =>
      sub { my $n = shift(); $n =~ qr/^[0-9]+$/ && $n <= 100 },
    'upload' => sub {
        UNIVERSAL::isa( $_[0], 'WebService::Pinterest::Upload' )
          && $_[0]->is_valid();
    },

);
$PREDICATE_FOR{'pinterest:access-token'} = $PREDICATE_FOR{'any'};
$PREDICATE_FOR{'pinterest:cursor'}       = $PREDICATE_FOR{'any'};    # FIXME

my %ALLOWED_METHODS_FOR = ( 'upload' => ['POST'], );

my %PARAM_VALIDATE_TYPE_FOR = ( 'upload' => OBJECT, );

sub _compile_spec {
    my ( $specs, $endpoint ) = @_;
    my %specs;
    for my $k ( keys %$specs ) {
        my $v = $specs->{$k};
        my $s = $v->{spec}
          or die "No 'spec' for parameter $k\n";
        my $p = $PREDICATE_FOR{$s} // $PREDICATE_FOR{"pinterest:$s"}
          or die "Unknown 'spec' ($s) for parameter $k\n";
        if ( my $ms = $ALLOWED_METHODS_FOR{$s} ) {
            my $m = $endpoint->[0];
            die "Can't accept 'spec' ($s) - allowed only for @$ms\n"
              if none { $_ eq $m } @$ms;
        }
        my $cb = sub {
            return 1 if $p->( $_[0] );
            WebService::Pinterest::Spec::X->throw(
                {
                    key     => $k,
                    value   => $_[0],
                    message => "Invalid parameter '%s' (%s)"
                }
            );
        };
        my $pv_type = $PARAM_VALIDATE_TYPE_FOR{$s} // SCALAR;
        $specs{$k} = { %$v, type => $pv_type, callbacks => { check => $cb } };
    }
    return \%specs;
}

# ($tpl, $places, $argns) = _compile_path($enpoint_path);
#
#   $places (the mapping between sprintf parameters and named placeholders)
#   $argns  (the current argument names)
#
#  TODO escape special chars for sprintf
sub _compile_path {
    my $path   = shift;
    my $tpl    = '';
    my @places = ();
    my %args   = ();

    for ( $_ = $path ; ; ) {
        $tpl .= ':', next
          if /\G\\:/gc;
        $tpl .= '%s', push( @places, $1 ), $args{$1} = 1, next
          if /\G:([a-z0-9_]+)/gc;
        $tpl .= $1, next
          if /\G([^:]*)/gc;
        last;
    }

    # if not at the end of string, invalid use of :[^\w:] -> not yet implemented

    my @argns = keys %args;
    return ( $tpl, \@places, \@argns );
}

my %IS_SINGULAR = (
    'me'        => 1,
    'my'        => 1,
    'suggested' => 1,
    'search'    => 1,
    'following' => 1,
);

my %VARIANTS_OF;

# TODO change to return a list
sub _compute_variants {
    my $resource = shift;
    if ( ref $resource eq 'ARRAY' ) {
        return [ map { @{ _compute_variants($_) } } @$resource ];
    }

    my @parts = split( '/', $resource );
    my @variants = ( [] );
    for my $part (@parts) {
        my $vs = $VARIANTS_OF{$part} //=
          $IS_SINGULAR{$part}
          ? [$part]
          : do {
            ( my $p = $part ) =~ s/s$//;
            [ $p, "${p}s" ]    # w & w/o trailing "s"
          };
        @variants = map {
            my $v = $_;
            map { [ @$v, $_ ] } @$vs
        } @variants;
    }
    @variants = map {
        my $v = join( '/', @$_ );
        ( $v, "$v/" )          # w & w/o trailing "/"
    } @variants;
    return \@variants;
}

sub _compile_endpoints {

    my $endpoint_map;
    my $resource_map;
    for my $ep (@ENDPOINT_SPECS) {
        my $endpoint = $ep->{endpoint};
        my $params = $ep->{parameters} // {};

        my $k = join( ' ', @$endpoint );    # eg. 'POST /v1/pins'
        my $v;

        die "Error: endpoint '$k' redefined\n" if exists $endpoint_map->{$k};

        $ep->{type} //= 'std';              # default endpoint type
        $ep->{type} = 'std' . $ep->{type} if $ep->{type} =~ /^\+/;
        my $t = { map { $_ => 1 } split( '\+', $ep->{type} ) };
        if ( $t->{std} ) {

            # add access_token & fields
            my $object = $ep->{object};
            $params->{access_token} //= { spec => 'access-token' };
            $params->{fields} //= { spec => "$object-fields", optional => 1 }
              if $object;
        }
        if ( $t->{cursor} ) {
            my $m = $ep->{endpoint}[0];
            die "Error: endpoint '$k' can't have 'cursor' type (not GET)\n"
              unless $m eq 'GET';

            # add limit & cursor
            $params->{limit}  //= { spec => 'limit',  optional => 1, };
            $params->{cursor} //= { spec => 'cursor', optional => 1 };
        }

        my $path = $endpoint->[1];
        my ( $tpl, $places, $argns ) = _compile_path($path);
        if (@$argns) {
            $v->{path_tpl} =
              { tpl => $tpl, places => $places, argns => $argns };
            $params->{$_}{optional} = 0 for @$argns;
        }
        else {
            $v->{path} = $tpl;
        }

        my $spec = $params;
        my $pv_spec = eval { _compile_spec( $spec, $endpoint ) };
        die "Failed to compile '$k' endpoint specs: $@" if $@;
        $v->{spec} = $pv_spec;

        $endpoint_map->{$k} = $v;

        if ( my $r = $ep->{resource} ) {
            my $m   = $endpoint->[0];          # method
            my $rvs = _compute_variants($r);
            for my $rv (@$rvs) {
                my $rk = join( ' ', $m, $rv );
                die "Error: conflict on resource variant '$rv'\n"
                  if exists $resource_map->{$rk};    # FIXME EXPLAIN better
                $resource_map->{$rk} = $endpoint;
            }
            $resource_map->{$k} = $endpoint;
        }
    }
    return ( $endpoint_map, $resource_map );
}

our ( $COMPILED_ENDPOINTS, $RESOURCE_MAP ) = _compile_endpoints();

my $RE_METHOD = qr/^(GET|POST|PATCH|DELETE)$/; # one of GET, POST, PATCH, DELETE
my $RE_ENDPOINT = qr{^ /? (?: :? [a-zA-Z0-9]+ / )* :? [a-zA-Z0-9]+ /? $}x;

# ($method, $endpoint, $query, $form_data) = $self->_validate_call($method, $endpoint, %params);
# ($method, $endpoint, $query, $form_data) = $self->_validate_call($method, $endpoint, \%params);
# ($method, $endpoint, $query, $form_data) = $self->_validate_call($method, $endpoint, \%params, \%opts);
#
# $method is one of GET, POST, PATCH, DELETE
# $endpoint looks like a relative or absolute Unix file path
#
sub validate_call {
    my $self = shift;

    if ( @_ > 2 && !ref $_[2] && defined $_[2] ) {    # %params
        croak "Invalid usage 1"
          unless @_ % 2 == 0;    # FIXME throw, explain better
        my @params = splice( @_, 2 );
        push @_, {@params};
    }

    my ( $method, $endpoint, $params, $opts ) = validate_with(
        params => [@_],
        spec   => [
            { type => SCALAR,  regex   => $RE_METHOD },
            { type => SCALAR,  regex   => $RE_ENDPOINT },
            { type => HASHREF, default => {} },
            { type => HASHREF, default => {} },
        ],
        on_fail => sub { croak "Invalid usage" },  # FIXME throw, explain better
    );

    # From relative to absolute
    unless ( $endpoint =~ m{^/} ) {
        $endpoint = '/v1/' . $endpoint;
    }

    if ( $self->has_access_token ) {
        $params = { access_token => $self->access_token, %$params };
    }

    # Validate params
    my ( $path, $query, @more ) =
      $self->validate_endpoint_params( $method, $endpoint, $params, $opts );

    return ( $method, $path, $query, @more );
}

# $compiled = $api->find_endpoint($method, $endpoint);
sub find_endpoint {
    my ( $self, $method, $endpoint ) = @_;
    my $k = join( ' ', $method, $endpoint );
    return $COMPILED_ENDPOINTS->{$k};
}

# $endpoint = $api->resolve_resource($method, $resource);
sub resolve_resource {
    my ( $self, $method, $resource ) = @_;
    my $k = join( ' ', $method, $resource );
    return $RESOURCE_MAP->{$k};
}

# ($path, $query) = $api->validate_endpoint_params($method, $endpoint, $params, $opts);
sub validate_endpoint_params {
    my ( $self, $method, $endpoint, $params, $opts ) = @_;
    $opts //= {};

    my $compiled = $self->find_endpoint( $method, $endpoint );
    unless ($compiled) {
        carp "Could not find spec for '$method $endpoint'";
        return $endpoint, $params;
    }

    my @pv_more;
    push @pv_more, ( on_fail => sub { } ) if $opts->{skip_validate};
    push @pv_more, ( allow_extra => 1 ) if $opts->{allow_extra};

    my $checked = validate_with(
        params => $params,
        spec   => $compiled->{spec},

        #normalize
        #called
        @pv_more,
    );

    my $path;
    if ( $compiled->{path} ) {
        $path = $compiled->{path};
    }
    else {
        my ( $tpl, $places, $argns ) =
          @{ $compiled->{path_tpl} }{qw(tpl places argns)};
        $path = sprintf( $tpl, @{$checked}{@$places} );
        delete @{$checked}{@$argns};
    }

    my @more;
    if (
        my @uploads =
        map { $_ => ( delete $checked->{$_} )->lwp_file_spec } grep {
            UNIVERSAL::isa( $checked->{$_}, 'WebService::Pinterest::Upload' )
        } keys %$checked
      )
    {
        @more = \@uploads;
    }

    return ( $path, $checked, @more );
}

1;

