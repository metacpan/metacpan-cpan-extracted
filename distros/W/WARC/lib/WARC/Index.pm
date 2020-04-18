package WARC::Index;						# -*- CPerl -*-

use strict;
use warnings;

use Carp;

our @ISA = qw();

require WARC; *WARC::Index::VERSION = \$WARC::VERSION;

=head1 NAME

WARC::Index - base class for WARC index classes

=head1 SYNOPSIS

  use WARC::Index::File::CDX;	# or ...
  use WARC::Index::File::SDBM;
  # or some other WARC::Index::File::* implementation

  $index = attach WARC::Index::File::CDX (...);	# or ...
  $index = attach WARC::Index::File::SDBM (...);

  $record = $index->search(url => $url, time => $when);
  @records = $index->search(url => $url, time => $when);

  build WARC::Index::File::CDX (...);	# or ...
  build WARC::Index::File::SDBM (...);

=head1 DESCRIPTION

C<WARC::Index> is an abstract base class for indexes on WARC files and
WARC-alike files.  This class establishes the expected interface and
provides a simple interface for building indexes.

=head2 Methods

=over

=item $index = attach WARC::Index::File::* (...)

Construct an index object using the indicated technology and whatever
parameters the index implementation needs.

Typically, indexes are file-based and a single parameter is the name of an
index file which in turn contains the names of the indexed WARC files.

=cut

sub attach {
  die __PACKAGE__." is an abstract base class and "
    .(shift)." must override the 'attach' method"
}

=item $yes_or_no = $index-E<gt>searchable( $key )

Return true or false to reflect if the index can search for the requested
key.  Indexes may be able to search for keys that are not present in
entries returned from those indexes.

See the L<"Search Keys" section|WARC::Collection/"Search Keys"> of the
C<WARC::Collection> page for details on the implemented search keys.

=cut

sub searchable {
  die __PACKAGE__." is an abstract base class and "
    .(ref shift)." must override the 'searchable' method"
}

=item $record = $index-E<gt>search( ... )

=item @records = $index-E<gt>search( ... )

Search an index for records matching parameters.  The C<WARC::Collection>
class uses this method to search each index in a collection.

If the none of the requested search keys are searchable, returns an
undefined value in scalar context and the empty list in list context.

The details of the parameters for this method are documented in the
L<"Search Keys" section|WARC::Collection/"Search Keys"> of the
C<WARC::Collection> page.

=cut

sub search {
  die __PACKAGE__." is an abstract base class and "
    .(ref shift)." must override the 'search' method"
}

=item build WARC::Index::File::* (into =E<gt> $dest, from =E<gt> ...)

=item build WARC::Index::File::* (from =E<gt> [...], into =E<gt> $dest)

The C<WARC::Index> base class B<does> provide this method, however.  The
C<build> method works by loading the corresponding index builder class and
driving the process or simply returning the newly-constructed object.

The C<build> method itself handles the C<from> key for specifying the files
to index.  The C<from> key can be given an array reference, after which
more key =E<gt> value pairs may follow, or can simply use the rest of the
argument list as its value.

If the C<from> key is given, the C<build> method will read the indicated
files, construct an index, and return nothing.  If the C<from> key is not
given, the C<build> method will construct and return an index builder.

All index builders accept at least the C<into> key for specifying where to
store the index.  See the documentation for WARC::Index::File::*::Builder
for more information.

=cut

sub build {
  my $class = shift;

  croak "'build' is a class method"
    if ref $class;
  croak "no arguments given to 'build' class method"
    unless scalar @_;

  my @args = (); my $from = undef;
  while (@_) {
    my $key = shift;
    if ($key eq 'from') {
      if (UNIVERSAL::isa($_[0], 'ARRAY'))	{ $from = shift }
      else					{ $from = [splice @_] }
    } else { push @args, $key, shift }
  }

  croak "empty list of index sources given"
    if defined $from && scalar @$from == 0;

  my $bclass = $class . q{::Builder};
  {
    no strict 'refs';
    unless (exists ${$class.'::'}{'Builder::'})
      { eval q{require }.$bclass; die $@ if $@ }
  }

  my $ob = _new $bclass (@args);

  return $ob unless defined $from;

  $ob->add(@$from);
  return ();
}

=back

=head2 Optional Methods

Some index systems may also provide these methods:

=over

=item $entry = $index-E<gt>first_entry

An index that has a sequential ordering may provide this method to obtain
the first entry in the index.  Indexes that do not have a meaningful
sequence amongst their entries do not provide this method.

=item $entry = $index-E<gt>entry_at( $position )

An index that has a sequential ordering may provide this method to obtain
an entry at a specified position in the index.  The exact format of the
position parameter is not specified in general, but should be a value
previously obtained from the C<entry_position> method on an entry from the
same index.  Valid positions may be sparse.

=back

=head2 Index system registration

The C<WARC::Index> package also provides a registry of loaded index
support.  The C<register> function adds the calling package to the list.

=cut

# Array of arrays listing index implementations and filename patterns.
#  Each element:  [ Package => qr/pattern1/, qr/pattern2/, ... ]
our @Index_Handlers = ();

=over

=item WARC::Index::register( filename =E<gt> $filename_re )

Add the calling package to an internal list of available index handlers.
The calling package must be a subclass of C<WARC::Index> or this function
will croak().

The C<filename> key indicates that the calling package expects to handle
index files with names matching the provided regex.

=cut

sub register {
  my %opt = @_;
  my $caller = scalar caller;

  croak "WARC::Index implementations must subclass WARC::Index"
    unless $caller->isa('WARC::Index');

  croak "WARC::Index implementations must handle a filename pattern"
    unless $opt{filename};

  foreach my $row (grep {$_->[0] eq $caller} @Index_Handlers) {
    push @$row, $opt{filename};	# add pattern to existing row
    return # ensure that there will be at most one row per package
  }
  push @Index_Handlers, [$caller => $opt{filename}];

  return # nothing
}

=item WARC::Index::find_handler( $filename )

Return the registered handler for $filename or undef if none match.  If
multiple handlers match, which one is returned is unspecified.

=cut

sub find_handler {
  my $filename = shift;
  my @match = grep {grep {$filename =~ $_} @$_[1..$#$_]} @Index_Handlers;
  return undef unless @match;
  return $match[0][0];
}

=back

=cut

1;
__END__

=head1 AUTHOR

Jacob Bachmeyer, E<lt>jcb@cpan.orgE<gt>

=head1 SEE ALSO

L<WARC>, L<WARC::Index::Entry>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019, 2020 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
