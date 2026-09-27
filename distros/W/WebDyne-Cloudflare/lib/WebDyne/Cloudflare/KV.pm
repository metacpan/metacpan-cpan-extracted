package WebDyne::Cloudflare::KV;

use 5.020;
use strict;
use warnings;

use Encode qw(decode FB_CROAK);
use Future::AsyncAwait;
use WebDyne::Cloudflare ();
use JSON::PP ();
use MIME::Base64 qw(decode_base64);
use Scalar::Util qw(blessed);
use WebDyne::Cloudflare::KV::Blob;
use WebDyne::Cloudflare::KV::Error;

our $VERSION='0.001';
our $HOST_CALL;

use constant EXTENSION_NAME => 'webdyne.cloudflare.kv';
use constant PROTOCOL_VERSION => 1;

my $json_or=JSON::PP->new()->canonical()->allow_nonref();

sub new {
    my ($class, %opt)=@_;
    my $scope_hr=$opt{'scope'};
    die "WebDyne::Cloudflare::KV requires a PAGI scope hash\n"
        unless ref($scope_hr) eq 'HASH';
    my $extension_hr=(ref($scope_hr->{'extensions'}) eq 'HASH')
        ? $scope_hr->{'extensions'}{EXTENSION_NAME()}
        : undef;
    die "PAGI scope has no " . EXTENSION_NAME() . " capability\n"
        unless ref($extension_hr) eq 'HASH';
    die "Unsupported KV capability protocol\n"
        unless (defined($extension_hr->{'version'})
            &&!ref($extension_hr->{'version'})
            &&($extension_hr->{'version'} eq PROTOCOL_VERSION()));
    die "Invalid KV capability token\n"
        unless (defined($extension_hr->{'capability'})
            &&!ref($extension_hr->{'capability'})
            &&length($extension_hr->{'capability'}));

    my $binding=(defined($opt{'binding'}) ? $opt{'binding'} : 'KV');
    die "Invalid KV binding name '$binding'\n"
        unless (!ref($binding)&&($binding=~/\A[A-Z_][A-Z0-9_]*\z/));
    my $bindings_ar=$extension_hr->{'bindings'};
    die "Invalid KV capability binding list\n"
        unless (ref($bindings_ar) eq 'ARRAY');
    my %binding=map { $_ => 1 } grep { defined($_)&&!ref($_) } @{$bindings_ar};
    die "KV binding '$binding' is not available to this request\n"
        unless $binding{$binding};

    my $self=bless({
        binding    => $binding,
        capability => $extension_hr->{'capability'},
    }, $class);
    return $self;
}


sub binding { return shift()->{'binding'}; }


sub blob {
    #  Accept function, class and object calls without discarding payload bytes.
    #
    shift() if ((@_>1)&&(defined($_[0])
        &&(blessed($_[0])||(!ref($_[0])&&($_[0] eq __PACKAGE__)))));
    die "KV blob requires exactly one byte string\n" unless (@_==1);
    return WebDyne::Cloudflare::KV::Blob->new($_[0]);
}


sub key {
    my ($key)=@_;
    die "KV key must be a non-empty scalar other than . or ..\n"
        unless (defined($key)&&!ref($key)&&length($key)
            &&($key ne '.')&&($key ne '..'));
    return $key;
}


sub known_options {
    my ($operation, $allowed_ar, %opt)=@_;
    my %allowed=map { $_ => 1 } @{$allowed_ar};
    my @unknown=sort grep { !$allowed{$_} } keys %opt;
    die "Unknown KV $operation option: $unknown[0]\n" if @unknown;
    return %opt;
}


sub encode_text {
    my ($value_ref)=@_;
    die "KV value must be a scalar or KV blob\n" if (!defined($value_ref)||ref($value_ref));
    return decode('UTF-8', $value_ref, FB_CROAK)
        if (!utf8::is_utf8($value_ref)&&($value_ref=~/[\x80-\xff]/));
    return "$value_ref";
}


sub decode_bytes {
    my ($value_ref)=@_;
    return undef unless defined($value_ref);
    die "KV host returned an invalid byte value\n"
        unless ((ref($value_ref) eq 'HASH')
            &&defined($value_ref->{'type'})&&($value_ref->{'type'} eq 'bytes')
            &&defined($value_ref->{'base64'})&&!ref($value_ref->{'base64'}));
    return decode_base64($value_ref->{'base64'});
}


async sub get {
    my ($self, $key, %opt)=@_;
    %opt=known_options('get', [qw(type cache_ttl)], %opt);
    my $type=(defined($opt{'type'}) ? $opt{'type'} : 'text');
    die "KV get type must be text, json, or bytes\n"
        unless (($type eq 'text')||($type eq 'json')||($type eq 'bytes'));
    my $result_ref=await $self->execute(
        operation => 'get',
        key       => key($key),
        type      => $type,
        (defined($opt{'cache_ttl'}) ? (cache_ttl => $opt{'cache_ttl'}) : ()),
    );
    return $type eq 'bytes' ? decode_bytes($result_ref) : $result_ref;
}


async sub get_with_metadata {
    my ($self, $key, %opt)=@_;
    %opt=known_options('get_with_metadata', [qw(type cache_ttl)], %opt);
    my $type=(defined($opt{'type'}) ? $opt{'type'} : 'text');
    die "KV get type must be text, json, or bytes\n"
        unless (($type eq 'text')||($type eq 'json')||($type eq 'bytes'));
    my $result_ref=await $self->execute(
        operation => 'get_with_metadata',
        key       => key($key),
        type      => $type,
        (defined($opt{'cache_ttl'}) ? (cache_ttl => $opt{'cache_ttl'}) : ()),
    );
    $result_ref->{'value'}=decode_bytes($result_ref->{'value'})
        if (($type eq 'bytes')&&(ref($result_ref) eq 'HASH'));
    return $result_ref;
}


async sub put {
    my ($self, $key, $value_ref, %opt)=@_;
    %opt=known_options('put', [qw(expiration expiration_ttl metadata)], %opt);
    my $encoded_ref=(blessed($value_ref)&&$value_ref->isa('WebDyne::Cloudflare::KV::Blob'))
        ? $value_ref->wire_value()
        : encode_text($value_ref);
    return await $self->execute(
        operation => 'put',
        key       => key($key),
        value     => $encoded_ref,
        (defined($opt{'expiration'}) ? (expiration => $opt{'expiration'}) : ()),
        (defined($opt{'expiration_ttl'}) ? (expiration_ttl => $opt{'expiration_ttl'}) : ()),
        (exists($opt{'metadata'}) ? (metadata => $opt{'metadata'}) : ()),
    );
}


async sub put_json {
    my ($self, $key, $value_ref, %opt)=@_;
    return await $self->put($key, $json_or->encode(WebDyne::Cloudflare::json_value($value_ref)), %opt);
}


async sub delete {
    my ($self, $key)=@_;
    return await $self->execute(operation => 'delete', key => key($key));
}


async sub list {
    my ($self, %opt)=@_;
    %opt=known_options('list', [qw(prefix cursor limit)], %opt);
    return await $self->execute(operation => 'list', %opt);
}


sub call_host {
    my ($wire)=@_;
    return $HOST_CALL->($wire) if $HOST_CALL;
    no strict 'refs';
    my $host_call_cr=*{'WebDyne::Cloudflare::KV::Host::call'}{'CODE'};
    die "KV host adapter is not registered in this runtime\n" unless $host_call_cr;
    return $host_call_cr->($wire);
}


async sub execute {
    my ($self, %request)=@_;
    my $wire_hr={
        version    => PROTOCOL_VERSION,
        capability => $self->{'capability'},
        binding    => $self->{'binding'},
        %request,
    };
    my $response_wire=call_host($json_or->encode(WebDyne::Cloudflare::json_value($wire_hr)));
    my $response_hr=eval { $json_or->decode($response_wire) };
    if ((ref($response_hr) ne 'HASH')||!exists($response_hr->{'ok'})) {
        my $detail=$@||'host returned an invalid response';
        die WebDyne::Cloudflare::KV::Error->new(name => 'KV_PROTOCOL_ERROR', message => $detail);
    }
    unless ($response_hr->{'ok'}) {
        my $error_hr=ref($response_hr->{'error'}) eq 'HASH' ? $response_hr->{'error'} : {};
        die WebDyne::Cloudflare::KV::Error->new(%{$error_hr});
    }
    return $response_hr->{'result'};
}

1;
