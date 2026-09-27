package WebDyne::Cloudflare::DurableObject;

use 5.020;
use strict;
use warnings;
use Future::AsyncAwait;
use JSON::PP ();
use Scalar::Util qw(blessed refaddr);
use MIME::Base64 qw(encode_base64 decode_base64);
use WebDyne::Cloudflare ();
use WebDyne::Cloudflare::DurableObject::Bytes;
use WebDyne::Cloudflare::DurableObject::Error;

our $VERSION='0.001';
our $HOST_CALL;
my $json_or=JSON::PP->new()->canonical()->allow_nonref();

sub capability {
    my ($scope_hr)=@_;
    die "Durable Object requires a scope hash\n" unless (ref($scope_hr) eq 'HASH');
    my $extension_hr=$scope_hr->{'extensions'}{'webdyne.cloudflare.durable_object'};
    die "No valid Durable Object capability in scope\n"
        unless ((ref($extension_hr) eq 'HASH')&&($extension_hr->{'version'}||0)==1
            &&defined($extension_hr->{'capability'})&&!ref($extension_hr->{'capability'})
            &&length($extension_hr->{'capability'})&&(ref($extension_hr->{'bindings'}) eq 'ARRAY'));
    return $extension_hr;
}


sub new {
    my ($class, %opt)=@_;
    my $extension_hr=capability($opt{'scope'});
    my $binding=$opt{'binding'};
    die "Durable Object requires an available binding\n"
        unless (defined($binding)&&!ref($binding)
            &&grep { $_ eq $binding } @{$extension_hr->{'bindings'}});
    return bless({capability => $extension_hr->{'capability'}, binding => $binding}, $class);
}


async sub get_by_name {
    my ($self, $name)=@_;
    my $id=await $self->execute(operation => 'resolve', name => $name);
    return bless({%{$self}, id => $id}, ref($self));
}


async sub get_by_id {
    my ($self, $id)=@_;
    $id=await $self->execute(operation => 'validate_id', id => $id);
    return bless({%{$self}, id => $id}, ref($self));
}


sub id { return shift()->{'id'}; }
sub binding { return shift()->{'binding'}; }


async sub call {
    my ($self, $method, @args)=@_;
    die "Select a Durable Object before calling a method\n" unless $self->{'id'};
    return decode_value(await $self->execute(operation => 'call', id => $self->{'id'},
        method => $method, args => encode_value(\@args)));
}


sub bytes {
    shift() if ((@_==2)&&(blessed($_[0])||(!ref($_[0])&&defined($_[0])&&($_[0] eq __PACKAGE__))));
    return WebDyne::Cloudflare::DurableObject::Bytes->new(@_);
}


sub encode_value {
    my ($value_ref, $seen_hr, $depth)=@_;
    $depth=0 unless defined($depth);
    die "Durable Object value nesting exceeds 64\n" if ($depth>64);
    return WebDyne::Cloudflare::json_value($value_ref) unless ref($value_ref);
    return $value_ref if JSON::PP::is_bool($value_ref);
    if (blessed($value_ref)&&$value_ref->isa('WebDyne::Cloudflare::DurableObject::Bytes')) {
        return {t => 'bytes', v => encode_base64($value_ref->value(), '')};
    }
    die "Durable Object values must be arrays, hashes or explicit bytes\n"
        unless ((ref($value_ref) eq 'HASH')||(ref($value_ref) eq 'ARRAY'));
    $seen_hr={} unless $seen_hr;
    my $address=refaddr($value_ref);
    die "Cyclic Durable Object value\n" if $seen_hr->{$address};
    local $seen_hr->{$address}=1;
    return {t => 'array', v => [map { encode_value($_, $seen_hr, $depth+1) } @{$value_ref}]}
        if (ref($value_ref) eq 'ARRAY');
    return {t => 'hash', v => {map { $_ => encode_value($value_ref->{$_}, $seen_hr, $depth+1) } keys(%{$value_ref})}};
}


sub decode_value {
    my ($value_ref, $depth)=@_;
    $depth=0 unless defined($depth);
    die "Durable Object value nesting exceeds 64\n" if ($depth>64);
    return $value_ref unless ref($value_ref);
    return $value_ref if JSON::PP::is_bool($value_ref);
    die "Invalid Durable Object value envelope\n"
        unless ((ref($value_ref) eq 'HASH')&&(keys(%{$value_ref})==2)&&defined($value_ref->{'t'}));
    my $type=$value_ref->{'t'};
    my $item_ref=$value_ref->{'v'};
    if (($type eq 'bytes')&&defined($item_ref)&&!ref($item_ref)
        &&($item_ref=~/\A(?:[A-Za-z0-9+\/]{4})*(?:[A-Za-z0-9+\/]{2}==|[A-Za-z0-9+\/]{3}=)?\z/)) {
        return bytes(decode_base64($item_ref));
    }
    return [map { decode_value($_, $depth+1) } @{$item_ref}]
        if (($type eq 'array')&&(ref($item_ref) eq 'ARRAY'));
    return {map { $_ => decode_value($item_ref->{$_}, $depth+1) } keys(%{$item_ref})}
        if (($type eq 'hash')&&(ref($item_ref) eq 'HASH'));
    die "Invalid Durable Object value envelope\n";
}


async sub execute {
    my ($self, %request)=@_;
    my $wire=$json_or->encode(WebDyne::Cloudflare::json_value({
        version => 1, capability => $self->{'capability'}, binding => $self->{'binding'}, %request,
    }));
    die "Durable Object request exceeds limit\n" if (length($wire)>1048576);
    no strict 'refs';
    my $host_cr=$HOST_CALL||*{'WebDyne::Cloudflare::DurableObject::Host::call'}{'CODE'};
    die "Durable Object host adapter is not registered\n" unless $host_cr;
    my $response_hr=$json_or->decode($host_cr->($wire));
    die "Invalid Durable Object host response\n" unless ((ref($response_hr) eq 'HASH')&&exists($response_hr->{'ok'}));
    die WebDyne::Cloudflare::DurableObject::Error->new(%{$response_hr->{'error'}}) unless $response_hr->{'ok'};
    return $response_hr->{'result'};
}

1;
