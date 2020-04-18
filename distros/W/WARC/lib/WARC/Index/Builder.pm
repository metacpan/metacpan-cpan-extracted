package WARC::Index::Builder;					# -*- CPerl -*-

use strict;
use warnings;

our @ISA = qw();

require WARC; *WARC::Index::Builder::VERSION = \$WARC::VERSION;

use Carp;

=head1 NAME

WARC::Index::Builder - abstract base class for building indexes

=head1 SYNOPSIS

  use WARC::Index;

  $cdx_builder = build WARC::Index::File::CDX (...);
  $sdbm_builder = build WARC::Index::File::SDBM (...);

  $cdx_entry = $cdx_builder->add($record);
  $sdbm_builder->add($cdx_entry);

=head1 DESCRIPTION

C<WARC::Index::Builder> is an abstract base class for constructing indexes
on WARC files.  The interface is documented here, but implemented in
specialized classes for each index type.  Some common code has also been
moved to this class, and is also documented here.

=head2 Methods

=over

=item $builder-E<gt>add( ... )

Add items to the growing index.  All index types accept both WARC records
and entries from other indexes, although only metaindex-capable formats use
the latter.  Any number of items may be added with a single call.

Returns nothing.

The C<WARC::Index::Builder> base class provides an implementation of this
method that dispatches to the internal _add_* methods listed below.

=cut

sub add {
  my $self = shift;

  foreach (@_) {
    if (not ref)
      # treat a loose scalar as a WARC volume file name
      {  $self->_add_volume(mount WARC::Volume ($_)) }
    else {
      if   ($_->isa('WARC::Volume'))		{ $self->_add_volume($_) }
      elsif($_->isa('WARC::Index'))		{ $self->_add_index($_)  }
      elsif($_->isa('WARC::Index::Entry'))	{ $self->_add_entry($_)  }
      elsif($_->isa('WARC::Record::FromVolume')){ $self->_add_record($_) }
      else { croak "unrecognized object $_" }
    }
  }
}

=item $builder-E<gt>flush

Write any buffered data to the underlying storage.  After calling this
method, all records added using this builder should be visible.  Some index
systems do this implicitly; this method is a no-op in those cases.

Returns nothing.

=cut

sub flush {}

=back

=head2 Internal Methods

=over

=item $builder-E<gt>_add_record( $record )

Add one L<WARC::Record> to the index.

=cut

=item $builder-E<gt>_add_entry( $entry )

Add one L<WARC::Index::Entry> to the index.

The C<WARC::Index::Builder> base class provides a default implementation
that adds the corresponding record instead.

=cut

sub _add_entry {
  my $self = shift;
  my $source = shift;

  $self->_add_record($source->record);
}

=item $builder-E<gt>_add_index( $index )

Add all entries from an enumerable index to the index.

The C<WARC::Index::Builder> base class provides a default implementation.

=cut

sub _add_index {
  my $self = shift;
  my $source = shift;

  for (my $entry = $source->first_entry; $entry; $entry = $entry->next)
    { $self->_add_entry($entry) }
}

=item $builder-E<gt>_add_volume( $volume )

Add all records from a L<WARC::Volume> to the index.

The C<WARC::Index::Builder> base class provides a default implementation.

=cut

sub _add_volume {
  my $self = shift;
  my $volume = shift;

  for (my $record = $volume->first_record; $record; $record = $record->next)
    { $self->_add_record($record) }
}

=back

=cut

1;
__END__

=head1 AUTHOR

Jacob Bachmeyer, E<lt>jcb@cpan.orgE<gt>

=head1 SEE ALSO

L<WARC>, L<WARC::Index>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
