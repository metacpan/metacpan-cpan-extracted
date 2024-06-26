package Venus::Data;

use 5.018;

use strict;
use warnings;

use Venus::Class 'attr', 'base';

base 'Venus::Path';

# ATTRIBUTES

attr 'from';
attr 'stag';
attr 'etag';

# BUILDERS

sub build_self {
  my ($self, $data) = @_;

  return $self->docs;
};

# METHODS

sub assertion {
  my ($self) = @_;

  my $assertion = $self->SUPER::assertion;

  $assertion->match('string')->format(sub{
    (ref $self || $self)->new($_)
  });

  return $assertion;
}

sub count {
  my ($self, $data) = @_;

  my @result = ($self->search($data));

  return scalar @result;
}

sub data {
  my ($self) = @_;

  my $data = $self->read;

  $data = (split(/^__END__/m, (split(/^__DATA__/m, $data))[1] || ''))[0] || '';

  $data =~ s/^\s+|\s+$//g;

  return $data;
}

sub docs {
  my ($self) = @_;

  $self->stag('=');
  $self->etag('=cut');
  $self->from('read');

  return $self;
}

sub explode {
  my ($self) = @_;

  my $from = $self->from;
  my $data = $self->$from;
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

sub text {
  my ($self) = @_;

  $self->stag('@@ ');
  $self->etag('@@ end');
  $self->from('data');

  return $self;
}

1;



=head1 NAME

Venus::Data - Data Class

=cut

=head1 ABSTRACT

Data Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Data;

  my $data = Venus::Data->new('t/data/sections');

  # $data->find(undef, 'name');

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

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Path>

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

  my $count = $data->docs->count;

  # 6

=back

=over 4

=item count example 2

  # given: synopsis;

  my $count = $data->text->count;

  # 3

=back

=cut

=head2 data

  data() (string)

The data method returns the text between the C<DATA> and C<END> sections of a
Perl package or file.

I<Since C<0.01>>

=over 4

=item data example 1

  # given: synopsis;

  $data = $data->data;

  # ...

=back

=cut

=head2 docs

  docs() (Venus::Data)

The docs method configures the instance for parsing POD blocks.

I<Since C<0.01>>

=over 4

=item docs example 1

  # given: synopsis;

  my $docs = $data->docs;

  # bless({ etag => "=cut", from => "read", stag => "=", ... }, "Venus::Data")

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

  my $find = $data->docs->find(undef, 'name');

  # [
  #   { data => ["Example #1"], index => 4, list => undef, name => "name" },
  #   { data => ["Example #2"], index => 5, list => undef, name => "name" },
  # ]

=back

=over 4

=item find example 2

  # given: synopsis;

  my $find = $data->docs->find('head1', 'NAME');

  # [
  #   { data => ["Example #1"], index => 1, list => "head1", name => "NAME" },
  #   { data => ["Example #2"], index => 2, list => "head1", name => "NAME" },
  # ]

=back

=over 4

=item find example 3

  # given: synopsis;

  my $find = $data->text->find(undef, 'name');

  # [
  #   { data => ["Example Name"], index => 1, list => undef, name => "name" },
  # ]

=back

=over 4

=item find example 4

  # given: synopsis;

  my $find = $data->text->find('titles', '#1');

  # [
  #   { data => ["Example Title #1"], index => 2, list => "titles", name => "#1" },
  # ]

=back

=cut

=head2 search

The search method returns the set of blocks matching the criteria provided.
This method can return a list of values in list-context.

=over 4

=item search example 1

  # given: synopsis;

  my $search = $data->docs->search({list => undef, name => 'name'});

  # [
  #   { data => ["Example #1"], index => 4, list => undef, name => "name" },
  #   { data => ["Example #2"], index => 5, list => undef, name => "name" },
  # ]

=back

=over 4

=item search example 2

  # given: synopsis;

  my $search = $data->docs->search({list => 'head1', name => 'NAME'});

  # [
  #   { data => ["Example #1"], index => 1, list => "head1", name => "NAME" },
  #   { data => ["Example #2"], index => 2, list => "head1", name => "NAME" },
  # ]

=back

=over 4

=item search example 3

  # given: synopsis;

  my $find = $data->text->search({list => undef, name => 'name'});

  # [
  #   { data => ["Example Name"], index => 1, list => undef, name => "name" },
  # ]

=back

=over 4

=item search example 4

  # given: synopsis;

  my $search = $data->text->search({list => 'titles', name => '#1'});

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

  my $string = $data->docs->string(undef, 'name');

  # "Example #1\nExample #2"

=back

=over 4

=item string example 2

  # given: synopsis;

  my $string = $data->docs->string('head1', 'NAME');

  # "Example #1\nExample #2"

=back

=over 4

=item string example 3

  # given: synopsis;

  my $string = $data->text->string(undef, 'name');

  # "Example Name"

=back

=over 4

=item string example 4

  # given: synopsis;

  my $string = $data->text->string('titles', '#1');

  # "Example Title #1"

=back

=over 4

=item string example 5

  # given: synopsis;

  my @string = $data->docs->string('head1', 'NAME');

  # ("Example #1", "Example #2")

=back

=cut

=head2 text

  text() (Venus::Data)

The text method configures the instance for parsing DATA blocks.

I<Since C<0.01>>

=over 4

=item text example 1

  # given: synopsis;

  my $text = $data->text;

  # bless({ etag  => '@@ end', from  => 'data', stag  => '@@ ', ... }, "Venus::Data")

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