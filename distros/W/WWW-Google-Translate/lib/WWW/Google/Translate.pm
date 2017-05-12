package WWW::Google::Translate;

our $VERSION = '0.09';

use strict;
use warnings;
{
    use Carp;
    use URI;
    use File::Spec;
    use JSON qw( from_json );
    use LWP::UserAgent;
    use HTTP::Status qw( HTTP_BAD_REQUEST );
    use Readonly;
    use English qw( -no_match_vars $EVAL_ERROR $OS_ERROR );
    use Data::Dumper;
}

my ( $REST_HOST, $REST_URL, $CONSOLE_URL, %SIZE_LIMIT_FOR, $TEMP_FILE );
{
    Readonly $REST_HOST      => 'www.googleapis.com';
    Readonly $REST_URL       => "https://$REST_HOST/language/translate/v2";
    Readonly $CONSOLE_URL    => "https://code.google.com/apis/console";
    Readonly %SIZE_LIMIT_FOR => (
        translate => 2000,    # google states 2K but observed results vary
        detect    => 2000,
        languages => 9999,    # N/A
    );
    Readonly $TEMP_FILE => 'www-google-translate.dat';
}

sub new {
    my ( $class, $param_rh ) = @_;

    my %self = (
        key            => 0,
        format         => 0,
        prettyprint    => 0,
        default_source => 0,
        default_target => 0,
        data_format    => 'perl',
        timeout        => 60,
        force_post     => 0,
        rest_url       => $REST_URL,
        agent          => ( sprintf '%s/%s', __PACKAGE__, $VERSION ),
        cache_results  => 0,
        headers        => {},
    );

    for my $property ( keys %self ) {

        if ( exists $param_rh->{$property} ) {

            my $type          = ref $param_rh->{$property} || 'String';
            my $expected_type = ref $self{$property}       || 'String';

            croak "$property should be a $expected_type"
                if $expected_type ne $type;

            $self{$property} = delete $param_rh->{$property};
        }
    }

    for my $property ( keys %{$param_rh} ) {

        carp "$property is not a supported parameter";
    }

    for my $default (qw( cache_results default_source default_target )) {

        if ( !$self{$default} ) {

            delete $self{$default};
        }
    }

    if ( exists $self{cache_results} ) {

        my $tmpdir = File::Spec->tmpdir();

        if ($tmpdir) {

            $self{cache_rh}   = {};
            $self{cache_file} = File::Spec->catfile( $tmpdir, $TEMP_FILE );

            if ( stat $self{cache_file} ) {

                croak $self{cache_file}, ' is not writable'
                    if !-w $self{cache_file};

                croak $self{cache_file}, ' is not readable'
                    if !-r $self{cache_file};

                $self{cache_rh} = do $self{cache_rh};
            }
        }
        else {

            carp 'unable to find a writable temp directory';
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
    my ( $self, $arg_rh ) = @_;

    croak 'q is a required parameter'
        if !exists $arg_rh->{q};

    my $result;

    if ( $arg_rh->{q} ) {

        $arg_rh->{source} ||= $self->{default_source};
        $arg_rh->{target} ||= $self->{default_target};

        $self->{default_source} = $arg_rh->{source};
        $self->{default_target} = $arg_rh->{target};

        my %is_supported = (
            format      => 1,
            prettyprint => 1,
            q           => 1,
            source      => 1,
            target      => 1,
        );

        my @unsupported = grep { !exists $is_supported{$_} }
            keys %{$arg_rh};

        croak "unsupported parameters: ", ( join ',', @unsupported )
            if @unsupported;

        if ( !exists $arg_rh->{prettyprint} ) {

            if ( $self->{prettyprint} ) {

                $arg_rh->{prettyprint} = $self->{prettyprint};
            }
        }

        if ( !exists $arg_rh->{format} ) {

            if ( $self->{format} ) {

                $arg_rh->{format} = $self->{format};
            }
            elsif ( $arg_rh->{q} =~ m{ < [^>]+ > }xms ) {

                $arg_rh->{format} = 'html';
            }
            else {

                $arg_rh->{format} = 'text';
            }
        }

        my $cache_key;

        if ( exists $self->{cache_rh} ) {

            $cache_key
                = join ',',
                map { $arg_rh->{$_} }
                sort grep { exists $arg_rh->{$_} }
                keys %is_supported;

            return $self->{cache_rh}->{$cache_key}
                if exists $self->{cache_rh}->{$cache_key};
        }

        $result = $self->_rest( 'translate', $arg_rh );

        if ($cache_key) {

            $self->{cache_rh}->{$cache_key} = $result;

            my $count = keys %{ $self->{cache_rh} };

            if ( $count % 10 == 0 ) {

                $self->_store_cache();
            }
        }
    }

    return $result;
}

sub languages {
    my ( $self, $arg_rh ) = @_;

    croak 'target is a required parameter'
        if !exists $arg_rh->{target};

    my $result;

    if ( $arg_rh->{target} ) {

        my @unsupported = grep { $_ ne 'target' } keys %{$arg_rh};

        croak "unsupported parameters: ", ( join ',', @unsupported )
            if @unsupported;

        $result = $self->_rest( 'languages', $arg_rh );
    }

    return $result;
}

sub detect {
    my ( $self, $arg_rh ) = @_;

    croak 'q is a required parameter'
        if !exists $arg_rh->{q};

    my $result;

    if ( $arg_rh->{q} ) {

        my @unsupported = grep { $_ ne 'q' } keys %{$arg_rh};

        croak "unsupported parameters: ", ( join ',', @unsupported )
            if @unsupported;

        $result = $self->_rest( 'detect', $arg_rh );
    }

    return $result;
}

sub _rest {
    my ( $self, $operation, $arg_rh ) = @_;

    my $url
        = $operation eq 'translate'
        ? $self->{rest_url}
        : $self->{rest_url} . "/$operation";

    my $force_post = $self->{force_post};

    my %form = (
        key => $self->{key},
        %{$arg_rh},
    );

    if ( exists $arg_rh->{source} && !$arg_rh->{source} ) {

        delete $form{source};
        delete $arg_rh->{source};
    }

    my $byte_size = exists $form{q} ? length $form{q} : 0;
    my $get_size_limit = $SIZE_LIMIT_FOR{$operation};

    my ( $method, $response );

    if ( $force_post || $byte_size > $get_size_limit ) {

        $method = 'POST';

        $response = $self->{ua}->post(
            $url,
            'X-HTTP-Method-Override' => 'GET',
            'Content'                => \%form
        );
    }
    else {

        $method = 'GET';

        my $uri = URI->new($url);

        $uri->query_form( \%form );

        $response = $self->{ua}->get($uri);
    }

    my $json = $response->content() || "";

    my ($message) = $json =~ m{ "message" \s* : \s* "( [^"]+ )" }xms;

    $message ||= $response->status_line();

    if ( $response->code() == HTTP_BAD_REQUEST ) {

        my $dump = join ",\n", map {"$_ => $arg_rh->{$_}"} keys %{$arg_rh};

        warn "request failed: $dump\n";

        require Sys::Hostname;

        my $host = Sys::Hostname::hostname() || 'this machine';
        $host = uc $host;

        die "unsuccessful $operation $method for $byte_size bytes: ",
            $message,
            "\n",
            "check that $host is has API Access for this API key",
            "\n",
            "at $CONSOLE_URL\n";
    }
    elsif ( !$response->is_success() ) {

        croak "unsuccessful $operation $method ",
            "for $byte_size bytes, message: $message\n";
    }

    return $json
        if 'json' eq lc $self->{data_format};

    $json =~ s{ NaN }{-1}xmsg;    # prevent from_json failure

    my $trans_rh;

    eval { $trans_rh = from_json( $json, { utf8 => 1 } ); };

    if ($EVAL_ERROR) {
        warn "$json\n$EVAL_ERROR";
        return $json;
    }

    return $trans_rh;
}

sub _store_cache {
    my ($self) = @_;

    return
        if !exists $self->{cache_rh} || !exists $self->{cache_file};

    my $fh;

    open $fh, '>', $self->{cache_file}
        or die 'open ', $self->{cache_file}, ": $OS_ERROR";

    local $Data::Dumper::Terse     = 1;
    local $Data::Dumper::Indent    = 1;
    local $Data::Dumper::Quotekeys = 0;
    local $Data::Dumper::Sortkeys  = 1;

    print {$fh} Dumper( $self->{cache_rh} )
        or die 'print ', $self->{cache_file}, ": $OS_ERROR";

    close $fh
        or die 'close ', $self->{cache_file}, ": $OS_ERROR";

    return 1;
}

sub DESTROY {
    my ($self) = @_;

    $self->_store_cache();

    return;
}

1;
