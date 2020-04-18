package WARC::Index::Volatile;					# -*- CPerl -*-

use strict;
use warnings;

use Scalar::Util;

use WARC::Index;
use WARC::Index::Builder;
use WARC::Index::Entry;

our @ISA = qw(WARC::Index WARC::Index::Builder);

use WARC; *WARC::Index::Volatile::VERSION = \$WARC::VERSION;

use Carp;

require WARC::Volume;

our @Default_Column_Set = qw/record_id/;

WARC::Index::register(filename => qr/[.]warc(?:[.]gz)?$/);

# This implementation uses a hash as the underlying structure.
#  Keys defined by this class:
#
#   volumes
#	array of WARC::Volume objects known to this index
#	-- This field is used to intern volume objects within an index.
#   volume_position_by_tag
#	hash mapping volume tags to positions in volumes array
#	-- This field is used to intern volume objects within an index.
#   entries
#	hash mapping volume tags to arrays of index entries
#	-- This field is used to intern index entries within an index.
#   entry_position_by_tag_offset
#	hash mapping volume tags to hashes mapping record offset pairs to
#	positions in entries arrays
#	-- This field is used to intern index entries within an index.
#   by
#	nested hash mapping indexed columns and values to arrays of entries

sub _dbg_dump {
  my $self = shift;

  my $out =
    (ref $self)." over ".(scalar @{$self->{volumes}})." volume(s):\n";
  $out .= "  $_\n" for map $_->filename, @{$self->{volumes}};

  return $out;
}

# implement WARC::Index interface
sub attach { my $class = shift; $class->build(from => \@_) }

# override build method inherited from WARC::Index
sub build {
  my $class = shift;

  my @columns = @Default_Column_Set;
  my @from = ();

  unless (defined wantarray)
    { carp "building volatile index in void context"; return }

  while (@_) {
    my $key = shift;
    if ($key eq 'from') {
      if (UNIVERSAL::isa($_[0], 'ARRAY'))	{ @from = @{(shift)} }
      else					{ @from = splice @_ }
    } elsif ($key eq 'columns')			{ @columns = @{(shift)} }
    else { croak "unknown option '$key' building volatile index" }
  }

  my $_dvmap = \%WARC::Index::Entry::_distance_value_map;
  croak "unknown index column requested"
    if grep !defined $_dvmap->{$_}, @columns;

  my $index = bless
    { by => {(map {$_ => {}} (grep $_dvmap->{$_}[0] eq 'exact', @columns)),
	     (map {$_ => []} (grep $_dvmap->{$_}[0] eq 'prefix', @columns))}
    }, $class;

  $index->add($_) for @from;

  { our $_total_constructed; $_total_constructed++ }

  return $index;
}
sub DESTROY { our $_total_destroyed; $_total_destroyed++ }

sub searchable {
  my $self = shift;
  my $key = shift;

  return defined $self->{by}{$key};
}

sub search {
  my $self = shift;

  unless (defined wantarray)
    { carp "calling 'search' method in void context"; return }

  croak "no arguments given to 'search' method"
    unless scalar @_;
  croak "odd number of arguments given to 'search' method"
    if scalar @_ % 2;

  my $key = undef; my $val = undef;
  for (my $i = 0; $i < $#_; $i += 2)
    { (($key, $val) = @_[$i,1+$i]), last if ref $self->{by}{$_[$i]} eq 'ARRAY' }
  for (my $i = 0; $i < $#_; $i += 2)
    { (($key, $val) = @_[$i,1+$i]), last if ref $self->{by}{$_[$i]} eq 'HASH' }
  croak "no usable search key" unless $key;

  my $mode = $WARC::Index::Entry::_distance_value_map{$key}[0];
  my $refkey = $WARC::Index::Entry::_distance_value_map{$key}[1];

  my $rows;
  if ($mode eq 'exact') {
    $rows = $self->{by}{$key}{$val};
  } elsif ($mode eq 'prefix') {
    $rows = [grep $_->value($refkey) =~ m/^\Q$val/, @{$self->{by}{$key}}];
  } else { die "unimplemented search mode $mode" }

  if (wantarray)
    { return grep { $_->distance(@_) >= 0 } @$rows }
  else {
    my $result = undef; my $result_distance = -1;
    foreach my $entry (@$rows) {
      my $distance = $entry->distance(@_);
      unless (0 > $distance) {
	if ($result_distance < 0		# first match found
	    or $distance < $result_distance)	# or better match found
	  { $result = $entry; $result_distance = $distance }
      }
      return $result if $result_distance == 0;	# no better match possible
    }
    return $result;
  }
}

sub first_entry {
  my $self = shift;

  return $self->{entries}{$self->{volumes}[0]->_file_tag}[0];
}

# implement WARC::Index::Builder interface
sub _intern_volume ($$) {
  my $index = shift;
  my $volume = shift;

  my $voltag = $volume->_file_tag;
  $index->{volume_position_by_tag}{$voltag} =
    ((push @{$index->{volumes}}, $volume) - 1)
      unless defined $index->{volume_position_by_tag}{$voltag};
  $volume = $index->{volumes}[$index->{volume_position_by_tag}{$voltag}];

  return $volume, $voltag;
}
sub _index_entry ($$) {
  my $index = shift;
  my $entry = shift;

  foreach my $key (keys %{$index->{by}}) {
    my $refkey = $WARC::Index::Entry::_distance_value_map{$key}[1];
    next unless defined $entry->value($refkey);
    if (ref $index->{by}{$key} eq 'HASH')
      { push @{$index->{by}{$key}{$entry->{$refkey}}}, $entry }
    elsif (ref $index->{by}{$key} eq 'ARRAY')
      { push @{$index->{by}{$key}}, $entry } # defer sort to outer call
    else { die "unknown object in $key index slot" }
  }
}

sub _add_record {
  my $index = shift;
  my $record = shift;

  my $volume; my $voltag;
  ($volume, $voltag) = _intern_volume $index, $record->volume;

  my $offset = $record->offset;
  my $entry = WARC::Index::Volatile::Entry->_new
    ( _index => $index, _volume => $volume, _record_offset => $offset );

  # intern entry
  return if defined $index->{entry_position_by_tag_offset}{$voltag}{$offset};
  $index->{entry_position_by_tag_offset}{$voltag}{$offset} =
    ((push @{$index->{entries}{$voltag}}, $entry) - 1);

  # populate entry
  $entry->{time} = $record->date;
  $entry->{record_id} = $record->id;
  $entry->{segment_origin_id} = $record->field('WARC-Segment-Origin-ID')
    if exists $index->{by}{segment_origin_id}
      && $record->type eq 'continuation';
  $entry->{url} = $record->field('WARC-Target-URI')
    if (exists $index->{by}{url} || exists $index->{by}{url_prefix})
      && defined $record->field('WARC-Target-URI');

  _index_entry $index, $entry;
}

sub _add_entry ($$) {
  my $index = shift;
  my $source = shift;

  if (grep !defined $source->value($_), keys %{$index->{by}})
    # at least one column not in source index; index the record instead
    { $index->_add_record($source->record) }
  else {
    # volume and offset can be retrieved from a stub record without I/O
    my $rstub = $source->record; my $volume; my $voltag;
    ($volume, $voltag) = _intern_volume $index, $rstub->volume;
    my $offset = $rstub->offset;
    my $entry = WARC::Index::Volatile::Entry->_new
      ( _index => $index, _volume => $volume, _record_offset => $offset,
	map { $_ => $source->value($_) } keys %{$index->{by}} );

    # intern entry
    return if defined $index->{entry_position_by_tag_offset}{$voltag}{$offset};
    $index->{entry_position_by_tag_offset}{$voltag}{$offset} =
      ((push @{$index->{entries}{$voltag}}, $entry) - 1);

    _index_entry $index, $entry;
  }
}

sub add {
  my $self = shift;

  $self->SUPER::add(@_);

  # sort any array-based columns
  foreach my $key (keys %{$self->{by}}) {
    next unless ref $self->{by}{$key} eq 'ARRAY';
    my $refkey = $WARC::Index::Entry::_distance_value_map{$key}[1];
    @{$self->{by}{$key}} =
      sort { $a->value($refkey) cmp $b->value($refkey) } @{$self->{by}{$key}};
  }
}

{
  package WARC::Index::Volatile::Entry;

  our @ISA = qw(WARC::Index::Entry);

  # This implementation uses a hash as the underlying structure.
  #
  # Accessible search keys are stored directly in the hash, while internal
  #  values are stored with names with a leading underscore.

  #  Keys defined by this class:
  #
  #   _index
  #	weak reference to parent index
  #   _volume
  #	reference to volume containing record
  #   _record_offset
  #	offset of record within containing volume

  sub index { (shift)->{_index} }
  sub volume { (shift)->{_volume} }
  sub record_offset { (shift)->{_record_offset} }

  sub next {
    my $self = shift;

    my $idx = $self->index;
    my $vt = $self->volume->_file_tag;
    my $off = $self->record_offset;

    my $next = $idx->{entries}{$vt}
      [1+$idx->{entry_position_by_tag_offset}{$vt}{$off}];
    return $next if defined $next;

    my $nextvol = $idx->{volumes}[1+$idx->{volume_position_by_tag}{$vt}];
    $next = $idx->{entries}{$nextvol->_file_tag}[0] if defined $nextvol;

    return $next;
  }

  sub value {
    my $self = shift;
    my $key = shift;

    return undef if $key =~ m/^_/;
    return $self->{$key};
  }

  sub _new {
    my $class = shift;

    my $entry = bless { @_ }, $class;
    Scalar::Util::weaken $entry->{_index};
    return $entry;
  }
}

1;
__END__

=head1 NAME

WARC::Index::Volatile - in-memory volume index for WARC library

=head1 SYNOPSIS

  use WARC::Index::Volatile;

  # using default column list
  $index = attach WARC::Index::Volatile ($warc_file);
  $index = attach WARC::Index::Volatile ($volume);

  # specifying columns to index
  $index = build WARC::Index::Volatile
    (from => [$warc_file, ...], columns => [ ... ]);
  # NOTE:  This use of build is unique to WARC::Index::Volatile!

=head1 DESCRIPTION

The C<WARC::Index::Volatile> class provides an in-memory index
implementation suitable for small-scale applications.  Unusally for index
systems, a volatile index object is also its own index builder.

Loading this module also registers a handler that allows WARC volumes to be
treated as indexes when assembling a C<WARC::Collection>.

=head1 AUTHOR

Jacob Bachmeyer, E<lt>jcb@cpan.orgE<gt>

=head1 SEE ALSO

L<WARC>, L<WARC::Index>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
