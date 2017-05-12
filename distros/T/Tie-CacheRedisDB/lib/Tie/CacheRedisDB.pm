package Tie::CacheRedisDB;

use strict;
use warnings;
use 5.010;
our $VERSION = '1.0.1';

use Carp qw(croak);
use Scalar::Util qw(reftype);
use Cache::RedisDB;

sub TIEHASH {
    my ($self, $addr, $args) = @_;

    # Don't want to be crazy strict, but at least something which implies they know how this works.
    my $whatsit = reftype $args;

    croak 'Must supply a lookup element' unless defined $addr;
    croak 'Arguments must be supplied as a hash reference.'
      unless (not defined $whatsit)
      or (($whatsit // '') eq 'HASH');

    my $where = [$args->{namespace} // "TIECACHEREDISDB", $addr];

    my $node = {
        EXP_SECONDS  => $args->{expiry},
        CAN_MISS     => $args->{can_miss} // 2,
        DIRTY        => 0,
        DEL_ON_UNTIE => 0,
        WHERE        => $where,
        DATA         => Cache::RedisDB->get(@$where) // {},
    };

    return bless $node, $self;
}

sub FETCH {
    my ($self, $key) = @_;

    return $self->{DATA}->{$key};
}

sub STORE {
    my ($self, $key, $val) = @_;

    $self->{DATA}->{$key} = $val;
    return $self->_check_dirty;
}

sub _check_dirty {
    my $self = shift;

    $self->{DIRTY} += 1;
    $self->sync
      if ($self->{DIRTY} > $self->{CAN_MISS});   # Need to hit the backing store

    return;
}

sub DELETE {
    my ($self, $key) = @_;

    my $val = delete $self->{DATA}->{$key};
    $self->_check_dirty;

    return $val;
}

sub CLEAR {
    my $self = shift;

    $self->{DATA} = {};
    return $self->sync;

}

sub EXISTS {
    my ($self, $key) = @_;

    return exists $self->{DATA}->{$key};
}

sub FIRSTKEY {
    my $self = shift;

    return each %{$self->{DATA}};
}

sub NEXTKEY {
    my $self = shift;

    return each %{$self->{DATA}};
}

sub SCALAR {
    my $self = shift;

    return scalar %{$self->{DATA}};
}

sub UNTIE {
    my $self = shift;

    return ($self->{DEL_ON_UNTIE})
        ? Cache::RedisDB->del(@{$self->{WHERE}})
        : $self->sync;
}

sub DESTROY {
    my $self = shift;

    return $self->UNTIE;
}

sub sync {
    my $self = shift;

    Cache::RedisDB->set(@{$self->{WHERE}}, $self->{DATA}, $self->{EXP_SECONDS});

    return $self->{DIRTY} = 0;    # Since we've sync'd it's not longer dirty,
}

sub delete {
    my $self = shift;

    return $self->{DEL_ON_UNTIE} = 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Tie::CacheRedisDB - Tie a hash to a Cache::RedisDB

=head1 SYNOPSIS

  use Tie::CacheRedisDB;

  tie %hash, 'Tie::CacheRedisDB', 'myrediskey';
  tie %hash, 'Tie::CacheRedisDB', 'myrediskey',
    { can_miss => 0, expiry => 60, namespace => 'junk' };


=head1 DESCRIPTION

Tie::CacheRedisDB is to simplify using key-value storage by presenting
a familiar interface while using a Redis backing store.

Arguments to the tie should be presented in a single hash reference.

=over 4

=item can_miss
The number of updates allowed between persisting to the backing store.
Defaults to 2.  The structure will still be synced upon destroy.

=item expiry
The number of seconds (since last update) after which the key should be culled.
Defaults to `undef` (no expiration) .

=item namespace
B<Cache::RedisDB> namespace for the associated keys.

=back

=head1 AUTHOR

Inspire.com

=head1 COPYRIGHT

Copyright 2016- Inspire

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
