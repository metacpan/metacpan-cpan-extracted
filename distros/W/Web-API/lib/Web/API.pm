package Web::API;

use 5.010001;
use Mouse::Role;
use experimental 'smartmatch';

# ABSTRACT: A Simple base module to implement almost every RESTful API with just a few lines of configuration

our $VERSION = '2.7'; # VERSION

use LWP::UserAgent;
use HTTP::Cookies 6.04;
use Data::Printer colored => 1;
use XML::Simple;
use URI::Escape::XS qw/uri_escape uri_unescape/;
use JSON;
use URI;
use URI::QueryParam;
use Carp;
use Net::OAuth;
use Data::Random qw(rand_chars);
use Time::HiRes 'sleep';

$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;

our $AUTOLOAD;

our %CONTENT_TYPE = (
    json => 'application/json',
    js   => 'application/json',
    xml  => 'text/xml',
);


requires 'commands';


has 'live_url' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_live_test_url',
);


has 'test_url' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_live_test_url',
);


has 'test' => (
    is      => 'rw',
    isa     => 'Bool',
    default => sub { 0 },
);


has 'api_key' => (
    is  => 'rw',
    isa => 'Str',
);


has 'user' => (
    is  => 'rw',
    isa => 'Str',
);


has 'api_key_field' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { 'key' },
);


has 'api_version' => (
    is      => 'rw',
    isa     => 'Int',
    default => sub { 1 },
);


has 'mapping' => (is => 'rw');


has 'wrapper' => (
    is      => 'rw',
    clearer => 'clear_wrapper',
);


has 'header' => (
    is      => 'rw',
    lazy    => 1,
    default => sub { {} },
);


has 'auth_type' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { 'none' },
);


has 'auth_header' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { 'Authorization' },
);


has 'auth_header_token_format' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { 'Token token=%s' },
);


has 'default_method' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { 'GET' },
);


has 'extension' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { '' },
);


has 'user_agent' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { __PACKAGE__ . ' ' . $Web::API::VERSION },
);


has 'timeout' => (
    is      => 'rw',
    isa     => 'Int',
    default => sub { 30 },
    lazy    => 1,
);


has 'strict_ssl' => (
    is      => 'rw',
    isa     => 'Bool',
    default => sub { 1 },
    lazy    => 1,
);


has 'agent' => (
    is       => 'rw',
    isa      => 'LWP::UserAgent',
    lazy     => 1,
    required => 1,
    builder  => '_build_agent',
);


has 'retry_http_codes' => (
    is  => 'rw',
    isa => 'ArrayRef[Int]',
);


has 'retry_errors' => (
    is  => 'rw',
    isa => 'ArrayRef[RegexpRef]',
);


has 'retry_times' => (
    is      => 'rw',
    isa     => 'Int',
    lazy    => 1,
    default => sub { 3 },
);


has 'retry_delay' => (
    is      => 'rw',
    isa     => 'Num',
    lazy    => 1,
    default => sub { 1.0 },
);


has 'content_type' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { 'text/plain' },
);


has 'incoming_content_type' => (
    is  => 'rw',
    isa => 'Str',
);


has 'outgoing_content_type' => (
    is  => 'rw',
    isa => 'Str',
);


has 'debug' => (
    is      => 'rw',
    isa     => 'Bool',
    default => sub { 0 },
    lazy    => 1,
);


has 'cookies' => (
    is      => 'rw',
    isa     => 'HTTP::Cookies',
    default => sub { HTTP::Cookies->new },
);


has 'consumer_secret' => (
    is  => 'rw',
    isa => 'Str',
);


has 'access_token' => (
    is  => 'rw',
    isa => 'Str',
);


has 'access_secret' => (
    is  => 'rw',
    isa => 'Str',
);


has 'signature_method' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { 'HMAC-SHA1' },
    lazy    => 1,
);


has 'encoder' => (
    is        => 'rw',
    isa       => 'CodeRef',
    predicate => 'has_encoder',
);


has 'decoder' => (
    is        => 'rw',
    isa       => 'CodeRef',
    predicate => 'has_decoder',
);


has 'oauth_post_body' => (
    is      => 'rw',
    isa     => 'Bool',
    default => sub { 1 },
    lazy    => 1,
);


has 'error_keys' => (
    is  => 'rw',
    isa => 'ArrayRef[Str]',
);

has 'base_url' => (
    is  => 'rw',
    isa => 'Str',
);

has 'json' => (
    is      => 'rw',
    isa     => 'JSON',
    default => sub {
        my $js = JSON->new;
        $js->utf8;
        $js->allow_blessed;
        $js->convert_blessed;
        $js->allow_nonref;
        $js;
    },
);

has 'xml' => (
    is      => 'rw',
    isa     => 'XML::Simple',
    lazy    => 1,
    default => sub {
        XML::Simple->new(
            ContentKey => '-content',
            NoAttr     => 1,
            KeepRoot   => 1,
            KeyAttr    => {},
        );
    },
);

has '_decoded_response' => (
    is      => 'rw',
    isa     => 'Ref',
    clearer => 'clear_decoded_response',
);

has '_response' => (
    is      => 'rw',
    isa     => 'HTTP::Response',
    clearer => 'clear_response',
);

sub _build_agent {
    my ($self) = @_;

    return LWP::UserAgent->new(
        agent      => $self->user_agent,
        cookie_jar => $self->cookies,
        timeout    => $self->timeout,
        keep_alive => 1,
        ssl_opts   => { verify_hostname => $self->strict_ssl },
    );
}

sub _build_live_test_url {
    my ($self) = @_;

    return $self->base_url if $self->base_url;
    return;
}


sub nonce {
    return join('', rand_chars(size => 16, set => 'alphanumeric'));
}


sub log {    ## no critic (ProhibitBuiltinHomonyms)
    my ($self, $msg) = @_;
    print STDERR caller() . ': '
        . ($self->test ? '[test] ' : '[LIVE] ')
        . $msg
        . $/;
    return;
}


sub decode {
    my ($self, $content, $content_type) = @_;

    $self->log("decoding response from '$content_type'") if $self->debug;

    my $data;
    eval {
        if ($self->has_decoder) {
            $self->log('running custom decoder') if $self->debug;
            $data = $self->decoder->($content, $content_type);
        }
        else {
            given ($content_type) {
                when (/urlencoded/) {
                    foreach (split(/&/, $content)) {
                        my ($key, $value) = split(/=/, $_);
                        $data->{ uri_unescape($key) } = uri_unescape($value);
                    }
                }
                when (/json/) { $data = $self->json->decode($content); }
                when (/(xml|html)/) {
                    $data = $self->xml->XMLin($content, NoAttr => 0);
                }
                default {
                    $data = { text => $content };
                }
            }
        }
    };

    die("couldn't decode payload using $content_type: $@\n" . np($content))
        if ($@ || ref \$content ne 'SCALAR');

    $self->_decoded_response($data);

    return $data;
}


sub encode {
    my ($self, $options, $content_type) = @_;

    $self->log("encoding response to '$content_type'") if $self->debug;

    my $payload;
    eval {
        # custom encoder should only be run if called by Web::API otherwise we
        # end up calling it twice
        if ($self->has_encoder and caller(1) eq 'Web::API') {
            $self->log('running custom encoder') if $self->debug;
            $payload = $self->encoder->($options, $content_type);
        }
        else {
            given ($content_type) {
                when (/urlencoded/) {
                    $payload .=
                        uri_escape($_) . '=' . uri_escape($options->{$_}) . '&'
                        foreach (keys %$options);
                    chop($payload);
                }
                when (/json/) { $payload = $self->json->encode($options); }
                when (/xml/)  { $payload = $self->xml->XMLout($options); }
                default {
                    if (exists $options->{payload}
                        and defined $options->{payload})
                    {
                        $payload = '' . $options->{payload};
                    }
                }
            }
        }
    };
    die("couldn't encode payload using $content_type: $@\n" . np(%$options))
        if ($@ || ref \$payload ne 'SCALAR');

    return $payload;
}


sub talk {
    my ($self, $command, $uri, $options, $query_keys, $content_type) = @_;

    my $method = uc($command->{method} || $self->default_method);
    my $oauth_req;

    # handle different auth_types
    given (lc $self->auth_type) {
        when ('basic') { $uri->userinfo($self->user . ':' . $self->api_key); }
        when ('header') {
            $self->header->{ $self->auth_header } =
                sprintf($self->auth_header_token_format, $self->api_key);
        }
        when ('hash_key') {
            my $api_key_field = $self->api_key_field;
            if ($self->mapping and not $command->{no_mapping}) {
                $self->log("mapping api_key_field: " . $self->api_key_field)
                    if $self->debug;
                $api_key_field = $self->mapping->{$api_key_field}
                    if $self->mapping->{$api_key_field};
            }
            $options->{$api_key_field} = $self->api_key;
        }
        when ('get_params') {
            $uri->query_form(
                $self->mapping->{user}    || 'user'    => $self->user,
                $self->mapping->{api_key} || 'api_key' => $self->api_key,
            );
        }
        when (/^oauth/) {
            my %opts = (
                consumer_key     => $self->api_key,
                consumer_secret  => $self->consumer_secret,
                request_url      => $uri,
                request_method   => $method,
                signature_method => $self->signature_method,
                timestamp        => time,
                nonce            => $self->nonce,
                token            => $self->access_token,
                token_secret     => $self->access_secret,
            );

            if (
                $options
                and (($self->oauth_post_body and $method eq 'POST')
                    or $method ne 'POST'))
            {
                $opts{extra_params} = { %$options, %{ $query_keys || {} } };
            }

            $oauth_req = Net::OAuth->request("protected resource")->new(%opts);
            $oauth_req->sign;
        }
        default {
            $self->log(
                "WARNING: auth_type " . $self->auth_type . " not supported yet")
                unless (lc($self->auth_type) eq 'none');
        }
    }

    # encode payload
    my $payload;
    if (keys %$options) {
        if ($method =~ m/^(GET|HEAD|DELETE)$/) {

            # TODO: check whether $option is a flat hashref

            unless ($self->auth_type eq 'oauth_params') {
                $uri->query_param_append($_ => $options->{$_})
                    for (keys %$options);
            }
        }
        else {
            $payload = $self->encode($options, $content_type->{out});
            $self->log("send payload: $payload") if $self->debug;
        }
    }

    # append query keys to URI
    $uri->query_param_append($_ => $query_keys->{$_}) for keys %$query_keys;

    $uri = $oauth_req->to_url if ($self->auth_type eq 'oauth_params');

    # build headers
    my %header = %{ $self->header };
    if (exists $command->{headers} and ref $command->{headers} eq 'HASH') {
        %header = (%header, %{ $command->{headers} });
    }
    my $headers = HTTP::Headers->new("Accept" => $content_type->{in}, %header);

    if ($self->debug) {
        $self->log("uri: $method $uri");
        $self->log("extra headers: " . np(%header)) if (%header);
        $self->log("OAuth headers: " . $oauth_req->to_authorization_header)
            if ($self->auth_type eq 'oauth_header');
    }

    # build request
    my $request = HTTP::Request->new($method, $uri, $headers);
    unless ($method =~ m/^(GET|HEAD|DELETE)$/) {
        $request->header("Content-type" => $content_type->{out});
        $request->content($payload);
    }

    # oauth POST
    if (    $options
        and ($method eq 'POST')
        and ($self->auth_type =~ m/^oauth/)
        and $self->oauth_post_body)
    {
        $request->content($oauth_req->to_post_body);
    }

    # oauth_header
    $request->header(Authorization => $oauth_req->to_authorization_header)
        if ($self->auth_type eq 'oauth_header');

    # add session cookies
    $self->agent->cookie_jar($self->cookies);

    # do the actual work
    return $self->request($request);
}


sub map_options {
    my ($self, $options, $command) = @_;

    my %opts;

    # first include default attributes
    %opts = %{ $command->{default_attributes} }
        if exists $command->{default_attributes};

    # then map everything in $options, overwriting default_attributes if necessary
    if ($self->mapping and not $command->{no_mapping}) {
        $self->log("mapping hash:\n" . np(%{ $self->mapping })) if $self->debug;

        # do the key and value mapping of options hash and overwrite defaults
        foreach my $key (keys %$options) {
            my ($newkey, $newvalue);
            $newkey = $self->mapping->{$key} if ($self->mapping->{$key});
            $newvalue = $self->mapping->{ $options->{$key} }
                if ($options->{$key} and $self->mapping->{ $options->{$key} });

            $opts{ $newkey || $key } = $newvalue || $options->{$key};
        }

        # and write everything back to $options
        $options = \%opts;
    }
    else {
        $options = { %opts, %$options };
    }

    return $options;
}


sub check_mandatory {
    my ($self, $options, $mandatory) = @_;

    $self->log("mandatory keys:\n" . np(@$mandatory))
        if $self->debug;

    my @missing_attrs;
    foreach my $attr (@$mandatory) {
        push(@missing_attrs, $attr)
            unless $self->key_exists($attr, $options);
    }

    die 'mandatory attributes for this command missing: '
        . join(', ', @missing_attrs)
        . $/
        if @missing_attrs;

    return;
}


sub key_exists {
    my ($self, $path, $hash) = @_;

    my @bits = split /\./, $path;
    my $node = $hash;

    return $node
        if @bits == grep {
               ref $node eq "HASH"
            && exists $node->{$_}
            && ($node = $node->{$_} // {})
        } @bits;

    return;
}


sub wrap {
    my ($options, $wrapper, $content_type) = @_;

    if (ref $wrapper eq 'ARRAY') {

        # XML needs wrapping into extra array ref layer to make XML::Simple
        # behave correctly
        if ($content_type =~ m/xml/) {
            $options = { $_ => [$options] } for (reverse @$wrapper);
        }
        else {
            $options = { $_ => $options } for (reverse @$wrapper);
        }
    }
    elsif (defined $wrapper) {
        $options = { $wrapper => $options };
    }

    return $options;
}


sub request {
    my ($self, $request) = @_;

    my $response;
    my $error;

    if (   ($self->retry_http_codes and scalar(@{ $self->retry_http_codes }))
        or ($self->retry_errors and scalar(@{ $self->retry_errors })))
    {
        my $times = $self->retry_times;
        my $n     = 0;

        while ($times-- > 0) {
            $n++;
            $self->log("try: $n/"
                    . $self->retry_times
                    . ' delay: '
                    . $self->retry_delay . 's')
                if $self->debug;

            $response = eval { $self->agent->request($request) };
            $error = $@;

            # if the user agent died there was a connection issue, definitely retry those
            unless ($error) {
                $self->_response($response);

                $self->log("recv payload: " . $response->decoded_content)
                    if $self->debug;

                return $response
                    unless $self->needs_retry($response,
                    $request->header('Accept'));
            }

            sleep $self->retry_delay if $times;    # Do not sleep in last time
        }
    }
    else {
        $response = eval { $self->agent->request($request) };
        $error = $@;

        $self->log("recv payload: " . $response->decoded_content)
            if $response and $self->debug;
    }

    $self->_response($response);

    die $error if $error;

    return $response;
}


sub needs_retry {
    my ($self, $response, $content_type) = @_;

    $self->log("response code was: " . $response->code)
        if $self->debug;

    return 1 if $response->code ~~ $self->retry_http_codes;

    if (    $self->retry_errors
        and scalar(@{ $self->retry_errors })
        and $self->error_keys
        and scalar(@{ $self->error_keys }))
    {
        # we need to decode the response content to be able to find a custom
        # error field
        my $content = $self->decode($response->decoded_content,
            ($response->header('Content-Type') || $content_type));

        my $error = $self->find_error($content);

        return unless $error;

        return 1 if map { $error =~ $_ } @{ $self->retry_errors };
    }

    return;
}


sub find_error {
    my ($self, $content) = @_;

    for (@{ $self->error_keys || [] }) {
        $self->log("checking for error at ($_)") if $self->debug;

        my $node = $self->key_exists($_, $content);

        if ($node) {
            $self->log("found error: '$node' at ($_)") if $self->debug;
            return $node;
        }
    }

    return;
}


sub format_response {
    my ($self, $response, $ct, $error) = @_;

    my $answer;

    if ($response) {

        # collect response headers
        my $response_headers;
        $response_headers->{$_} = $response->header($_)
            foreach ($response->header_field_names);

        # decode content if necessary
        unless ($self->_decoded_response) {
            if (    defined $response->decoded_content
                and length($response->decoded_content) > 0
                and $response->decoded_content =~ m/\S/)
            {
                $self->_decoded_response(
                    eval {
                        $self->decode($response->decoded_content,
                            ($response_headers->{'Content-Type'} || $ct));
                    });
                $error ||= $@;
            }
        }

        # search for and expose errors
        $error ||= $self->find_error($self->_decoded_response);

        $answer = {
            header  => $response_headers,
            code    => $response->code,
            content => $self->_decoded_response,
            raw     => $response->content,
            cookies => $self->cookies->get_cookies($self->base_url),
        };

        unless ($response->is_success || $response->is_redirect) {
            $error ||= $response->status_line;
        }
    }

    if ($error) {
        chomp($error);
        $self->log("ERROR: $error") if $self->debug;
        $answer->{error} = $error;
    }

    return $answer;
}


sub build_uri {
    my ($self, $command, $options, $path) = @_;

    my $uri = URI->new($self->base_url);
    my $p   = $uri->path;

    if ($path) {
        $p .= '/' . $path;

        # parse all mandatory ID keys from URI path
        # format: /path/with/some/:id/and/:another_id/fun.js
        my @mandatory = ($path =~ m/:(\w+)/g);

        # and replace placeholders
        foreach my $key (@mandatory) {
            die "required {$key} option missing\n"
                unless (exists $options->{$key});

            my $encoded_option = uri_escape(delete $options->{$key});
            $p =~ s/:$key/$encoded_option/gex;
        }
    }
    else {
        $p .= "/$command";
    }

    $p .= '.' . $self->extension if ($self->extension);
    $uri->path($p);

    return $uri;
}


sub build_content_type {
    my ($self, $command) = @_;

    return {
        in => $command->{incoming_content_type}
            || $command->{content_type}
            || $CONTENT_TYPE{ $self->extension }
            || $self->incoming_content_type
            || $self->content_type,
        out => $command->{outgoing_content_type}
            || $command->{content_type}
            || $self->outgoing_content_type
            || $self->content_type,
    };
}


sub DESTROY { }


sub AUTOLOAD {
    my ($self, %options) = @_;

    $self->clear_decoded_response;
    $self->clear_response;

    $self->base_url($self->test ? $self->test_url : $self->live_url);

    # sanity checks
    die "Attribute (base_url) is required\n" unless $self->base_url;
    if ($self->auth_type =~ m/^oauth_/) {
        for (qw(consumer_secret access_token access_secret)) {
            die "Attribute ($_) is required\n" unless $self->$_;
        }
    }

    my ($command) = $AUTOLOAD =~ /([^:]+)$/;

    my $ct;
    my $response = eval {
        die "unknown command: $command\n"
            unless (exists $self->commands->{$command});

        my $options = \%options;

        # construct URI
        my $uri =
            $self->build_uri($command, $options,
            $self->commands->{$command}->{path});

        # first select the right content types for encoding/decoding
        $ct = $self->build_content_type($self->commands->{$command});

        # then map options if necessary
        $options =
            $self->map_options($options, $self->commands->{$command}, $ct->{in})
            if (((keys %$options) and ($ct->{out} =~ m/(xml|json|urlencoded)/))
            or (exists $self->commands->{$command}->{default_attributes})
            or (exists $self->commands->{$command}->{mandatory}));

        # then check existence of mandatory attributes
        $self->check_mandatory($options,
            $self->commands->{$command}->{mandatory})
            if exists $self->commands->{$command}->{mandatory};

        # then extract query keys from options to prevent them being wrapped
        # in the next step
        my $query_keys;
        foreach my $key (keys %$options) {
            $query_keys->{$key} = delete $options->{$key}
                if $key ~~ $self->commands->{$command}->{query_keys};
        }

        # finally wrap all options in wrapper key(s) if requested
        my $method =
            uc($self->commands->{$command}->{method} || $self->default_method);
        $options =
            wrap($options,
            $self->commands->{$command}->{wrapper} || $self->wrapper,
            $ct->{in})
            unless ($method =~ m/^(GET|HEAD|DELETE)$/);

        $self->log("options:\n" . np(%$options)) if $self->debug;

        # do the talking
        return $self->talk($self->commands->{$command},
            $uri, $options, $query_keys, $ct);
    };

    return $self->format_response($self->_response, $ct->{in}, $@);
}


1;    # End of Web::API

__END__

=pod

=encoding UTF-8

=head1 NAME

Web::API - A Simple base module to implement almost every RESTful API with just a few lines of configuration

=head1 VERSION

version 2.7

=head1 SYNOPSIS

B<NOTE:> as of version 2.1 C<strict_ssl> is enabled by default for obvious security
reasons, this may break your current library implementation, sorry.

Implement the RESTful API of your choice in 10 minutes, roughly.

    package Net::CloudProvider;

    use Mouse;

    with 'Web::API';

    our $VERSION = "0.1";

    has 'commands' => (
        is      => 'rw',
        default => sub {
            {
                list_nodes => { method => 'GET' },
                node_info  => { method => 'GET', require_id => 1 },
                create_node => {
                    method             => 'POST',
                    default_attributes => {
                        allowed_hot_migrate            => 1,
                        required_virtual_machine_build => 1,
                        cpu_shares                     => 5,
                        required_ip_address_assignment => 1,
                        primary_network_id             => 1,
                        required_automatic_backup      => 0,
                        swap_disk_size                 => 1,
                    },
                    mandatory => [
                        'label',
                        'hostname',
                        'template_id',
                        'cpus',
                        'memory',
                        'primary_disk_size',
                        'required_virtual_machine_build',
                        'cpu_shares',
                        'primary_network_id',
                        'required_ip_address_assignment',
                        'required_automatic_backup',
                        'swap_disk_size',
                    ]
                },
                update_node => { method => 'PUT',    require_id => 1 },
                delete_node => { method => 'DELETE', require_id => 1 },
                start_node  => {
                    method       => 'POST',
                    require_id   => 1,
                    post_id_path => 'startup',
                },
                stop_node => {
                    method       => 'POST',
                    require_id   => 1,
                    post_id_path => 'shutdown',
                },
                suspend_node => {
                    method       => 'POST',
                    require_id   => 1,
                    post_id_path => 'suspend',
                },
            };
        },
    );

    sub commands {
        my ($self) = @_;
        return $self->commands;
    }

    sub BUILD {
        my ($self) = @_;

        $self->user_agent(__PACKAGE__ . ' ' . $VERSION);
        $self->live_url('https://ams01.cloudprovider.net/virtual_machines');
        $self->content_type('application/json');
        $self->extension('json');
        $self->wrapper('virtual_machine');
        $self->mapping({
                os        => 'template_id',
                debian    => 1,
                id        => 'label',
                disk_size => 'primary_disk_size',
        });

        return $self;
    }

    1;

later use as:

    use Net::CloudProvider;

    my $nc = Net::CloudProvider->new(user => 'foobar', api_key => 'secret');
    my $response = $nc->create_node({
        id                             => 'funnybox',
        hostname                       => 'node.funnybox.com',
        os                             => 'debian',
        cpus                           => 2,
        memory                         => 256,
        disk_size                      => 5,
        allowed_hot_migrate            => 1,
        required_virtual_machine_build => 1,
        cpu_shares                     => 5,
        required_ip_address_assignment => 1,
    });

=head1 ATTRIBUTES

=head2 commands

most important configuration part of the module which has to be provided by the
module you are writing.

the following keys are valid/possible:

    method
    path
    mandatory
    default_attributes
    headers
    extension
    content_type
    incoming_content_type
    outgoing_content_type
    wrapper
    query_keys
    require_id (deprecated, use path)
    pre_id_path (deprecated, use path)
    post_id_path (deprecated, use path)

the request path for commands is being build as:

    $base_url/$path.$extension

an example for C<path>:

    path => 'users/:user_id/labels'

this will add C<user_id> to the list of mandatory keys for this command
automatically.

=head2 live_url (required)

get/set base URL to API, can include paths

=head2 test_url (optional)

get/set base URL for test system if applicable

=head2 test (optional)

get/set boolean to run against base URL from test system or live system

=head2 api_key (required in most cases)

get/set API key (also used as basic auth password)

=head2 user (optional)

get/set API username/account name

=head2 api_key_field (optional)

get/set name of the hash key that has to hold the C<api_key>
e.g. in POST content payloads

=head2 api_version (optional)

get/set API version to be used

default: 1

=head2 mapping (optional)

supply mapping table, hashref of format { "key" => "value", ... }

=head2 wrapper (optional)

get/set name of the key that is used to wrap all options of a command in.
unfortunately some APIs increase the depth of a hash by wrapping everything into
a single key (who knows why...), which means this:

    $wa->command(%options);

turns C<%options> into:

    { wrapper => \%options }

before encoding and sending it off.

=head2 header (optional)

get/set custom headers sent with every request

=head2 auth_type

get/set authentication type. currently supported are only 'basic', 'header',
'hash_key', 'get_params', 'oauth_header', 'oauth_params' or 'none'

default: none

=head2 auth_header (optional)

get/set the name of the header used for Authorization credentials

default: Authorization

=head2 auth_header_token_format

get/set format of the auth_header token.

default: 'Token token=%s'

=head2 default_method (optional)

get/set default HTTP method

default: GET

=head2 extension (optional)

get/set file extension, e.g. 'json'

=head2 user_agent (optional)

get/set User Agent String

default: "Web::API $VERSION"

=head2 timeout (optional)

get/set L<LWP::UserAgent> timeout

=head2 strict_ssl (optional)

enable/disable strict SSL certificate hostname checking as a convenience
alternatively you can supply your own LWP::Useragent compatible agent for
the C<agent> attribute.

default: true

=head2 agent (optional)

get/set L<LWP::UserAgent> object

=head2 retry_http_codes (optional)

get/set array of HTTP response codes that trigger a retry of the request

=head2 retry_errors (optional)

define an array reference of regexes that should trigger a retry of the request
if matched against an error found via one of the C<error_keys>

=head2 retry_times (optional)

get/set number of times a request will be retried at most

default: 3

=head2 retry_delay (optional)

get/set delay to wait between retries. accepts float for millisecond support.

default: 1.0

=head2 content_type (optional)

global content type, which is used for in and out going request/response
headers and to encode and decode the payload if no other more specific content
types are set, e.g. C<incoming_content_type>, C<outgoing_content_type> or
content types set individually per command attribute.

default: 'text/plain'

=head2 incoming_content_type (optional)

default: undef

=head2 outgoing_content_type (optional)

default: undef

=head2 debug (optional)

enable/disabled debug logging

default: false

=head2 cookies (optional)

this is used to store and retrieve cookies before and after requests were made
to keep authenticated sessions alive for the time this object exists in memory
you can add your own cookies to be send with every request. See
L<HTTP::Cookies> for more information.

default: HTTP::Cookies->new()

=head2 consumer_secret (required for all oauth_* auth_types)

default: undef

=head2 access_token (required for all oauth_* auth_types)

default: undef

=head2 access_secret (required for all oauth_* auth_types)

default: undef

=head2 signature_method (required for all oauth_* auth_types)

default: undef

=head2 encoder (custom options encoding subroutine)

Receives C<\%options> and C<content-type> as the only 2 arguments and has to
return a single scalar.

default: undef

=head2 decoder (custom response content decoding subroutine)

Receives C<content> and C<content-type> as the only 2 scalar arguments and has
to return a single hash reference.

default: undef

=head2 oauth_post_body (required for all oauth_* auth_types)

enable/disable adding of command options as extra parameters to the OAuth
request generation and therefor be included in the OAuth signature calculation.

default: true

=head2 error_keys

get/set list of array keys that will be search for in the decoded response data
structure. the same format as for mandatory keys is supported:

    some.deeply.nested.error.message

will search for an error message at

    $decoded_response->{some}->{deeply}->{nested}->{error}->{messsage}

and if the key exists and its value is defined it will be provided as
C<$response->{error}> and matched against all regexes from the `retry_errors`
array ref if provided to trigger a retry on particular errors.

=head1 INTERNAL SUBROUTINES/METHODS

=head2 nonce

generates new OAuth nonce for every request

=head2 log

=head2 decode

=head2 encode

=head2 talk

=head2 map_options

=head2 check_mandatory

=head2 key_exists

=head2 wrap

=head2 request

retry request with delay if C<retry_http_codes> is set, otherwise just try once.

=head2 needs_retry

returns true if the HTTP code or error found match either C<retry_http_codes>
or C<retry_errors> respectively.
returns false otherwise.

if C<retry_errors> are defined it will try to decode the response content and
store the decoded structure internally so we don't have to decode again at the
end.

needs the last response object and the 'Accept' content type header from the
request for decoding.

=head2 find_error

go through C<error_keys> and find a potential error message in the decoded/parsed
response and return it.

=head2 format_response

=head2 build_uri

=head2 build_content_type

configure in/out content types

order of precedence:
1. per command C<incoming_content_type> / C<outgoing_content_type>
2. per command general C<content_type>
3. content type based on file path extension (only for incoming)
4. global C<incoming_content_type> / C<outgoing_content_type>
5. global general C<content_type>

=head2 DESTROY

catch DESTROY call and tear down / clean up if necessary
at this point there is nothing to do though. This prevents
AUTOLOAD from logging an unknown command error message

=head2 AUTOLOAD magic

install a method for each new command and call it in an C<eval {}> to catch
exceptions and set an error in a unified way.

=head1 BUGS

Please report any bugs or feature requests on GitHub's issue tracker L<https://github.com/nupfel/Web-API/issues>.
Pull requests welcome.

=head1 SUPPORT

You can find documentation for this module with the L<perldoc(1)> command.

    perldoc Web::API

You can also look for information at:

=over 4

=item * GitHub repository

L<https://github.com/nupfel/Web-API>

=item * MetaCPAN

L<https://metacpan.org/module/Web::API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Web::API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Web::API>

=back

=head1 SEE ALSO

L<HTTP::Cookies>, L<LWP::UserAgent>, L<Net::OAuth>

=head1 AUTHOR

Tobias Kirschstein <lev@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Tobias Kirschstein.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
