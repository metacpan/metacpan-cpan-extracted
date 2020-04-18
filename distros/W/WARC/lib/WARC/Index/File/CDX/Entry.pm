package WARC::Index::File::CDX::Entry;				# -*- CPerl -*-

use strict;
use warnings;

require WARC::Index::Entry;
our @ISA = qw(WARC::Index::Entry);

require WARC; *WARC::Index::File::CDX::Entry::VERSION = \$WARC::VERSION;

# This implementation uses a hash as the underlying structure.

# Accessible search keys are stored directly in the hash, while internal
#  values are stored with names with a leading underscore.

sub index { (shift)->{_index} }
sub volume { (shift)->{_g__volume} }
sub entry_position { (shift)->{_entry_offset} }
sub record_offset { (shift)->{_Vv__record_offset} }

sub next {
  my $self = shift;

  return $self->{_index}->entry_at($self->{_entry_offset}
				   + $self->{_entry_length});
}

sub value {
  my $self = shift;
  my $key = shift;

  return undef if $key =~ m/^_/;
  return $self->{$key};
}

1;
__END__

=head1 NAME

WARC::Index::File::CDX::Entry - CDX WARC index entries

=head1 SYNOPSIS

  use WARC::Index::File::CDX;

  $index = attach WARC::Index::File::CDX ($cdx_file);
  $entry = $index->search( ... );

  # see WARC::Index::Entry for base methods

  $next_entry = $entry->next;		# get next entry in CDX index
  $offset = $entry->entry_position;	# get offset of entry in CDX file

=head1 DESCRIPTION

See L<WARC::Index::Entry> for details.

=head1 AUTHOR

Jacob Bachmeyer, E<lt>jcb@cpan.orgE<gt>

=head1 SEE ALSO

L<WARC>, L<WARC::Index::Entry>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
