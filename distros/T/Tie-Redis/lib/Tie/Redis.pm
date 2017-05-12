package Tie::Redis;
{
  $Tie::Redis::VERSION = '0.26';
}
# ABSTRACT: Connect perl data structures to Redis
use strict;
use Carp ();

use Tie::Redis::Connection;
use Tie::Redis::Hash;
use Tie::Redis::List;
use Tie::Redis::Scalar;

sub TIEHASH {
  my($class, %args) = @_;
  my $serialize = delete $args{serialize};
  
  my $conn = Tie::Redis::Connection->new(%args);
  Carp::croak "Unable to connect to Redis server: $!" unless $conn;

  bless {
    _conn     => $conn,
    serialize => $class->_serializer($serialize),
  }, $class;
}

sub _serializer {
  my($self, $serialize) = @_;

  my %serializers = (
    json => [
      sub { require JSON },
      \&JSON::to_json,
      \&JSON::from_json
    ],
    storable => [
      sub { require Storable },
      \&Storable::nfreeze,
      \&Storaable::thaw
    ],
    msgpack => [
      sub { require Data::MessagePack },
      sub { unshift @_, "Data::MessagePack"; goto &Data::MessagePack::pack },
      sub { unshift @_, "Data::MessagePack"; goto &Data::MessagePack::unpack }
    ],
  );

  my $serializer = $serializers{$serialize || ''} || [undef, (sub {
    Carp::croak("No serializer specified for Tie::Redis; unable to handle nested structures");
  }) x 2];

  # Load; will error if required module isn't present
  $serializer->[0] && $serializer->[0]->();

  return $serializer;
}

sub _cmd {
  my($self, $cmd, @args) = @_;

  if($self->{prefix} && defined $args[0]) {
    $args[0] = "$self->{prefix}$args[0]";
  }

  $self->{_conn}->$cmd(@args);
}

sub STORE {
  my($self, $key, $value) = @_;

  if(!ref $value) {
    $self->_cmd(set => $key, $value);

  } elsif(ref $value eq 'HASH') {
    # TODO: Should pipeline somehow
    $self->_cmd("multi");
    $self->_cmd(del => $key);
    $self->_cmd(hmset => $key,
          map +($_ => $value->{$_}), keys %$value);
    $self->_cmd("exec");
    $self->{_type_cache}->{$key} = 'hash';

  } elsif(ref $value eq 'ARRAY') {
    $self->_cmd("multi");
    $self->_cmd(del => $key);
    for my $v(@$value) {
      $self->_cmd(rpush => $key, $v);
    }
    $self->_cmd("exec");
    $self->{_type_cache}->{$key} = 'list';

  } elsif(ref $value) {
    $self->_cmd(set => $key, $self->{serialize}->[1]->($value));
  }
}

sub FETCH {
  my($self, $key) = @_;
  my $type = exists $self->{_type_cache}->{$key}
    ? $self->{_type_cache}->{$key}
    : $self->_cmd(type => $key);

  if($type eq 'hash') {
    tie my %h, "Tie::Redis::Hash", redis => $self, key => $key;
    return \%h;
  } elsif($type eq 'list') {
    tie my @l, "Tie::Redis::List", redis => $self, key => $key;
    return \@l;
  } elsif($type eq 'set') {
    die "Sets yet to be implemented...";
  } elsif($type eq 'zset') {
    die "Zsets yet to be implemented...";
  } elsif($type eq 'string') {
    $self->_cmd(get => $key);
  } else {
    return undef;
  }
}

sub FIRSTKEY {
  my($self) = @_;
  my $keys = $self->_cmd(keys => "*");
  $self->{keys} = $keys;
  $self->NEXTKEY;
}

sub NEXTKEY {
  my($self) = @_;
  shift @{$self->{keys}};
}

sub EXISTS {
  my($self, $key) = @_;
  $self->_cmd(exists => $key);
}

sub DELETE {
  my($self, $key) = @_;
  $self->_cmd(del => $key);
}

sub CLEAR {
  my($self, $key) = @_;
  if($self->{prefix}) {
    $self->_cmd(del => $self->_cmd(keys => "*"));
  } else {
    $self->_cmd("flushdb");
  }
}

sub SCALAR {
  my($self) = @_;
  $self->_cmd("dbsize");
}

1;



__END__
=pod

=head1 NAME

Tie::Redis - Connect perl data structures to Redis

=head1 VERSION

version 0.26

=head1 SYNOPSIS

 use Tie::Redis;
 tie my %r, "Tie::Redis";

 $r{foo} = 42;

 print $r{foo}; # 42, persistently

=head1 DESCRIPTION

This allows basic access to Redis from Perl using tie, so it looks just like a
a hash or array.

B<Please> think carefully before using this, the tie interface has quite a
performance overhead and the error handling is not that great. Using
L<AnyEvent::Redis> or L<Redis> directly is recommended.

=head2 General usage

L<Tie::Redis> provides an interface to the top level Redis "hash table";
depending on the type of key you access this then returns a value tied to
L<Tie::Redis::Hash>, L<Tie::Redis::List>, L<Tie::Redis::Scalar> or a set type
(unfortunately, these aren't yet implemented).

If an error occurs these types will throw an exception, therefore you may want
to surround your Redis accessing code with an C<eval> block (or use
L<Try::Tiny>).

=head2 Issues

There are some cases where Redis and Perl types do not match, for example empty
lists in Redis have a type of "none", therefore if you empty a list and then
try to access it again it will no longer be an array reference.

Autovivification currently doesn't correctly work, I believe some of this may
be fixable but haven't yet fully investigated.

=head1 SEE ALSO

=over 4

=item * L<App::redisp>

A redis shell in Perl and the main reason I wrote this
module.

=item * L<Tie::Redis::Attributes>

An experimental attribute based interface.

=item * L<Redis>

Another Redis API.

=back

=head1 AUTHOR

David Leadbeater <dgl@dgl.cx>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David Leadbeater.

This program is free software. It comes without any warranty, to the extent
permitted by applicable law. You can redistribute it and/or modify it under the
terms of the Beer-ware license revision 42.

=cut

