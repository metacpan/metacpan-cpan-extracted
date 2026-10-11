package Unblock::HTTP2::_nghttp2;

use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.11';

require XSLoader;
XSLoader::load('Unblock::HTTP2', $VERSION);

sub available { return _available() ? 1 : 0 }

use constant {
    SETTINGS_HEADER_TABLE_SIZE       => 1,
    SETTINGS_ENABLE_PUSH             => 2,
    SETTINGS_MAX_CONCURRENT_STREAMS  => 3,
    SETTINGS_INITIAL_WINDOW_SIZE     => 4,
    SETTINGS_MAX_FRAME_SIZE          => 5,
    SETTINGS_MAX_HEADER_LIST_SIZE    => 6,
    SETTINGS_ENABLE_CONNECT_PROTOCOL => 8,
    SETTINGS_NO_RFC7540_PRIORITIES   => 9,
};

package Unblock::HTTP2::_nghttp2::Session;

use strict;
use warnings;
use Carp qw(croak);

sub _callbacks {
    my ($callbacks) = @_;
    $callbacks ||= {};
    croak 'callbacks must be a hash reference' unless ref($callbacks) eq 'HASH';
    for my $name (keys %$callbacks) {
        my $cb = $callbacks->{$name};
        croak "callback $name must be a coderef"
            if defined($cb) && ref($cb) ne 'CODE';
    }
    return $callbacks;
}

sub _max_header_list_size {
    my ($operation, $args) = @_;
    my $limit = exists($args->{max_header_list_size})
        ? delete($args->{max_header_list_size})
        : 65_536;
    croak "$operation: max_header_list_size must be a positive integer"
        unless defined($limit) && !ref($limit)
            && "$limit" =~ /\A[0-9]+\z/ && $limit > 0;
    return 0 + $limit;
}

sub new_client {
    my ($class, %args) = @_;
    my $callbacks = _callbacks(delete($args{callbacks}));
    my $max_header_list_size = _max_header_list_size('new_client()', \%args);
    croak 'new_client(): unknown options: ' . join(', ', sort keys %args)
        if %args;
    return $class->_new_client_xs($callbacks, $max_header_list_size);
}

sub new_server {
    my ($class, %args) = @_;
    my $callbacks = _callbacks(delete($args{callbacks}));
    my $max_header_list_size = _max_header_list_size('new_server()', \%args);
    croak 'new_server(): unknown options: ' . join(', ', sort keys %args)
        if %args;
    return $class->_new_server_xs($callbacks, $max_header_list_size);
}

sub send_connection_preface {
    my ($self, %settings) = @_;
    return $self->submit_settings(\%settings);
}

sub _body_provider {
    my ($body) = @_;
    return unless defined $body;
    return $body if ref($body) eq 'CODE';
    croak 'body must be a byte string or coderef' if ref($body);
    return if !length($body);

    my $offset = 0;
    my $length = length($body);
    return sub {
        my ($stream_id, $max_length) = @_;
        my $left = $length - $offset;
        my $take = $left < $max_length ? $left : $max_length;
        my $chunk = substr($body, $offset, $take);
        $offset += $take;
        return ($chunk, $offset >= $length ? 1 : 0);
    };
}

sub _submit_request_xs {
    my ($self, $headers, $body) = @_;
    my $provider = _body_provider($body);
    return $self->_submit_request_native($headers, $provider);
}

sub _submit_request_uniform_xs {
    my ($self, $message, $body) = @_;
    my $provider = _body_provider($body);
    return $self->_submit_request_uniform_native($message, $provider);
}

sub submit_response_uniform {
    my ($self, $stream_id, $message, %args) = @_;
    my $body = delete($args{body});
    my $data_callback = delete($args{data_callback});
    delete $args{callback_data};
    croak 'submit_response_uniform(): unknown options: '
        . join(', ', sort keys %args)
        if %args;

    my $provider = defined($data_callback)
        ? _body_provider($data_callback)
        : _body_provider($body);

    return $provider
        ? $self->_submit_response_uniform_streaming_native(
            $stream_id, $message, $provider,
        )
        : $self->_submit_response_uniform_no_body_native(
            $stream_id, $message,
        );
}

sub submit_response_headers_uniform {
    my ($self, $stream_id, $message, %args) = @_;
    my $end_stream = delete($args{end_stream}) || 0;
    croak 'submit_response_headers_uniform(): unknown options: '
        . join(', ', sort keys %args)
        if %args;

    return $self->_submit_response_headers_uniform_native(
        $stream_id, $message, $end_stream ? 1 : 0,
    );
}

sub submit_response {
    my ($self, $stream_id, %args) = @_;
    my $status = exists($args{status}) ? delete($args{status}) : 200;
    my $headers = delete($args{headers}) || [];
    my $body = delete $args{body};
    my $data_callback = delete $args{data_callback};
    delete $args{callback_data};
    croak 'submit_response(): unknown options: ' . join(', ', sort keys %args)
        if %args;
    croak 'submit_response(): headers must be an array reference'
        unless ref($headers) eq 'ARRAY';
    croak 'submit_response(): status must be an integer'
        unless defined($status) && !ref($status) && $status =~ /\A[0-9]+\z/;

    my @block = ([ ':status', "$status" ], @$headers);
    my $provider = defined($data_callback)
        ? _body_provider($data_callback)
        : _body_provider($body);

    return $provider
        ? $self->_submit_response_streaming_native($stream_id, \@block, $provider)
        : $self->_submit_response_no_body_native($stream_id, \@block);
}

sub submit_headers {
    my ($self, $stream_id, %args) = @_;
    my $headers = delete($args{headers}) || [];
    my $end_stream = delete($args{end_stream}) || 0;
    croak 'submit_headers(): unknown options: ' . join(', ', sort keys %args)
        if %args;
    croak 'submit_headers(): headers must be an array reference'
        unless ref($headers) eq 'ARRAY';
    return $self->_submit_headers_native($stream_id, $headers, $end_stream ? 1 : 0);
}

sub submit_trailer {
    my ($self, $stream_id, %args) = @_;
    my $headers = delete($args{headers}) || [];
    croak 'submit_trailer(): unknown options: ' . join(', ', sort keys %args)
        if %args;
    croak 'submit_trailer(): headers must be an array reference'
        unless ref($headers) eq 'ARRAY';
    return $self->_submit_trailer_native($stream_id, $headers);
}

sub submit_priority_update {
    my ($self, $stream_id, $field_value) = @_;
    croak 'submit_priority_update(): stream id must be a positive integer'
        unless defined($stream_id) && !ref($stream_id)
            && "$stream_id" =~ /\A[0-9]+\z/ && $stream_id > 0;
    croak 'submit_priority_update(): field value must be a scalar'
        if ref($field_value);
    $field_value = '' unless defined $field_value;
    croak 'submit_priority_update(): field value exceeds 16380 bytes'
        if length($field_value) > 16_380;
    return $self->_submit_priority_update_native($stream_id, $field_value);
}

sub submit_ping {
    my ($self, $opaque) = @_;
    croak 'submit_ping(): opaque data must be exactly 8 bytes'
        unless defined($opaque) && !ref($opaque) && length($opaque) == 8;
    return $self->_submit_ping_native($opaque);
}

sub submit_goaway {
    my ($self, %args) = @_;
    my $last_stream_id = delete $args{last_stream_id};
    croak 'submit_goaway(): last_stream_id is required'
        unless defined $last_stream_id;
    my $error_code = exists($args{error_code}) ? delete($args{error_code}) : 0;
    my $debug_data = exists($args{debug_data})
        ? delete($args{debug_data})
        : delete($args{opaque_data});
    croak 'submit_goaway(): unknown options: ' . join(', ', sort keys %args)
        if %args;
    return $self->_submit_goaway_native($last_stream_id, $error_code, $debug_data);
}

sub resume_stream {
    my ($self, $stream_id) = @_;
    $self->_clear_deferred($stream_id);
    return $self->resume_data($stream_id);
}

1;
