package Tie::Hash::RedisDB;

use strict;
use warnings;
our $VERSION = '1.03';

use Carp qw(croak);
use JSON;
use Scalar::Util qw(reftype);
use RedisDB;
use Try::Tiny;

my $json = JSON->new->utf8->allow_nonref;

sub TIEHASH {
    my ($self, $addr, $args) = @_;

    # Don't want to be crazy strict, but at least something which implies they know how this works.
    my $whatsit = reftype $args;

    croak 'Must supply a lookup element' unless defined $addr;
    croak 'Arguments must be supplied as a hash reference.'
      unless ($whatsit // '') eq 'HASH';

    # All easy server definition for Cache::RedisDB users
    my $ruri = $args->{redis_uri} // $ENV{REDIS_CACHE_SERVER};
    croak 'Must supply a redis_redis' unless $ruri;

    my $node = {
        EXP_SECONDS  => $args->{expiry},
        DEL_ON_UNTIE => 0,
        WHERE        => join(chr(2), ($args->{namespace} // "THRDB"), $addr),
        REDIS => RedisDB->new(url => $ruri),
    };

    return bless $node, $self;

}

sub FETCH {
    my ($self, $key) = @_;

    my $val = $self->{REDIS}->hget($self->{WHERE}, $key);

    return $val && $json->decode($val);
}

sub STORE {
    my ($self, $key, $val) = @_;

    my $redis = $self->{REDIS};

    $redis->hset($self->{WHERE}, $key, $json->encode($val));
    if (my $expiry = $self->{EXP_SECONDS}) {
        $redis->expire($self->{WHERE}, $expiry);
    }

    return 1;
}

sub DELETE {
    my ($self, $key) = @_;

    return $self->{REDIS}->hdel($self->{WHERE}, $key);
}

sub CLEAR {
    my ($self) = @_;

    return $self->{REDIS}->del($self->{WHERE});
}

sub EXISTS {
    my ($self, $key) = @_;

    return $self->{REDIS}->hexists($self->{WHERE}, $key);
}

sub FIRSTKEY {
    my ($self) = @_;

    $self->{_keys} = $self->{REDIS}->hkeys($self->{WHERE});

    return $self->NEXTKEY;
}

sub NEXTKEY {
    my ($self) = @_;

    return shift @{$self->{_keys}};
}

sub UNTIE {
    my ($self) = @_;

    return $self->{DEL_ON_UNTIE} ? $self->CLEAR : 1;
}

sub DESTROY {
    my ($self) = @_;

    return $self->UNTIE;
}

sub delete {
    my ($self) = @_;

    return $self->{DEL_ON_UNTIE} = 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Tie::Hash::RedisDB - A very thin Tie around a RedisDB Hash

=head1 SYNOPSIS

  use Tie::Hash::RedisDB;
  my $redis_key = 'scrub';
  my %bucket;
  tie %bucket, 'Tie::Hash::RedisDB', $redis_key,
   { expiry => 60, namespace => 'buckets', redis_uri => 'redis://localhost'};

=head1 DESCRIPTION

Tie::Hash::RedisDB is Redis hashes refied into perl hashes.

=head1 AUTHOR

ClinicaHealth, Inc. dba Inspire

=head1 COPYRIGHT

Copyright 2018- Inspire

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
