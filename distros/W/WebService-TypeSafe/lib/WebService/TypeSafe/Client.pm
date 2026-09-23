package WebService::TypeSafe::Client;

use 5.020;
use strict;
use warnings;
use Carp qw(croak);
use HTTP::Tiny;
use JSON::PP qw(encode_json decode_json);
use Scalar::Util qw(blessed);
use Time::HiRes qw(time sleep);
use WebService::TypeSafe::Error ();
use WebService::TypeSafe::Models ();
use WebService::TypeSafe::Question ();
use WebService::TypeSafe::Response ();
use WebService::TypeSafe::RetryPolicy ();

sub new {
    my ($class, @args) = @_;
    my %args = @args == 1 && ref($args[0]) eq 'HASH' ? %{ $args[0] } : @args;
    my $api_key = exists $args{api_key} ? $args{api_key} : $ENV{TYPESAFE_API_KEY};
    $api_key =~ s/^\s+|\s+$//g if defined $api_key;
    _throw('TypeSafe API key is required') unless defined($api_key) && length($api_key);
    _throw('TypeSafe API key contains whitespace, control, or non-ASCII characters')
        if $api_key =~ /\s|[^\x21-\x7e]/;
    my $base_url = $args{base_url} // $ENV{TYPESAFE_BASE_URL} // 'https://api.typesafe.ai';
    $base_url =~ s{/+$}{};
    my $timeout = $args{timeout} // 60;
    _throw('timeout must be a positive number')
        unless $timeout =~ /^\d+(?:\.\d+)?$/ && $timeout > 0;
    my $retry = $args{retry} // WebService::TypeSafe::RetryPolicy->new;
    $retry = WebService::TypeSafe::RetryPolicy->new($retry) if ref($retry) eq 'HASH';
    _throw('retry must be a WebService::TypeSafe::RetryPolicy')
        unless blessed($retry) && $retry->isa('WebService::TypeSafe::RetryPolicy');
    my $self = bless {
        api_key => $api_key,
        model => $args{model} // $ENV{TYPESAFE_DEFAULT_MODEL} // 'jev-latest',
        base_url => $base_url,
        timeout => $timeout,
        retry => $retry,
        headers => { %{ $args{headers} || {} } },
        http => $args{http},
        sleeper => $args{sleeper} || sub { sleep($_[0]) },
    }, $class;
    $self->{models} = WebService::TypeSafe::Models->new($self);
    return $self;
}

sub model { $_[0]->{model} }
sub models { $_[0]->{models} }

sub system_one {
    my ($self, %args) = @_;
    _throw('state is required') unless exists $args{state} && defined $args{state};
    _throw('questions must be a nonempty hash reference')
        unless ref($args{questions}) eq 'HASH' && keys %{ $args{questions} };
    my %questions;
    for my $name (keys %{ $args{questions} }) {
        my $q = $args{questions}{$name};
        $questions{$name} = blessed($q) && $q->can('as_hash') ? $q->as_hash : $q;
        _throw("question '$name' must be a question object or hash reference")
            unless ref($questions{$name}) eq 'HASH';
    }
    my $body = {
        state => $args{state},
        model => $args{model} // $self->{model},
        questions => \%questions,
        %{ $args{extra_body} || {} },
    };
    my $data = $self->_request('POST', '/v1/systemone', $body,
        map { exists($args{$_}) ? ($_ => $args{$_}) : () }
            qw(retry timeout extra_headers));
    _validate_response($data, $self->{base_url} . '/v1/systemone');
    return WebService::TypeSafe::Response->from_hash($data);
}

sub _request {
    my ($self, $method, $path, $body, %opts) = @_;
    my $retry = $opts{retry} // $self->{retry};
    $retry = WebService::TypeSafe::RetryPolicy->new($retry) if ref($retry) eq 'HASH';
    my $timeout = $opts{timeout} // $self->{timeout};
    my $url = $self->{base_url} . $path;
    my %headers = (
        'accept' => 'application/json',
        'content-type' => 'application/json',
        'authorization' => 'Bearer ' . $self->{api_key},
        'user-agent' => 'webservice-typesafe-perl/' . $WebService::TypeSafe::VERSION,
        %{ $self->{headers} },
        %{ $opts{extra_headers} || {} },
    );
    # Authentication and protocol headers cannot be accidentally overridden.
    $headers{authorization} = 'Bearer ' . $self->{api_key};
    $headers{accept} = 'application/json';
    my $content = defined($body) ? eval { encode_json($body) } : undef;
    _throw("request body is not JSON encodable: $@") if defined($body) && $@;
    my $started = time;
    my $retry_number = 0;
    my $last_error;
    while (1) {
        my $response;
        my $ok = eval {
            my $http = $self->{http} || HTTP::Tiny->new(timeout => $timeout);
            my %request = (headers => \%headers);
            $request{content} = $content if defined $content;
            $response = ref($http) eq 'CODE'
                ? $http->($method, $url, \%request)
                : $http->request($method, $url, \%request);
            1;
        };
        if (!$ok || !$response) {
            my $error = WebService::TypeSafe::ConnectionError->new(
                message => 'connection to TypeSafe API failed: ' . ($@ || 'no response'),
                endpoint => "$method $url",
            );
            $last_error = $error;
            if ($retry->{connection_errors} && $retry_number < $retry->max_retries) {
                my $delay = $retry->delay(++$retry_number, {});
                last if defined($retry->timeout) && time - $started + $delay >= $retry->timeout;
                $self->{sleeper}->($delay); next;
            }
            die $error;
        }
        my %response_headers = map { lc($_) => $response->{headers}{$_} }
            keys %{ $response->{headers} || {} };
        # HTTP::Tiny represents transport failures as synthetic HTTP 599 responses.
        if (($response->{status} || 0) == 599) {
            my $is_timeout = ($response->{content} // '') =~ /tim(?:e|ed)\s*out/i;
            my $class = $is_timeout
                ? 'WebService::TypeSafe::TimeoutError' : 'WebService::TypeSafe::ConnectionError';
            my %fields = (
                message => 'connection to TypeSafe API failed: ' . ($response->{content} // $response->{reason} // 'unknown error'),
                endpoint => "$method $url",
            );
            $fields{timeout} = $timeout if $is_timeout;
            $last_error = $class->new(%fields);
            if ($retry->{connection_errors} && $retry_number < $retry->max_retries) {
                my $delay = $retry->delay(++$retry_number, \%response_headers);
                last if defined($retry->timeout) && time - $started + $delay >= $retry->timeout;
                $self->{sleeper}->($delay); next;
            }
            die $last_error;
        }
        if ($response->{success}) {
            my $data = eval { decode_json($response->{content} // '') };
            if ($@ || ref($data) ne 'HASH') {
                die WebService::TypeSafe::ResponseValidationError->new(
                    message => 'TypeSafe API returned invalid JSON', status => $response->{status},
                    body => $response->{content}, headers => \%response_headers,
                    endpoint => "$method $url", field_path => '',
                );
            }
            return $data;
        }
        my $status = $response->{status} || 0;
        $last_error = _api_error($status, $response->{content}, \%response_headers, "$method $url");
        if ($retry->should_retry_status($status) && $retry_number < $retry->max_retries) {
            my $delay = $retry->delay(++$retry_number, \%response_headers);
            last if defined($retry->timeout) && time - $started + $delay >= $retry->timeout;
            $self->{sleeper}->($delay); next;
        }
        die $last_error;
    }
    die $last_error;
}

sub _api_error {
    my ($status, $content, $headers, $endpoint) = @_;
    my $body = eval { decode_json($content // '') };
    $body = $content if $@;
    my $class = $status == 400 ? 'WebService::TypeSafe::BadRequestError'
        : $status == 401 ? 'WebService::TypeSafe::AuthenticationError'
        : $status == 403 ? 'WebService::TypeSafe::PermissionDeniedError'
        : $status == 404 ? 'WebService::TypeSafe::NotFoundError'
        : $status == 422 ? 'WebService::TypeSafe::UnprocessableEntityError'
        : $status == 429 ? 'WebService::TypeSafe::RateLimitError'
        : $status >= 500 ? 'WebService::TypeSafe::InternalServerError'
        : 'WebService::TypeSafe::APIError';
    return $class->new(
        message => "TypeSafe API request failed with HTTP $status",
        status => $status, body => $body, headers => $headers, endpoint => $endpoint,
    );
}

sub _validate_response {
    my ($data, $endpoint) = @_;
    my ($path, $message);
    if (!defined $data->{model}) { ($path, $message) = ('model', 'missing model') }
    elsif (ref($data->{answers}) ne 'HASH') { ($path, $message) = ('answers', 'missing answers object') }
    elsif (ref($data->{usage}) ne 'HASH') { ($path, $message) = ('usage', 'missing usage object') }
    if ($message) {
        die WebService::TypeSafe::ResponseValidationError->new(
            message => "invalid TypeSafe response: $message", status => 200,
            body => $data, headers => {}, endpoint => "POST $endpoint", field_path => $path,
        );
    }
}

sub _throw { die WebService::TypeSafe::Error->new(message => $_[0]) }
sub close { return }

1;
