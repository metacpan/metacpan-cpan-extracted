package Zing::Store::Pg;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Zing::Store';

our $VERSION = '0.03'; # VERSION

# ATTRIBUTES

has client => (
  is => 'ro',
  isa => 'InstanceOf["DBI::db"]',
  new => 1,
);

fun new_client($self) {
  my $dbname = $ENV{ZING_DBNAME} || 'zing';
  my $dbhost = $ENV{ZING_DBHOST} || 'localhost';
  my $dbport = $ENV{ZING_DBPORT} || '5432';
  my $dbuser = $ENV{ZING_DBUSER} || 'postgres';
  my $dbpass = $ENV{ZING_DBPASS};
  require DBI; DBI->connect(
    join(';',
      "dbi:Pg:dbname=$dbname",
      $dbhost ? join('=', 'host', $dbhost) : (),
      $dbport ? join('=', 'port', $dbport) : (),
    ),
    $dbuser, $dbpass,
    {
      AutoCommit => 1,
      PrintError => 0,
      RaiseError => 1
    }
  );
}

has meta => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_meta($self) {
  require Zing::ID; Zing::ID->new->string
}

has table => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_table($self) {
  $ENV{ZING_DBZONE} || 'entities'
}

# BUILDERS

fun new_encoder($self) {
  require Zing::Encoder::Dump; Zing::Encoder::Dump->new;
}

fun BUILD($self) {
  my $client = $self->client;
  my $table = $self->table;
  local $@; eval {
    $client->do(qq{
      create table if not exists "$table" (
        "id" serial primary key,
        "key" varchar not null,
        "value" text not null,
        "index" integer default 0,
        "meta" varchar null
      )
    });
  }
  unless (defined(do{
    local $@;
    local $client->{RaiseError} = 0;
    local $client->{PrintError} = 0;
    eval {
      $client->do(qq{
        select 1 from "$table" where 1 = 1
      })
    }
  }));
  return $self;
}

fun DESTROY($self) {
  $self->client->disconnect;
  return $self;
}

# METHODS

my $retries = 10;

method drop(Str $key) {
  my $table = $self->table;
  my $client = $self->client;
  my $sth = $client->prepare(
    qq{delete from "$table" where "key" = ?}
  );
  $sth->execute($key);
  return $sth->rows > 0 ? 1 : 0;
}

method keys(Str $query) {
  $query =~ s/\*/%/g;
  my $table = $self->table;
  my $client = $self->client;
  my $data = $client->selectall_arrayref(
    qq{select distinct("key") from "$table" where "key" like ?},
    {},
    $query,
  );
  return [map $$_[0], @$data];
}

method lpull(Str $key) {
  my $table = $self->table;
  my $client = $self->client;
  for my $attempt (1..$retries) {
    local $@; eval {
      my $sth = $client->prepare(
        qq{
          update "$table" set "meta" = ? where "id" = (
            select "me"."id" from "$table" "me"
            where "me"."key" = ? and "me"."meta" is null
            order by "me"."index" asc limit 1
          )
        }
      );
      $sth->execute($self->meta, $key);
    };
    if ($@) {
      die $@ if $attempt == $retries;
    }
    else {
      last;
    }
  }
  my $data = $client->selectrow_arrayref(
    qq{
      select "id", "value"
      from "$table" where "meta" = ? and "key" = ? order by "index" asc limit 1
    },
    {},
    $self->meta, $key,
  );
  if ($data) {
    my $sth = $client->prepare(
      qq{delete from "$table" where "id" = ?}
    );
    $sth->execute($data->[0]);
  }
  return $data ? $self->decode($data->[1]) : undef;
}

method lpush(Str $key, HashRef $val) {
  my $table = $self->table;
  my $client = $self->client;
  my $sth = $client->prepare(
    qq{
      insert into "$table" ("key", "value", "index") values (?, ?, (
        select coalesce(min("me"."index"), 0) - 1
        from "$table" "me" where "me"."key" = ?
      ))
    }
  );
  for my $attempt (1..$retries) {
    local $@; eval {
      $sth->execute($key, $self->encode($val), $key);
    };
    if ($@) {
      die $@ if $attempt == $retries;
    }
    else {
      last;
    }
  }
  return $sth->rows;
}

method read(Str $key) {
  my $table = $self->table;
  my $client = $self->client;
  my $data = $client->selectrow_arrayref(
    qq{
      select "value" from "$table"
      where "key" = ? order by "id" desc limit 1
    },
    {},
    $key,
  );
  return $data ? $data->[0] : undef;
}

method recv(Str $key) {
  my $data = $self->read($key);
  return $data ? $self->decode($data) : $data;
}

method rpull(Str $key) {
  my $table = $self->table;
  my $client = $self->client;
  for my $attempt (1..$retries) {
    local $@; eval {
      my $sth = $client->prepare(
        qq{
          update "$table" set "meta" = ? where "id" = (
            select "me"."id" from "$table" "me"
            where "me"."key" = ? and "me"."meta" is null
            order by "me"."index" desc limit 1
          )
        }
      );
      $sth->execute($self->meta, $key);
    };
    if ($@) {
      die $@ if $attempt == $retries;
    }
    else {
      last;
    }
  }
  my $data = $client->selectrow_arrayref(
    qq{
      select "id", "value"
      from "$table" where "meta" = ? and "key" = ? order by "index" desc limit 1
    },
    {},
    $self->meta, $key,
  );
  if ($data) {
    my $sth = $client->prepare(
      qq{delete from "$table" where "id" = ?}
    );
    $sth->execute($data->[0]);
  }
  return $data ? $self->decode($data->[1]) : undef;
}

method rpush(Str $key, HashRef $val) {
  my $table = $self->table;
  my $client = $self->client;
  my $sth = $client->prepare(
    qq{
      insert into "$table" ("key", "value", "index") values (?, ?, (
        select coalesce(max("me"."index"), 0) + 1
        from "$table" "me" where "me"."key" = ?
      ))
    }
  );
  for my $attempt (1..$retries) {
    local $@; eval {
      $sth->execute($key, $self->encode($val), $key);
    };
    if ($@) {
      die $@ if $attempt == $retries;
    }
    else {
      last;
    }
  }
  return $sth->rows;
}

method send(Str $key, HashRef $val) {
  my $set = $self->encode($val);
  $self->write($key, $set);
  return 'OK';
}

method size(Str $key) {
  my $table = $self->table;
  my $client = $self->client;
  my $data = $client->selectrow_arrayref(
    qq{select count("key") from "$table" where "key" = ?},
    {},
    $key,
  );
  return $data->[0];
}

method slot(Str $key, Int $pos) {
  my $table = $self->table;
  my $client = $self->client;
  my $data = $client->selectrow_arrayref(
    qq{
      select "value" from "$table"
      where "key" = ? order by "index" asc offset ? limit 1
    },
    {},
    $key, $pos
  );
  return $data ? $self->decode($data->[0]) : undef;
}

method test(Str $key) {
  my $table = $self->table;
  my $client = $self->client;
  my $data = $client->selectrow_arrayref(
    qq{select count("id") from "$table" where "key" = ?},
    {},
    $key,
  );
  return $data->[0] ? 1 : 0;
}

method write(Str $key, Str $data) {
  my $table = $self->table;
  my $client = $self->client;
  $client->prepare(
    qq{delete from "$table" where "key" = ?}
  )->execute($key);
  $client->prepare(
    qq{insert into "$table" ("key", "value") values (?, ?)}
  )->execute($key, $data);
  return $self;
}

1;

=encoding utf8

=head1 NAME

Zing::Store::Pg - Postgres Storage

=cut

=head1 ABSTRACT

Postgres Storage Abstraction

=cut

=head1 SYNOPSIS

  use Test::DB::Postgres;
  use Zing::Encoder::Dump;
  use Zing::Store::Pg;

  my $testdb = Test::DB::Postgres->new;
  my $store = Zing::Store::Pg->new(
    client => $testdb->create->dbh,
    encoder => Zing::Encoder::Dump->new
  );

  # $store->drop;

=cut

=head1 DESCRIPTION

This package provides a Postgres-specific storage adapter for use with data
persistence abstractions. The L</client> attribute accepts a L<DBI> object
configured to connect to a L<DBD::Pg> backend. The C<ZING_DBNAME> environment
variable can be used to specify the database name (defaults to "zing"). The
C<ZING_DBHOST> environment variable can be used to specify the database host
(defaults to "localhost"). The C<ZING_DBPORT> environment variable can be used
to specify the database port (defaults to "5432"). The C<ZING_DBUSER>
environment variable can be used to specify the database username (defaults to
"postgres"). The C<ZING_DBPASS> environment variable can be used to specify the
database password. The C<ZING_DBZONE> environment variable can be used to
specify the database table name (defaults to "entities").

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Zing::Store>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 client

  client(InstanceOf["DBI::db"])

This attribute is read-only, accepts C<(InstanceOf["DBI::db"])> values, and is optional.

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

  $store->decode('{"status"=>"ok"}');

=back

=cut

=head2 drop

  drop(Str $key) : Int

The drop method removes (drops) the item from the datastore.

=over 4

=item drop example #1

  # given: synopsis

  $store->drop('zing:main:global:model:temp');

=back

=cut

=head2 encode

  encode(HashRef $data) : Str

The encode method encodes and returns the data provided as JSON.

=over 4

=item encode example #1

  # given: synopsis

  $store->encode({ status => 'ok' });

=back

=cut

=head2 keys

  keys(Str @keys) : ArrayRef[Str]

The keys method returns a list of keys under the namespace of the datastore or
provided key.

=over 4

=item keys example #1

  # given: synopsis

  my $keys = $store->keys('zing:main:global:model:temp');

=back

=over 4

=item keys example #2

  # given: synopsis

  $store->send('zing:main:global:model:temp', { status => 'ok' });

  my $keys = $store->keys('zing:main:global:model:temp');

=back

=cut

=head2 lpull

  lpull(Str $key) : Maybe[HashRef]

The lpull method pops data off of the top of a list in the datastore.

=over 4

=item lpull example #1

  # given: synopsis

  $store->lpull('zing:main:global:model:items');

=back

=over 4

=item lpull example #2

  # given: synopsis

  $store->rpush('zing:main:global:model:items', { status => 'ok' });

  $store->lpull('zing:main:global:model:items');

=back

=cut

=head2 lpush

  lpush(Str $key, HashRef $val) : Int

The lpush method pushed data onto the top of a list in the datastore.

=over 4

=item lpush example #1

  # given: synopsis

  $store->lpush('zing:main:global:model:items', { status => '1' });

=back

=over 4

=item lpush example #2

  # given: synopsis

  $store->lpush('zing:main:global:model:items', { status => '0' });

  $store->lpush('zing:main:global:model:items', { status => '0' });

=back

=cut

=head2 recv

  recv(Str $key) : Maybe[HashRef]

The recv method fetches and returns data from the datastore by its key.

=over 4

=item recv example #1

  # given: synopsis

  $store->recv('zing:main:global:model:temp');

=back

=over 4

=item recv example #2

  # given: synopsis

  $store->send('zing:main:global:model:temp', { status => 'ok' });

  $store->recv('zing:main:global:model:temp');

=back

=cut

=head2 rpull

  rpull(Str $key) : Maybe[HashRef]

The rpull method pops data off of the bottom of a list in the datastore.

=over 4

=item rpull example #1

  # given: synopsis

  $store->rpull('zing:main:global:model:items');

=back

=over 4

=item rpull example #2

  # given: synopsis

  $store->rpush('zing:main:global:model:items', { status => 1 });
  $store->rpush('zing:main:global:model:items', { status => 2 });

  $store->rpull('zing:main:global:model:items');

=back

=cut

=head2 rpush

  rpush(Str $key, HashRef $val) : Int

The rpush method pushed data onto the bottom of a list in the datastore.

=over 4

=item rpush example #1

  # given: synopsis

  $store->rpush('zing:main:global:model:items', { status => 'ok' });

=back

=over 4

=item rpush example #2

  # given: synopsis

  $store->rpush('zing:main:global:model:items', { status => 'ok' });

  $store->rpush('zing:main:global:model:items', { status => 'ok' });

=back

=cut

=head2 send

  send(Str $key, HashRef $val) : Str

The send method commits data to the datastore with its key and returns truthy.

=over 4

=item send example #1

  # given: synopsis

  $store->send('zing:main:global:model:temp', { status => 'ok' });

=back

=cut

=head2 size

  size(Str $key) : Int

The size method returns the size of a list in the datastore.

=over 4

=item size example #1

  # given: synopsis

  my $size = $store->size('zing:main:global:model:items');

=back

=over 4

=item size example #2

  # given: synopsis

  $store->rpush('zing:main:global:model:items', { status => 'ok' });

  my $size = $store->size('zing:main:global:model:items');

=back

=cut

=head2 slot

  slot(Str $key, Int $pos) : Maybe[HashRef]

The slot method returns the data from a list in the datastore by its index.

=over 4

=item slot example #1

  # given: synopsis

  my $model = $store->slot('zing:main:global:model:items', 0);

=back

=over 4

=item slot example #2

  # given: synopsis

  $store->rpush('zing:main:global:model:items', { status => 'ok' });

  my $model = $store->slot('zing:main:global:model:items', 0);

=back

=cut

=head2 test

  test(Str $key) : Int

The test method returns truthy if the specific key (or datastore) exists.

=over 4

=item test example #1

  # given: synopsis

  $store->rpush('zing:main:global:model:items', { status => 'ok' });

  $store->test('zing:main:global:model:items');

=back

=over 4

=item test example #2

  # given: synopsis

  $store->drop('zing:main:global:model:items');

  $store->test('zing:main:global:model:items');

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/zing-store-pg/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/zing-store-pg/wiki>

L<Project|https://github.com/iamalnewkirk/zing-store-pg>

L<Initiatives|https://github.com/iamalnewkirk/zing-store-pg/projects>

L<Milestones|https://github.com/iamalnewkirk/zing-store-pg/milestones>

L<Contributing|https://github.com/iamalnewkirk/zing-store-pg/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/zing-store-pg/issues>

=cut