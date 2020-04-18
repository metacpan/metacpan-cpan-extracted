package WARC::Collection;					# -*- CPerl -*-

use strict;
use warnings;

our @ISA = qw();

require WARC; *WARC::Collection::VERSION = \$WARC::VERSION;

use Carp;

require WARC::Index;
require WARC::Index::Entries;

=head1 NAME

WARC::Collection - Interface to a group of WARC files

=head1 SYNOPSIS

  use WARC::Collection;

  $collection = assemble WARC::Collection ($index_1, $index_2, ...);
  $collection = assemble WARC::Collection from => ($index_1, ...);

  $yes_or_no = $collection->searchable( $key );

  $record = $collection->search(url => $url, time => $when);
  @records = $collection->search(url => $url, time => $when);

=cut

# This implementation uses a hash as the underlying structure.
#  Keys defined by this class:
#
#   indexes
#	Array of indexes used for this collection.

=head1 DESCRIPTION

The C<WARC::Collection> class is the primary means by which user code is
expected to use the WARC library.  This class uses indexes to efficiently
search for records in one or more WARC files.

=head2 Search Keys

The C<search> method accepts a list of parameters as I<key> =E<gt> I<value>
pairs with each pair narrowing the search, sorting the results, or both,
indicated in the following list with S<"C<[N ]>">, S<"C<[ S]>">, or "C<[NS]>",
respectively.

Supplying an array reference as a I<value> indicates a search where any of
the values in the array are acceptable.  This does not affect sorting.

The same search keys documented here are used for searching indexes, since
C<WARC::Collection> is a wrapper around one or more indexes, but index
support modules do not sort their results.  Only C<WARC::Collection> sorts
the returned entries, so keys listed below as "sort-only" are ignored by
the index support modules.

The keys supported are:

=over

=item C<[N ]> url

An exact match for a URL.

=item C<[NS]> url_prefix

A prefix match for a URL.  Prefers records with shorter URLs.

=item C<[ S]> time

Prefer records collected nearer to the requested time.

=item C<[N ]> record_id

An exact match for a (presumably unique) WARC-Record-ID.

=item C<[N ]> segment_origin_id

Exact match for continuation records for a WARC-Record-ID that identifies a
logical record stored using WARC record segmentation.  Searching on this
key returns only the continuation records.

=back

=for comment
Matching these keys is implemented in WARC::Index::Entry::_distance_for_item
via %_distance_value_map and in various index support modules.

=head2 Methods

=over

=item $collection = assemble WARC::Collection ($index_1, $index_2, ...);

=item $collection = assemble WARC::Collection from =E<gt> ($index_1, ...);

Assemble a collection of WARC files from one index or multiple indexes,
specified either as objects derived from C<WARC::Index> or filenames.

While multiple indexes can be used in a collection, note that searching a
collection requires individually searching every index in the collection.

=cut

sub assemble {
  my $class = shift;
  shift if scalar @_ and $_[0] eq 'from';	# discard optional noise word

  carp "assembling empty collection" unless scalar @_;

  my @indexes = ();

  while (@_) {
    my $index = shift;

    if (UNIVERSAL::isa($index, 'WARC::Index'))
      { push @indexes, $index }	# add index object to list
    else {			# or assume filename and find an index handler
      my $isys = WARC::Index::find_handler($index);
      croak "no known handler for index '$index'" unless $isys;
      push @indexes, (attach $isys $index);
    }
  }

  bless { indexes => \@indexes }, $class
}

=item $yes_or_no = $collection-E<gt>searchable( $key )

Return true or false to reflect if any index in the collection can search
for the requested key.

=cut

sub searchable {
  my $self = shift;
  my $key = shift;

  foreach my $index (@{$self->{indexes}})
    { return 1 if $index->searchable($key) }

  # none of the indexes recognize $key
  return 0;
}

=item $record = $collection-E<gt>search( ... )

=item @records = $collection-E<gt>search( ... )

Search the indexes for records matching the parameters and return the best
match in scalar context or a list of all matches in list context.  The
returned values are C<WARC::Record> objects.

See L</"Search Keys"> for more information about the parameters.

=cut

sub search {
  my $self = shift;

  unless (defined wantarray)
    { carp "calling 'search' method in void context"; return }

  croak "no arguments given to 'search' method"
    unless scalar @_;
  croak "odd number of arguments given to 'search' method"
    if scalar @_ % 2;

  # collect all matches from all indexes
  my %results = ();	# map:  tag => array of index entries for record
  if (grep UNIVERSAL::isa($_, 'ARRAY'), @_) {
    # at least one parameter is an arrayref; perform nested loop join
    my @step = @_; my @state = (); my @varpos = ();
    for (my $i = 1; $i <= $#step; $i += 2) {
      next unless UNIVERSAL::isa($step[$i], 'ARRAY');
      push @state, 0;
      push @varpos, $i;
      $step[$i] = $step[$i]->[0];
    }
    # search indexes with all combinations from the input
    while ($state[0] <= $#{$_[$varpos[0]]}) {
      foreach my $index (@{$self->{indexes}})
	{ foreach my $entry ($index->search(@step))
	    { push @{$results{$entry->tag}}, $entry } }
    } continue {
      # count in variable base in @state using the input arrayrefs
      my $i = $#state;
      $i-- while $i > 0 && $state[$i] >= $#{$_[$varpos[$i]]};
      $step[$varpos[$i]] = $_[$varpos[$i]]->[++$state[$i]];
      $step[$varpos[$i]] = $_[$varpos[$i]]->[$state[$i] = 0]
	while ++$i <= $#state;
    }
  } else {
    # simple case with single values; only one scan needed
    foreach my $index (@{$self->{indexes}})
      { foreach my $entry ($index->search(@_))
	  { push @{$results{$entry->tag}}, $entry } }
  }

  # coalesce and sort the collected index entries
  my @results =
    map {coalesce WARC::Index::Entries ($results{$_})} keys %results;
  @results =	# sort by distance using Schwartzian transform
    (map { $_->[0] } sort { $a->[1] <=> $b->[1] }
     map { [$_, scalar $_->distance(@_)] } @results);

  # return either the entire sorted list or the best match
  if (wantarray) { return map {$_->record(collection => $self)} @results }
  else		 { return (scalar @results
			   ? $results[0]->record(collection => $self) : undef) }
}

=back

=cut

1;
__END__

=head1 AUTHOR

Jacob Bachmeyer, E<lt>jcb@cpan.orgE<gt>

=head1 SEE ALSO

L<WARC>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
