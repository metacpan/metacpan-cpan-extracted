package WebDyne::Cloudflare::DurableObject::Context;

use 5.020;
use strict;
use warnings;
use Future::AsyncAwait;
use WebDyne::Cloudflare::DurableObject;
our @ISA=qw(WebDyne::Cloudflare::DurableObject);
our $VERSION='0.001';

sub new {
    my ($class, $scope_hr)=@_;
    my $extension_hr=WebDyne::Cloudflare::DurableObject::capability($scope_hr);
    die "Context is only available inside a Durable Object\n" unless $extension_hr->{'id'};
    return bless({capability => $extension_hr->{'capability'}, id => $extension_hr->{'id'}, scope => $scope_hr}, $class);
}

sub scope { return shift()->{'scope'}; }
sub storage { return shift(); }


sub statement {
    my ($sql, $attr_hr, @params)=@_;
    die "Storage attributes are not supported\n" if defined($attr_hr);
    die "SQL must be non-empty text\n" unless (defined($sql)&&!ref($sql)&&length($sql));
    return {sql => $sql, params => WebDyne::Cloudflare::DurableObject::encode_value(\@params)};
}


async sub query {
    my ($self, @args)=@_;
    return WebDyne::Cloudflare::DurableObject::decode_value(
        await $self->execute(operation => 'sql', statement => statement(@args)));
}


async sub do {
    my ($self, @args)=@_;
    my $result_hr=await $self->query(@args);
    return $result_hr->{'rows_written'};
}


async sub selectrow_hashref {
    my ($self, @args)=@_;
    my $result_hr=await $self->query(@args);
    return $result_hr->{'rows'}[0];
}


async sub selectall_arrayref {
    my ($self, @args)=@_;
    my $result_hr=await $self->query(@args);
    return $result_hr->{'rows'};
}


async sub batch {
    my ($self, $statements_ar)=@_;
    die "batch requires a non-empty array of [SQL, undef, bind values...]\n"
        unless ((ref($statements_ar) eq 'ARRAY')&&@{$statements_ar});
    my @statements;
    foreach my $statement_ar (@{$statements_ar}) {
        die "Invalid batch statement\n" unless (ref($statement_ar) eq 'ARRAY');
        push(@statements, statement(@{$statement_ar}));
    }
    return WebDyne::Cloudflare::DurableObject::decode_value(
        await $self->execute(operation => 'batch', statements => \@statements));
}

1;
