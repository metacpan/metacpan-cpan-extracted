package Zing::Store::Disk;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Zing::Store';

use File::Spec;

our $VERSION = '0.21'; # VERSION

# ATTRIBUTES

has root => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_root($self) {
  File::Spec->curdir
}

# BUILDERS

fun new_encoder($self) {
  require Zing::Encoder::Json; Zing::Encoder::Json->new;
}

# METHODS

method drop(Str $key) {
  return int(!!unlink $self->path($key));
}

method keys(Key $query) {
  my @paths = glob(File::Spec->catfile(
    $self->root, (map +($_ || '*'), (split(':', $query))[0..4])
  ));
  return [
    map {
      join(':', (reverse((reverse(File::Spec->splitdir($_)))[0..4])))
    }
    grep -f, @paths
  ];
}

method lpull(Str $key) {
  if ($self->test($key)) {
    if (my $data = $self->recv($key)) {
      my $result = shift @{$data->{list}};
      $self->send($key, $data);
      return $result;
    }
  }
  return undef;
}

method lpush(Str $key, HashRef $val) {
  if ($self->test($key)) {
    if (my $data = $self->recv($key)) {
      my $result = unshift @{$data->{list}}, $val;
      $self->send($key, $data);
      return $result;
    }
    else {
      return undef;
    }
  }
  else {
    my $data = {list => []};
    my $result = unshift @{$data->{list}}, $val;
    $self->send($key, $data);
    return $result;
  }
}

method path(Key $key) {
  my $dir = $self->root;
  mkdir $dir;
  for my $next ((split(':', $key))[0..3]) {
    $dir = File::Spec->catfile($dir, $next);
    mkdir $dir;
  }
  return File::Spec->catfile($self->root, split(':', $key));
}

method read(Str $file) {
  open my $fh, '<', $file
    or die "Can't open file ($file): $!";
  my $ret = my $data = '';
  while ($ret = $fh->sysread(my $buffer, 131072, 0)) {
    $data .= $buffer;
  }
  unless (defined $ret) {
    die "Can't read from file ($file): $!";
  }
  return $data;
}

method recv(Str $key) {
  my $data = $self->read($self->path($key));
  return $data ? $self->decode($data) : $data;
}

method rpull(Str $key) {
  if ($self->test($key)) {
    if (my $data = $self->recv($key)) {
      my $result = pop @{$data->{list}};
      $self->send($key, $data);
      return $result;
    }
  }
  return undef;
}

method rpush(Str $key, HashRef $val) {
  if ($self->test($key)) {
    if (my $data = $self->recv($key)) {
      my $result = push @{$data->{list}}, $val;
      $self->send($key, $data);
      return $result;
    }
    else {
      return undef;
    }
  }
  else {
    my $data = {list => []};
    my $result = push @{$data->{list}}, $val;
    $self->send($key, $data);
    return $result;
  }
}

method send(Str $key, HashRef $val) {
  my $set = $self->encode($val);
  $self->write($self->path($key), $set);
  return 'OK';
}

method size(Str $key) {
  if ($self->test($key)) {
    if (my $data = $self->recv($key)) {
      return scalar(@{$data->{list}});
    }
  }
  return 0;
}

method slot(Str $key, Int $pos) {
  if ($self->test($key)) {
    if (my $data = $self->recv($key)) {
      return $data->{list}[$pos];
    }
  }
  return undef;
}

method test(Str $key) {
  return -f $self->path($key) ? 1 : 0;
}

method write(Str $file, Str $data) {
  open my $fh, '>', $file
    or die "Can't open file ($file): $!";
  ($fh->syswrite($data) // -1) == length $data
    or die "Can't write to file ($file): $!";
  return $self;
}

1;

=encoding utf8

=head1 NAME

Zing::Store::Disk - Disk Storage

=cut

=head1 ABSTRACT

Disk Storage Abstraction

=cut

=head1 SYNOPSIS

  use Zing::Store::Disk;
  use Zing::Encoder::Dump;

  my $disk = Zing::Store::Disk->new(
    encoder => Zing::Encoder::Dump->new
  );

  # $disk->drop;

=cut

=head1 DESCRIPTION

This package provides an in-memory (only) storage adapter for use with data
persistence abstractions.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Zing::Store>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 decode

  decode(Str $data) : HashRef

The decode method decodes the JSON data provided and returns the data as a hashref.

=over 4

=item decode example #1

  # given: synopsis

  $disk->decode('{"status"=>"ok"}');

=back

=cut

=head2 drop

  drop(Str $key) : Int

The drop method removes (drops) the item from the datastore.

=over 4

=item drop example #1

  # given: synopsis

  $disk->drop('zing:main:global:model:temp');

=back

=cut

=head2 encode

  encode(HashRef $data) : Str

The encode method encodes and returns the data provided as JSON.

=over 4

=item encode example #1

  # given: synopsis

  $disk->encode({ status => 'ok' });

=back

=cut

=head2 keys

  keys(Str @keys) : ArrayRef[Str]

The keys method returns a list of keys under the namespace of the datastore or
provided key.

=over 4

=item keys example #1

  # given: synopsis

  my $keys = $disk->keys('zing:main:global:model:temp');

=back

=over 4

=item keys example #2

  # given: synopsis

  $disk->send('zing:main:global:model:temp', { status => 'ok' });

  my $keys = $disk->keys('zing:main:global:model:temp');

=back

=cut

=head2 lpull

  lpull(Str $key) : Maybe[HashRef]

The lpull method pops data off of the top of a list in the datastore.

=over 4

=item lpull example #1

  # given: synopsis

  $disk->lpull('zing:main:global:model:items');

=back

=over 4

=item lpull example #2

  # given: synopsis

  $disk->rpush('zing:main:global:model:items', { status => 'ok' });

  $disk->lpull('zing:main:global:model:items');

=back

=cut

=head2 lpush

  lpush(Str $key, HashRef $val) : Int

The lpush method pushed data onto the top of a list in the datastore.

=over 4

=item lpush example #1

  # given: synopsis

  $disk->lpush('zing:main:global:model:items', { status => '1' });

=back

=over 4

=item lpush example #2

  # given: synopsis

  $disk->lpush('zing:main:global:model:items', { status => '0' });

=back

=cut

=head2 recv

  recv(Str $key) : Maybe[HashRef]

The recv method fetches and returns data from the datastore by its key.

=over 4

=item recv example #1

  # given: synopsis

  $disk->recv('zing:main:global:model:temp');

=back

=over 4

=item recv example #2

  # given: synopsis

  $disk->send('zing:main:global:model:temp', { status => 'ok' });

  $disk->recv('zing:main:global:model:temp');

=back

=cut

=head2 rpull

  rpull(Str $key) : Maybe[HashRef]

The rpull method pops data off of the bottom of a list in the datastore.

=over 4

=item rpull example #1

  # given: synopsis

  $disk->rpull('zing:main:global:model:items');

=back

=over 4

=item rpull example #2

  # given: synopsis

  $disk->rpush('zing:main:global:model:items', { status => 1 });
  $disk->rpush('zing:main:global:model:items', { status => 2 });

  $disk->rpull('zing:main:global:model:items');

=back

=cut

=head2 rpush

  rpush(Str $key, HashRef $val) : Int

The rpush method pushed data onto the bottom of a list in the datastore.

=over 4

=item rpush example #1

  # given: synopsis

  $disk->rpush('zing:main:global:model:items', { status => 'ok' });

=back

=over 4

=item rpush example #2

  # given: synopsis

  $disk->rpush('zing:main:global:model:items', { status => 'ok' });

  $disk->rpush('zing:main:global:model:items', { status => 'ok' });

=back

=cut

=head2 send

  send(Str $key, HashRef $val) : Str

The send method commits data to the datastore with its key and returns truthy.

=over 4

=item send example #1

  # given: synopsis

  $disk->send('zing:main:global:model:temp', { status => 'ok' });

=back

=cut

=head2 size

  size(Str $key) : Int

The size method returns the size of a list in the datastore.

=over 4

=item size example #1

  # given: synopsis

  my $size = $disk->size('zing:main:global:model:items');

=back

=over 4

=item size example #2

  # given: synopsis

  $disk->rpush('zing:main:global:model:items', { status => 'ok' });

  my $size = $disk->size('zing:main:global:model:items');

=back

=cut

=head2 slot

  slot(Str $key, Int $pos) : Maybe[HashRef]

The slot method returns the data from a list in the datastore by its index.

=over 4

=item slot example #1

  # given: synopsis

  my $model = $disk->slot('zing:main:global:model:items', 0);

=back

=over 4

=item slot example #2

  # given: synopsis

  $disk->rpush('zing:main:global:model:items', { status => 'ok' });

  my $model = $disk->slot('zing:main:global:model:items', 0);

=back

=cut

=head2 test

  test(Str $key) : Int

The test method returns truthy if the specific key (or datastore) exists.

=over 4

=item test example #1

  # given: synopsis

  $disk->rpush('zing:main:global:model:items', { status => 'ok' });

  $disk->test('zing:main:global:model:items');

=back

=over 4

=item test example #2

  # given: synopsis

  $disk->drop('zing:main:global:model:items');

  $disk->test('zing:main:global:model:items');

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/zing/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/zing/wiki>

L<Project|https://github.com/iamalnewkirk/zing>

L<Initiatives|https://github.com/iamalnewkirk/zing/projects>

L<Milestones|https://github.com/iamalnewkirk/zing/milestones>

L<Contributing|https://github.com/iamalnewkirk/zing/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/zing/issues>

=cut
