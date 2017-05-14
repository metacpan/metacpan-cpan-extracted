package WWW::Google::Translate;

our $VERSION = '0.10';

use strict;
use warnings;
{
    use URI;
    use Carp;
    use Readonly;
    use LWP::UserAgent;
    use JSON qw( from_json );
    use Storable qw( store retrieve );
    use HTTP::Status qw( HTTP_BAD_REQUEST );
    use English qw( -no_match_vars $EVAL_ERROR );
}

my ( $REST_HOST, $REST_URL, $CONSOLE_URL, %SIZE_LIMIT_FOR );
{
    Readonly $REST_HOST      => 'translation.googleapis.com';
    Readonly $REST_URL       => "https://$REST_HOST/language/translate/v2";
    Readonly $CONSOLE_URL    => "https://console.developers.google.com/cloud-resource-manager";
    Readonly %SIZE_LIMIT_FOR => (
        translate => 2000,    # google states 2K but observed results vary
        detect    => 2000,
        languages => 9999,    # N/A
    );
}

sub new {
    my ( $class, $param_hr ) = @_;

    my %self = (
        key            => 0,
        format         => 0,
        model          => 0,
        prettyprint    => 0,
        default_source => 0,
        default_target => 0,
        data_format    => 'perl',
        timeout        => 60,
        force_post     => 0,
        rest_url       => $REST_URL,
        agent          => ( sprintf '%s/%s', __PACKAGE__, $VERSION ),
        cache_file     => 0,
        headers        => {},
    );

    for my $property ( keys %self )
    {
        if ( exists $param_hr->{$property} )
        {
            my $type          = ref $param_hr->{$property} || 'String';
            my $expected_type = ref $self{$property}       || 'String';

            croak "$property should be a $expected_type"
                if $expected_type ne $type;

            $self{$property} = delete $param_hr->{$property};
        }
    }

    for my $property ( keys %{$param_hr} )
    {
        carp "$property is not a supported parameter";
    }

    for my $default (qw( cache_file default_source default_target ))
    {
        if ( !$self{$default} )
        {
            delete $self{$default};
        }
    }

    if ( exists $self{cache_file} )
    {
        $self{cache_hr} = {};

        if ( stat $self{cache_file} )
        {
            $self{cache_hr} = retrieve( $self{cache_file} );

            if ( ref $self{cache_hr} ne 'HASH' )
            {
                unlink $self{cache_file};

                $self{cache_hr} = {};
            }
        }
    }

    croak "key is a required parameter"
        if !$self{key};

    croak "data_format must either be Perl or JSON"
        if $self{data_format} !~ m{\A (?: perl|json ) \z}xmsi;

    $self{ua} = LWP::UserAgent->new();
    $self{ua}->agent( delete $self{agent} );

    if ( keys %{ $self{headers} } )
    {
        $self{ua}->default_header( %{ $self{headers} } );
    }

    return bless \%self, $class;
}

sub translate {
    my ( $self, $arg_hr ) = @_;

    croak 'q is a required parameter'
        if !exists $arg_hr->{q};

    return
        if not $arg_hr->{q};

    $arg_hr->{source} ||= $self->{default_source};
    $arg_hr->{target} ||= $self->{default_target};

    $self->{default_source} = $arg_hr->{source};
    $self->{default_target} = $arg_hr->{target};

    my %is_supported = (
        format      => 1,
        model       => 1,
        prettyprint => 1,
        q           => 1,
        source      => 1,
        target      => 1,
    );

    my @unsupported
        = grep { !exists $is_supported{$_} } keys %{$arg_hr};

    croak "unsupported parameters: ", ( join ',', @unsupported )
        if @unsupported;

    if ( !exists $arg_hr->{model} )
    {
        if ( $self->{model} )
        {
            $arg_hr->{model} = $self->{model};
        }
    }

    if ( !exists $arg_hr->{prettyprint} )
    {
        if ( $self->{prettyprint} )
        {
            $arg_hr->{prettyprint} = $self->{prettyprint};
        }
    }

    if ( !exists $arg_hr->{format} )
    {
        if ( $self->{format} )
        {
            $arg_hr->{format} = $self->{format};
        }
        elsif ( $arg_hr->{q} =~ m{ < [^>]+ > }xms )
        {
            $arg_hr->{format} = 'html';
        }
        else
        {
            $arg_hr->{format} = 'text';
        }
    }

    my $cache_key;

    if ( exists $self->{cache_hr} )
    {
        $cache_key
            = join '||', map { $arg_hr->{$_} }
            sort grep { exists $arg_hr->{$_} && defined $arg_hr->{$_} }
            keys %is_supported;

        return $self->{cache_hr}->{$cache_key}
            if exists $self->{cache_hr}->{$cache_key};
    }

    my $result = $self->_rest( 'translate', $arg_hr );

    if ($cache_key)
    {
        $self->{cache_hr}->{$cache_key} = $result;

        store( $self->{cache_hr}, $self->{cache_file} );
    }

    return $result;
}

sub languages {
    my ( $self, $arg_hr ) = @_;

    croak 'target is a required parameter'
        if !exists $arg_hr->{target};

    my $result;

    if ( $arg_hr->{target} )
    {
        my @unsupported = grep { $_ ne 'target' } keys %{$arg_hr};

        croak "unsupported parameters: ", ( join ',', @unsupported )
            if @unsupported;

        $result = $self->_rest( 'languages', $arg_hr );
    }

    return $result;
}

sub detect {
    my ( $self, $arg_hr ) = @_;

    croak 'q is a required parameter'
        if !exists $arg_hr->{q};

    my $result;

    if ( $arg_hr->{q} )
    {
        my @unsupported = grep { $_ ne 'q' } keys %{$arg_hr};

        croak "unsupported parameters: ", ( join ',', @unsupported )
            if @unsupported;

        $result = $self->_rest( 'detect', $arg_hr );
    }

    return $result;
}

sub _rest {
    my ( $self, $operation, $arg_hr ) = @_;

    my $url
        = $operation eq 'translate'
        ? $self->{rest_url}
        : "$self->{rest_url}/$operation";

    my $force_post = $self->{force_post};

    my %form = (
        key => $self->{key},
        %{$arg_hr},
    );

    if ( exists $arg_hr->{source} && !$arg_hr->{source} )
    {
        delete $form{source};
        delete $arg_hr->{source};
    }

    my $byte_size = exists $form{q} ? length $form{q} : 0;
    my $get_size_limit = $SIZE_LIMIT_FOR{$operation};

    my ( $method, $response );

    if ( $force_post || $byte_size > $get_size_limit )
    {
        $method = 'POST';

        $response = $self->{ua}->post(
            $url,
            'X-HTTP-Method-Override' => 'GET',
            'Content'                => \%form
        );
    }
    else
    {
        $method = 'GET';

        my $uri = URI->new($url);

        $uri->query_form( \%form );

        $response = $self->{ua}->get($uri);
    }

    my $json = $response->content() || "";

    my ($message) = $json =~ m{ "message" \s* : \s* "( [^"]+ )" }xms;

    $message ||= $response->status_line();

    if ( $response->code() == HTTP_BAD_REQUEST )
    {
        my $dump = join ",\n", map {"$_ => $arg_hr->{$_}"} keys %{$arg_hr};

        warn "request failed: $dump\n";

        require Sys::Hostname;

        my $host = Sys::Hostname::hostname() || 'this machine';
        $host = uc $host;

        die "unsuccessful $operation $method for $byte_size bytes: ",
            $message, "\n",
            "check that $host has API Access for this API key", "\n",
            "at $CONSOLE_URL\n";
    }
    elsif ( !$response->is_success() )
    {
        croak "unsuccessful $operation $method ",
            "for $byte_size bytes, message: $message\n";
    }

    return $json
        if 'json' eq lc $self->{data_format};

    $json =~ s{ NaN }{-1}xmsg;    # prevent from_json failure

    my $trans_hr;

    eval { $trans_hr = from_json( $json, { utf8 => 1 } ); };

    if ($EVAL_ERROR)
    {
        warn "$json\n$EVAL_ERROR";
        return $json;
    }

    return $trans_hr;
}

sub DESTROY {
    my ($self) = @_;
    return;
}

1;
