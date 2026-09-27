package WebDyne::Cloudflare::D1::Statement;

use 5.020;
use strict;
use warnings;
use Future::AsyncAwait;
use JSON::PP ();
use Scalar::Util qw(blessed refaddr);

our $VERSION='0.001';

sub new {
    my ($class, %opt)=@_;
    my $self=bless({
        database => $opt{'database'},
        sql      => $opt{'sql'},
        params   => (defined($opt{'params'}) ? $opt{'params'} : []),
    }, $class);
    return $self;
}


sub bind {
    my ($self, @param)=@_;
    return ref($self)->new(
        database => $self->{'database'},
        sql      => $self->{'sql'},
        params   => \@param,
    );
}


sub batch_request {
    my ($self, $database_or)=@_;
    my $owner_or=$self->{'database'};
    die "D1 batch statements must belong to the same database object\n"
        unless (blessed($owner_or)&&$owner_or->isa('WebDyne::Cloudflare::D1')
            &&(refaddr($owner_or)==refaddr($database_or)));
    my $sql=$self->{'sql'};
    die "D1 batch statement requires a non-empty SQL string\n"
        unless (defined($sql)&&!ref($sql)&&length($sql));
    die "D1 batch statement parameters must be an array reference\n"
        unless (ref($self->{'params'}) eq 'ARRAY');
    return {sql => $sql, params => [@{$self->{'params'}}]};
}


async sub run {
    my ($self)=@_;
    return await $self->{'database'}->execute(
        operation => 'run',
        sql       => $self->{'sql'},
        params    => $self->{'params'},
    );
}


async sub all {
    my ($self)=@_;
    return await $self->run();
}


async sub first {
    my ($self, $column)=@_;
    my %request=(
        operation => 'first',
        sql       => $self->{'sql'},
        params    => $self->{'params'},
    );
    $request{'column'}=$column if defined($column);
    return await $self->{'database'}->execute(%request);
}


async sub raw {
    my ($self, %opt)=@_;
    return await $self->{'database'}->execute(
        operation    => 'raw',
        sql          => $self->{'sql'},
        params       => $self->{'params'},
        column_names => $opt{'column_names'} ? JSON::PP::true() : JSON::PP::false(),
    );
}

1;
