package Venus::Text::Pod;

use 5.018;

use strict;
use warnings;

# VENUS

use Venus::Class 'base';

# IMPORTS

use Venus::Path;

# INHERITS

base 'Venus::Text';

# METHODS

sub data {
  my ($self) = @_;

  my $file = $self->file;

  my $data = Venus::Path->new($file)->read;

  return $data;
}

sub stag {

  return '=';
}

sub etag {

  return '=cut';
}

1;



=head1 NAME

Venus::Text::Pod - Text (Pod) Class

=cut

=head1 ABSTRACT

Text (Pod) Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Text::Pod;

  my $text = Venus::Text::Pod->new('t/data/sections');

  # $text->find(undef, 'name');

=cut

=head1 DESCRIPTION

This package provides methods for extracting POD blocks from any file or
package.

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

I<Since C<4.15>>

=over 4

=item count example 1

  # given: synopsis;

  my $count = $text->count;

  # 7

=back

=cut

=head2 data

  data() (string)

The data method returns the contents of the L</file> to be parsed.

I<Since C<4.15>>

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

I<Since C<4.15>>

=over 4

=item find example 1

  # given: synopsis;

  my $find = $text->find(undef, 'name');

  # [
  #   { data => ["Example #1"], index => 4, list => undef, name => "name" },
  #   { data => ["Example #2"], index => 5, list => undef, name => "name" },
  # ]

=back

=over 4

=item find example 2

  # given: synopsis;

  my $find = $text->find('head1', 'NAME');

  # [
  #   { data => ["Example #1"], index => 1, list => "head1", name => "NAME" },
  #   { data => ["Example #2"], index => 2, list => "head1", name => "NAME" },
  # ]

=back

=cut

=head2 new

  new(any @args) (Venus::Text::Pod)

The new method constructs an instance of the package.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Text::Pod;

  my $new = Venus::Text::Pod->new;

  # bless(..., "Venus::Text::Pod")

=back

=over 4

=item new example 2

  package main;

  use Venus::Text::Pod;

  my $new = Venus::Text::Pod->new('t/data/sections');

  # bless(..., "Venus::Text::Pod")

=back

=over 4

=item new example 3

  package main;

  use Venus::Text::Pod;

  my $new = Venus::Text::Pod->new(file => 't/data/sections');

  # bless(..., "Venus::Text::Pod")

=back

=cut

=head2 search

  find(hashref $criteria) (arrayref)

The search method returns the set of blocks matching the criteria provided.
This method can return a list of values in list-context.

I<Since C<4.15>>

=over 4

=item search example 1

  # given: synopsis;

  my $search = $text->search({list => undef, name => 'name'});

  # [
  #   { data => ["Example #1"], index => 4, list => undef, name => "name" },
  #   { data => ["Example #2"], index => 5, list => undef, name => "name" },
  # ]

=back

=over 4

=item search example 2

  # given: synopsis;

  my $search = $text->search({list => 'head1', name => 'NAME'});

  # [
  #   { data => ["Example #1"], index => 1, list => "head1", name => "NAME" },
  #   { data => ["Example #2"], index => 2, list => "head1", name => "NAME" },
  # ]

=back

=cut

=head2 string

  string(maybe[string] $list, maybe[string] $name) (string)

The string method is a wrapper around L</find> as shorthand for searching by
C<list> and C<name>, returning only the strings found.

I<Since C<4.15>>

=over 4

=item string example 1

  # given: synopsis;

  my $string = $text->string(undef, 'name');

  # "Example #1\nExample #2"

=back

=over 4

=item string example 2

  # given: synopsis;

  my $string = $text->string('head1', 'NAME');

  # "Example #1\nExample #2"

=back

=over 4

=item string example 3

  # given: synopsis;

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