package WARC::Index::Entries;					# -*- CPerl -*-

use strict;
use warnings;

require WARC::Index::Entry;
our @ISA = qw(WARC::Index::Entry);

require WARC; *WARC::Index::Entries::VERSION = \$WARC::VERSION;

use Carp;

=head1 NAME

WARC::Index::Entries - combine information from multiple WARC::Index entries

=head1 SYNOPSIS

  use WARC::Collection;

  # WARC::Index::Entries objects are used to merge data from multiple indexes
  #  and are used internally when searching a collection with multiple indexes

=cut

# This implementation uses an array of index entries as the underlying
#  structure.  Correct results depend on all entries in the array referring
#  to the same record.

=head1 DESCRIPTION

See L<WARC::Index::Entry/"Common Methods"> for accessor methods.

=head2 Constructor

=over

=item $combined_entry = coalesce WARC::Index::Entries ( [ ... ] )

Return a coalesced index entry by combining multiple C<WARC::Index::Entry>
objects, presumably from different indexes.  All of the index entries so
combined must have the same tag value, or the resultant behavior is
undefined.  This constructor does not verify this requirement.

Since this is intended for internal use, the array reference passed to the
constructor is reused as part of the returned object.

=cut

sub coalesce {
  my $class = shift;
  my $entries = shift;

  return $entries->[0] if scalar @$entries == 1;

  bless $entries, $class;
}

=back

=cut

sub index { croak "a coalesced index entry is not in any one index" }
sub volume { (shift)->[0]->volume }
sub record { my $self = shift; $self->[0]->record(@_) }
sub record_offset { (shift)->[0]->record_offset }

sub value {
  my $self = shift;
  my $key = shift;

  foreach my $entry (@$self) {
    my $v = $entry->value($key);
    return $v if defined $v;
  }

  # not found in any entry
  return undef;
}

1;
__END__

=head1 AUTHOR

Jacob Bachmeyer, E<lt>jcb@cpan.orgE<gt>

=head1 SEE ALSO

L<WARC>, L<WARC::Index::Entry>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
