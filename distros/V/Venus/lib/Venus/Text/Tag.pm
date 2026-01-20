package Venus::Text::Tag;

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

  $data = (split(/^__END__/m, (split(/^__DATA__/m, $data))[1] || ''))[0] || '';

  $data =~ s/^\s+|\s+$//g;

  return $data;
}

sub stag {

  return '@@ ';
}

sub etag {

  return '@@ end';
}

1;



=head1 NAME

Venus::Text::Tag - Text (Tag) Class

=cut

=head1 ABSTRACT

Text (Tag) Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Text::Tag;

  my $text = Venus::Text::Tag->new('t/data/sections');

  # $text->find(undef, 'name');

=cut

=head1 DESCRIPTION

This package provides methods for extracting C<DATA> sections and tag blocks
from the C<DATA> and C<END> sections of any file or package.

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

  # 3

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
  #   { data => ["Example Name"], index => 1, list => undef, name => "name" },
  # ]

=back

=over 4

=item find example 2

  # given: synopsis;

  my $find = $text->find('titles', '#1');

  # [
  #   { data => ["Example Title #1"], index => 2, list => "titles", name => "#1" },
  # ]

=back

=cut

=head2 new

  new(any @args) (Venus::Text::Tag)

The new method constructs an instance of the package.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Text::Tag;

  my $new = Venus::Text::Tag->new;

  # bless(..., "Venus::Text::Tag")

=back

=over 4

=item new example 2

  package main;

  use Venus::Text::Tag;

  my $new = Venus::Text::Tag->new('t/data/sections');

  # bless(..., "Venus::Text::Tag")

=back

=over 4

=item new example 3

  package main;

  use Venus::Text::Tag;

  my $new = Venus::Text::Tag->new(file => 't/data/sections');

  # bless(..., "Venus::Text::Tag")

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

  my $find = $text->search({list => undef, name => 'name'});

  # [
  #   { data => ["Example Name"], index => 1, list => undef, name => "name" },
  # ]

=back

=over 4

=item search example 2

  # given: synopsis;

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

I<Since C<4.15>>

=over 4

=item string example 1

  # given: synopsis;

  my $string = $text->string(undef, 'name');

  # "Example Name"

=back

=over 4

=item string example 2

  # given: synopsis;

  my $string = $text->string('titles', '#1');

  # "Example Title #1"

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