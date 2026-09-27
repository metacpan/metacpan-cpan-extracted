package WebDyne::Cloudflare::D1;

use 5.020;
use strict;
use warnings;

use Future::AsyncAwait;
use WebDyne::Cloudflare ();
use Encode qw(decode FB_CROAK);
use JSON::PP ();
use MIME::Base64 qw(decode_base64);
use Scalar::Util qw(blessed);
use WebDyne::Cloudflare::D1::Blob;
use WebDyne::Cloudflare::D1::Error;
use WebDyne::Cloudflare::D1::Statement;

our $VERSION='0.001';
our $HOST_CALL;

use constant EXTENSION_NAME => 'webdyne.cloudflare.d1';
use constant PROTOCOL_VERSION => 1;

my $json_or=JSON::PP->new()->canonical()->allow_nonref();

sub new {
    my ($class, %opt)=@_;
    my $scope_hr=$opt{'scope'};
    die "WebDyne::Cloudflare::D1 requires a PAGI scope hash\n"
        unless ref($scope_hr) eq 'HASH';
    my $extension_hr=(ref($scope_hr->{'extensions'}) eq 'HASH')
        ? $scope_hr->{'extensions'}{EXTENSION_NAME()}
        : undef;
    die "PAGI scope has no " . EXTENSION_NAME() . " capability\n"
        unless ref($extension_hr) eq 'HASH';
    die "Unsupported D1 capability protocol\n"
        unless (defined($extension_hr->{'version'})
            &&!ref($extension_hr->{'version'})
            &&($extension_hr->{'version'} eq PROTOCOL_VERSION()));
    die "Invalid D1 capability token\n"
        unless (defined($extension_hr->{'capability'})
            &&!ref($extension_hr->{'capability'})
            &&length($extension_hr->{'capability'}));

    my $binding=(defined($opt{'binding'}) ? $opt{'binding'} : 'DB');
    die "Invalid D1 binding name '$binding'\n"
        unless (!ref($binding)&&($binding=~/\A[A-Z_][A-Z0-9_]*\z/));
    my $bindings_ar=$extension_hr->{'bindings'};
    die "Invalid D1 capability binding list\n"
        unless (ref($bindings_ar) eq 'ARRAY');
    my %binding=map { $_ => 1 } grep { defined($_)&&!ref($_) } @{$bindings_ar};
    die "D1 binding '$binding' is not available to this request\n"
        unless $binding{$binding};

    my $self=bless({
        binding    => $binding,
        capability => $extension_hr->{'capability'},
        sessions   => (ref($extension_hr->{'session_bindings'}) eq 'ARRAY'
            &&grep { defined($_)&&!ref($_)&&($_ eq $binding) } @{$extension_hr->{'session_bindings'}}) ? 1 : 0,
    }, $class);
    return $self;
}


async sub with_session {
    my ($self, $constraint)=@_;
    die "D1 Sessions API is unavailable for this binding\n" unless $self->{'sessions'};
    die "Cannot create a session from a session\n" if exists($self->{'session'});
    die "D1 session requires a non-empty constraint or bookmark\n"
        unless ((@_<=2)&&((@_==1)||(defined($constraint)&&!ref($constraint)&&length($constraint))));
    my $id=await $self->execute(operation => 'with_session',
        constraint => (defined($constraint) ? $constraint : 'first-unconstrained'));
    require WebDyne::Cloudflare::D1::Session;
    return bless({%{$self}, session => $id}, 'WebDyne::Cloudflare::D1::Session');
}


sub binding {
    return shift()->{'binding'};
}


sub blob {
    #  Accept function, class and object calls without discarding payload bytes.
    #
    shift() if ((@_>1)&&(defined($_[0])
        &&(blessed($_[0])||(!ref($_[0])&&($_[0] eq __PACKAGE__)))));
    die "D1 blob requires exactly one byte string\n" unless (@_==1);
    return WebDyne::Cloudflare::D1::Blob->new($_[0]);
}


sub prepare {
    my ($self, $sql)=@_;
    die "D1 prepare requires a non-empty SQL string\n"
        unless (defined($sql)&&!ref($sql)&&length($sql));
    return WebDyne::Cloudflare::D1::Statement->new(
        database => $self,
        sql      => $sql,
    );
}


async sub run {
    my ($self, $sql, @param)=@_;
    return await $self->prepare($sql)->bind(@param)->run();
}


async sub all {
    my ($self, $sql, @param)=@_;
    return await $self->prepare($sql)->bind(@param)->all();
}


async sub first {
    my ($self, $sql, @param)=@_;
    return await $self->prepare($sql)->bind(@param)->first();
}


async sub batch {
    my ($self, $statements_ar)=@_;
    die "D1 batch requires one non-empty array of prepared statements\n"
        unless ((@_==2)&&(ref($statements_ar) eq 'ARRAY')&&@{$statements_ar});

    #  Validate every statement before crossing the host boundary.
    #
    my @request;
    foreach my $statement_or (@{$statements_ar}) {
        die "D1 batch entries must be D1 prepared statements\n"
            unless (blessed($statement_or)
                &&$statement_or->isa('WebDyne::Cloudflare::D1::Statement'));
        push(@request, $statement_or->batch_request($self));
    }
    return await $self->execute(operation => 'batch', statements => \@request);
}


sub encode_parameter {
    my ($value_ref)=@_;
    return undef unless defined($value_ref);
    if (blessed($value_ref)&&$value_ref->isa('WebDyne::Cloudflare::D1::Blob')) {
        return $value_ref->wire_value();
    }
    if (!ref($value_ref)) {
        #  Decode web text strictly, preserving ASCII numeric/string flags.
        #  Binary input must use blob().
        #
        return decode('UTF-8', $value_ref, FB_CROAK)
            if (!utf8::is_utf8($value_ref)&&($value_ref=~/[\x80-\xff]/));
        return $value_ref;
    }
    return $value_ref if (blessed($value_ref)&&$value_ref->isa('JSON::PP::Boolean'));
    die "D1 bind values must be scalars, undef, JSON booleans, or D1 blobs\n";
}


sub decode_value {
    my ($value_ref)=@_;
    return $value_ref unless (ref($value_ref) eq 'HASH');
    die "D1 host returned an invalid blob value\n"
        unless (defined($value_ref->{'type'})&&($value_ref->{'type'} eq 'blob')
            &&defined($value_ref->{'base64'})&&!ref($value_ref->{'base64'}));
    return decode_base64($value_ref->{'base64'});
}


sub decode_row {
    my ($row_hr)=@_;
    die "D1 host returned an invalid row\n" unless (ref($row_hr) eq 'HASH');
    return {map { $_ => decode_value($row_hr->{$_}) } keys(%{$row_hr})};
}


sub decode_result {
    my ($request_hr, $result_ref)=@_;

    if ($request_hr->{'operation'} eq 'with_session' || $request_hr->{'operation'} eq 'get_bookmark') {
        die WebDyne::Cloudflare::D1::Error->new(
            name => 'D1_PROTOCOL_ERROR', message => 'host returned an invalid session value',
        ) unless ((!defined($result_ref)&&($request_hr->{'operation'} eq 'get_bookmark'))
            ||(defined($result_ref)&&!ref($result_ref)&&length($result_ref)));
        return $result_ref;
    }

    if ($request_hr->{'operation'} eq 'batch') {
        die WebDyne::Cloudflare::D1::Error->new(
            name    => 'D1_PROTOCOL_ERROR',
            message => 'host returned an invalid batch result count',
        ) unless ((ref($result_ref) eq 'ARRAY')
            &&(@{$result_ref}==@{$request_hr->{'statements'}}));
        foreach my $result_hr (@{$result_ref}) {
            die WebDyne::Cloudflare::D1::Error->new(
                name    => 'D1_PROTOCOL_ERROR',
                message => 'host returned an invalid batch result',
            ) unless ((ref($result_hr) eq 'HASH')
                &&(ref($result_hr->{'results'}) eq 'ARRAY')&&$result_hr->{'success'});
        }
        return [map { decode_result({operation => 'run'}, $_) } @{$result_ref}];
    }

    #  Decode only column values; rows can legitimately have type/base64 columns.
    #
    if ($request_hr->{'operation'} eq 'first') {
        return undef unless defined($result_ref);
        return exists($request_hr->{'column'})
            ? decode_value($result_ref) : decode_row($result_ref);
    }
    if ($request_hr->{'operation'} eq 'raw') {
        return [map { [map { decode_value($_) } @{$_}] } @{$result_ref}];
    }
    $result_ref->{'results'}=[map { decode_row($_) } @{$result_ref->{'results'}}];
    return $result_ref;
}


sub call_host {
    my ($wire)=@_;
    return $HOST_CALL->($wire) if $HOST_CALL;
    no strict 'refs';
    my $host_call_cr=*{'WebDyne::Cloudflare::D1::Host::call'}{'CODE'};
    die "D1 host adapter is not registered in this runtime\n" unless $host_call_cr;
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
    $wire_hr->{'session'}=$self->{'session'} if exists($self->{'session'});
    if ($request{'operation'} eq 'batch') {
        $wire_hr->{'statements'}=[map {
            {sql => $_->{'sql'}, params => [map { encode_parameter($_) } @{$_->{'params'}}]}
        } @{$request{'statements'}}];
    }
    else {
        $wire_hr->{'params'}=[map { encode_parameter($_) } @{(defined($wire_hr->{'params'}) ? $wire_hr->{'params'} : [])}];
    }

    my $response_wire=call_host($json_or->encode(WebDyne::Cloudflare::json_value($wire_hr)));
    my $response_hr=eval { $json_or->decode($response_wire) };
    if ((ref($response_hr) ne 'HASH')||!exists($response_hr->{'ok'})) {
        my $detail=$@||'host returned an invalid response';
        die WebDyne::Cloudflare::D1::Error->new(
            name    => 'D1_PROTOCOL_ERROR',
            message => $detail,
        );
    }
    unless ($response_hr->{'ok'}) {
        my $error_hr=ref($response_hr->{'error'}) eq 'HASH' ? $response_hr->{'error'} : {};
        die WebDyne::Cloudflare::D1::Error->new(%{$error_hr});
    }
    return decode_result(\%request, $response_hr->{'result'});
}

1;
