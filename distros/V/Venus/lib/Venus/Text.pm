package Venus::Text;

use 5.018;

use strict;
use warnings;

# Venus

use Venus::Class 'attr', 'base', 'with';

# IMPORTS

use Venus::Path;

# INHERITS

base 'Venus::Kind::Utility';

# INTEGRATES

with 'Venus::Role::Buildable';

# ATTRIBUTES

attr 'file';
attr 'stag';
attr 'etag';

# BUILDERS

sub build_arg {
  my ($self, $data) = @_;

  return {
    file => $data,
  };
}

# METHODS

sub count {
  my ($self, $data) = @_;

  my @result = ($self->search($data));

  return scalar @result;
}

sub data {
  my ($self) = @_;

  my $file = $self->file;

  my $data = Venus::Path->new($file)->read;

  return $data;
}

sub explode {
  my ($self) = @_;

  my $data = $self->data;
  my $stag = $self->stag;
  my $etag = $self->etag;

  my @chunks = split /^(?:\@$stag|$stag)\s*(.+?)\s*\r?\n/m, ($data . "\n");

  shift @chunks;

  my $items = [];

  while (my ($meta, $data) = splice @chunks, 0, 2) {
    next unless $meta && $data;
    next unless $meta ne $etag;

    my @info = split /\s/, $meta, 2;
    my ($list, $name) = @info == 2 ? @info : (undef, @info);

    $data =~ s/(\r?\n)\+$stag/$1$stag/g; # auto-escape nested syntax
    $data = [split /\r?\n\r?\n/, $data];

    my $item = {name => $name, data => $data, index => @$items + 1, list => $list};

    push @$items, $item;
  }

  return $items;
}

sub find {
  my ($self, $list, $name) = @_;

  return $self->search({list => $list, name => $name});
}

sub search {
  my ($self, $data) = @_;

  $data //= {};

  my $exploded = $self->explode;

  return wantarray ? (@$exploded) : $exploded if !keys %$data;

  my @result;

  my $sought = {map +($_, 1), keys %$data};

  for my $item (sort {$a->{index} <=> $b->{index}} @$exploded) {
    my $found = {};

    my $text;
    if ($text = $data->{data}) {
      $text = ref($text) eq 'Regexp' ? $text : qr/^@{[quotemeta($text)]}$/;
      $found->{data} = 1 if "@{$item->{data}}" =~ $text;
    }

    my $index;
    if ($index = $data->{index}) {
      $index = ref($index) eq 'Regexp' ? $index : qr/^@{[quotemeta($index)]}$/;
      $found->{index} = 1 if $item->{index} =~ $index;
    }

    my $list;
    if ($list = $data->{list}) {
      $list = (ref($list) eq 'Regexp' ? $list : qr/^@{[quotemeta($list)]}$/);
      $found->{list} = 1 if defined $item->{list} && $item->{list} =~ $list;
    }
    else {
      $found->{list} = 1 if (exists $data->{list} && !defined $data->{list})
        && !defined $item->{list};
    }

    my $name;
    if ($name = $data->{name}) {
      $name = ref($name) eq 'Regexp' ? $name : qr/^@{[quotemeta($name)]}$/;
      $found->{name} = 1 if $item->{name} =~ $name;
    }

    if (not(grep(not(defined($found->{$_})), keys(%$sought)))) {
      push @result, $item;
    }
  }

  return wantarray ? (@result) : \@result;
}

sub string {
  my ($self, $list, $name) = @_;

  my @result;

  for my $item ($self->find($list, $name)) {
    push @result, join "\n\n", @{$item->{data}};
  }

  return wantarray ? (@result) : join "\n", @result;
}

1;



=head1 NAME

Venus::Text - Text Class

=cut

=head1 ABSTRACT

Text Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Text;

  my $text = Venus::Text->new('t/data/sections');

  # $text->find(undef, 'name');

=cut

=head1 DESCRIPTION

This package provides methods for extracting C<DATA> sections and POD blocks
from any file or package. The package can be configured to parse either POD or
DATA blocks, and it defaults to being configured for POD blocks.

=head2 DATA syntax

  __DATA__

  # data syntax

  @@ name

  Example Name

  @@ end

  @@ titles #1

  Example Title #1

  @@ end

  @@ titles #2

  Example Title #2

  @@ end

=head2 DATA syntax (nested)

  __DATA__

  # data syntax (nested)

  @@ nested

  Example Nested

  +@@ demo

  blah blah blah

  +@@ end

  @@ end

=head2 POD syntax

  # pod syntax

  =head1 NAME

  Example #1

  =cut

  =head1 NAME

  Example #2

  =cut

  # pod-ish syntax

  =name

  Example #1

  =cut

  =name

  Example #2

  =cut

=head2 POD syntax (nested)

  # pod syntax (nested)

  =nested

  Example #1

  +=head1 WHY?

  blah blah blah

  +=cut

  More information on the same topic as was previously mentioned in the
  previous section demonstrating the topic, obviously from said section.

  =cut

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 count

  count(hashref $criteria) (number)

The count method uses the criteria provided to L</search> for and return the
number of blocks found.

I<Since C<0.01>>

=over 4

=item count example 1

  # given: synopsis;

  $text->stag('=');

  $text->etag('=cut');

  my $count = $text->count;

  # 7

=back

=over 4

=item count example 2

  # given: synopsis;

  $text->stag('@@ ');

  $text->etag('@@ end');

  my $count = $text->count;

  # 3

=back

=cut

=head2 data

  data() (string)

The data method returns the contents of the L</file> to be parsed.

I<Since C<0.01>>

=over 4

=item data example 1

  # given: synopsis;

  $text = $text->data;

  # ...

=back

=cut

=head2 find

  find(maybe[string] $list, maybe[string] $name) (arrayref)

The find method is a wrapper around L</search> as shorthand for searching by
C<list> and C<name>.

I<Since C<0.01>>

=over 4

=item find example 1

  # given: synopsis;

  $text->stag('=');

  $text->etag('=cut');

  my $find = $text->find(undef, 'name');

  # [
  #   { data => ["Example #1"], index => 4, list => undef, name => "name" },
  #   { data => ["Example #2"], index => 5, list => undef, name => "name" },
  # ]

=back

=over 4

=item find example 2

  # given: synopsis;

  $text->stag('=');

  $text->etag('=cut');

  my $find = $text->find('head1', 'NAME');

  # [
  #   { data => ["Example #1"], index => 1, list => "head1", name => "NAME" },
  #   { data => ["Example #2"], index => 2, list => "head1", name => "NAME" },
  # ]

=back

=over 4

=item find example 3

  # given: synopsis;

  $text->stag('@@ ');

  $text->etag('@@ end');

  my $find = $text->find(undef, 'name');

  # [
  #   { data => ["Example Name"], index => 1, list => undef, name => "name" },
  # ]

=back

=over 4

=item find example 4

  # given: synopsis;

  $text->stag('@@ ');

  $text->etag('@@ end');

  my $find = $text->find('titles', '#1');

  # [
  #   { data => ["Example Title #1"], index => 2, list => "titles", name => "#1" },
  # ]

=back

=cut

=head2 new

  new(any @args) (Venus::Text)

The new method constructs an instance of the package.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Text;

  my $new = Venus::Text->new;

  # bless(..., "Venus::Text")

=back

=over 4

=item new example 2

  package main;

  use Venus::Text;

  my $new = Venus::Text->new('t/data/sections');

  # bless(..., "Venus::Text")

=back

=over 4

=item new example 3

  package main;

  use Venus::Text;

  my $new = Venus::Text->new(file => 't/data/sections');

  # bless(..., "Venus::Text")

=back

=cut

=head2 search

  find(hashref $criteria) (arrayref)

The search method returns the set of blocks matching the criteria provided.
This method can return a list of values in list-context.

I<Since C<0.01>>

=over 4

=item search example 1

  # given: synopsis;

  $text->stag('=');

  $text->etag('=cut');

  my $search = $text->search({list => undef, name => 'name'});

  # [
  #   { data => ["Example #1"], index => 4, list => undef, name => "name" },
  #   { data => ["Example #2"], index => 5, list => undef, name => "name" },
  # ]

=back

=over 4

=item search example 2

  # given: synopsis;

  $text->stag('=');

  $text->etag('=cut');

  my $search = $text->search({list => 'head1', name => 'NAME'});

  # [
  #   { data => ["Example #1"], index => 1, list => "head1", name => "NAME" },
  #   { data => ["Example #2"], index => 2, list => "head1", name => "NAME" },
  # ]

=back

=over 4

=item search example 3

  # given: synopsis;

  $text->stag('@@ ');

  $text->etag('@@ end');

  my $find = $text->search({list => undef, name => 'name'});

  # [
  #   { data => ["Example Name"], index => 1, list => undef, name => "name" },
  # ]

=back

=over 4

=item search example 4

  # given: synopsis;

  $text->stag('@@ ');

  $text->etag('@@ end');

  my $search = $text->search({list => 'titles', name => '#1'});

  # [
  #   { data => ["Example Title #1"], index => 2, list => "titles", name => "#1" },
  # ]

=back

=cut

=head2 string

  string(maybe[string] $list, maybe[string] $name) (string)

The string method is a wrapper around L</find> as shorthand for searching by
C<list> and C<name>, returning only the strings found.

I<Since C<1.67>>

=over 4

=item string example 1

  # given: synopsis;

  $text->stag('=');

  $text->etag('=cut');

  my $string = $text->string(undef, 'name');

  # "Example #1\nExample #2"

=back

=over 4

=item string example 2

  # given: synopsis;

  $text->stag('=');

  $text->etag('=cut');

  my $string = $text->string('head1', 'NAME');

  # "Example #1\nExample #2"

=back

=over 4

=item string example 3

  # given: synopsis;

  $text->stag('@@ ');

  $text->etag('@@ end');

  my $string = $text->string(undef, 'name');

  # "Example Name"

=back

=over 4

=item string example 4

  # given: synopsis;

  $text->stag('@@ ');

  $text->etag('@@ end');

  my $string = $text->string('titles', '#1');

  # "Example Title #1"

=back

=over 4

=item string example 5

  # given: synopsis;

  $text->stag('=');

  $text->etag('=cut');

  my @string = $text->string('head1', 'NAME');

  # ("Example #1", "Example #2")

=back

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2022, Awncorp, C<awncorp@cpan.org>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut