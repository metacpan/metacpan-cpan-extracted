# ----------------------------------------------------------------------
# NAME       : BibTeX/File.pm
# CLASSES    : Text::BibTeX::File
# RELATIONS  : 
# DESCRIPTION: Provides an object-oriented interface to whole BibTeX
#              files.
# CREATED    : March 1997, Greg Ward
# MODIFIED   : 
# VERSION    : $Id$
# COPYRIGHT  : Copyright (c) 1997-2000 by Gregory P. Ward.  All rights
#              reserved.
# 
#              This file is part of the Text::BibTeX library.  This
#              library is free software; you may redistribute it and/or
#              modify it under the same terms as Perl itself.
# ----------------------------------------------------------------------

package Text::BibTeX::File;

use 5.026;
use strict;
use warnings;
use Carp;
use IO::File;
use Scalar::Util qw(blessed reftype);
use Text::BibTeX;
use Text::BibTeX::Entry;

our $VERSION = '1.00';

=head1 NAME

Text::BibTeX::File - interface to whole BibTeX files

=head1 SYNOPSIS

   use Text::BibTeX::File;

   $bib = Text::BibTeX::File->new("foo.bib") or die "foo.bib: $!\n";
   # or:
   $bib =  Text::BibTeX::File->new;
   $bib->open("foo.bib", {binmode => 'utf-8', normalization => 'NFC'}) || die "foo.bib: $!\n";

   $bib->set_structure ($structure_name,
                        $option1 => $value1, ...);

   $at_eof = $bib->eof;

   $bib->close;

=head1 DESCRIPTION

C<Text::BibTeX::File> provides an object-oriented interface to BibTeX
files.  Its most obvious purpose is to keep track of a filename and
filehandle together for use by the C<Text::BibTeX::Entry> module (which
is much more interesting).  In addition, it allows you to specify
certain options which are applicable to a whole database (file), rather
than having to specify them for each entry in the file.  Currently, you
can specify the I<database structure> and some I<structure options>.
These concepts are fully documented in L<Text::BibTeX::Structure>.

=head1 METHODS

=head2 Object creation, file operations

=over 4

=item new ([FILENAME], [OPTS]) 

Creates a new C<Text::BibTeX::File> object.  If FILENAME is supplied, passes
it to the C<open> method (along with OPTS).  If the C<open> fails, C<new>
fails and returns false; if the C<open> succeeds (or if FILENAME isn't
supplied), C<new> returns the new object reference.

=item open (SOURCE [, OPTS])

Opens SOURCE for reading.  SOURCE is usually a filename, but may also be
a reference to a scalar (to read from a string in memory) or an already
open filehandle (any Perl filehandle works, including tied handles and
handles with I/O layers).  OPTS is a hashref that can have the following
values (case-insensitive):

=over 4

=item MODE

mode as specified by L<IO::File>

=item PERMS

permissions as specified by L<IO::File>. Can only be used in conjunction
with C<MODE>

=item BINMODE

C<'utf-8'> (the default) or C<'bytes'> (also C<'raw'>).

In C<'utf-8'> mode the input is decoded as UTF-8 and all strings returned
(entry types, keys, field names, values, names...) are Perl character
strings, normalised as given by C<NORMALIZATION>.  Bytes that are not valid
UTF-8 are replaced by U+FFFD with a warning; use C<ENCODING> to read files
in other encodings.  A leading byte order mark is ignored.

In C<'bytes'> mode the input is not decoded at all and strings are
returned as byte strings, exactly as they appear in the file.

=item ENCODING

The encoding of the file, if it isn't UTF-8 (eg. C<'latin1'>): an
C<:encoding(...)> layer is pushed onto the filehandle.  If you pass in a
filehandle that already has an encoding layer, you don't need this.

=item NORMALIZATION

The Unicode normalization form for strings returned in C<'utf-8'> mode:
C<'NFC'> (the default), C<'NFD'>, C<'NFKC'>, C<'NFKD'>, or C<'none'>.

=item RESET_MACROS

By default, macros (C<@string> definitions) accumulate in one global
table, as in BibTeX itself: when you open a second file, macros defined by
the first are still available.  This option clears all macro definitions
(except for the month macros) before the file is read.

=item PRIVATE_MACROS

Give this file its own macro table: C<@string> definitions in it are not
seen by any other file, and it does not see those made by other files.
It still sees the global macros (the month names, and any defined with
L<Text::BibTeX/add_macro_text>).

=item FILENAME

When SOURCE is a filehandle, the name to use in error messages.

=back

=item close ()

Closes the filehandle associated with the object.  If there is no such
filehandle (i.e., C<open> was never called on the object), does nothing.

=item eof ()

Returns the end-of-file state of the filehandle associated with the
object: a true value means we are at the end of the file.

=back

=cut

sub new
{
   my $class = shift;

   $class = ref ($class) || $class;
   my $self = bless {}, $class;
   ($self->open (@_) || return undef) if @_;
   $self;
}

sub open {
    my ($self, $source, @args) = @_;
    my $opts = (ref $args[0] eq 'HASH') ? shift @args : {};
    my ($binmode, $norm, $o) = Text::BibTeX::_options($opts);

    $self->close if $self->{handle};
    $self->{binmode}        = $binmode;
    $self->{normalization}  = $norm;
    $self->{private_macros} = $o->{private_macros} ? 1 : 0;

    if ($o->{reset_macros}) {
        Text::BibTeX::delete_all_macros();
        Text::BibTeX::_define_months();
    }

    if (exists $o->{mode}) {
        @args = ($o->{mode});
        push @args, $o->{perms} if exists $o->{perms};
    }

    my $fh;
    if (ref $source && (reftype($source) // '') eq 'GLOB') {
        $fh = $source;                  # an open filehandle
        $self->{filename} = $o->{filename};
        $self->{own_handle} = 0;
    }
    else {
        $self->{filename} = $o->{filename} // (ref $source ? undef : $source);
        $fh = IO::File->new;
        # (a plain filename keeps IO::File's 2-argument open semantics)
        @args = ('<') if ref $source && !@args;
        $fh->open($source, @args) or return;
        $self->{own_handle} = 1;
    }

    if (defined $o->{encoding}) {
        binmode($fh, ":encoding($o->{encoding})")
            or croak "Text::BibTeX::File: can't use encoding '$o->{encoding}': $!";
    }
    elsif ($binmode eq 'utf-8' && $self->{own_handle} && @args
           && $args[0] =~ /^\s*(?:[>+]|[wa])/) {
        # writing character strings: encode them as UTF-8
        binmode($fh, ':encoding(UTF-8)');
    }

    $self->{handle} = $fh;
    return 1;
}

# The parser for this file (created when the first entry is read)
sub _parser {
    my $self = shift;
    croak "Text::BibTeX::File: file is not open" unless $self->{handle};
    return $self->{parser} //= Text::BibTeX::Parser->new(
        $self->{handle}, $self->{filename},
        $self->{binmode} eq 'utf-8' ? 1 : 0, $self->{private_macros});
}

sub close
{
   my $self = shift;
   delete $self->{parser};
   if (my $fh = delete $self->{handle}) {
      $fh->close if $self->{own_handle};
   }
}

sub eof
{
   my $self = shift;
   return 1 unless $self->{handle};
   return $self->{parser}->eof if $self->{parser};
   eof ($self->{handle});
}

sub DESTROY
{
   my $self = shift;
   $self->close;
}

=head2 Object properties

=over 4

=item set_structure (STRUCTURE [, OPTION =E<gt> VALUE, ...])

Sets the database structure for a BibTeX file.  At the simplest level,
this means that entries from the file are expected to conform to certain
field requirements as specified by the I<structure module>.  It also
gives you full access to the methods of the particular I<structured
entry class> for this structure, allowing you to perform operations
specific to this kind of database.  See L<Text::BibTeX::Structure/"CLASS
INTERACTIONS"> for all the consequences of setting the database
structure for a C<Text::BibTeX::File> object.

=item structure ()

Returns the name of the database structure associated with the object
(as set by C<set_structure>).

=cut

sub set_structure
{
   my ($self, $structure, @options) = @_;

   require Text::BibTeX::Structure;
   croak "Text::BibTeX::File::set_structure: options list must have even " .
         "number of elements"
      unless @options % 2 == 0;
   $self->{structure} = Text::BibTeX::Structure->new($structure, @options);
}

sub structure { shift->{structure} }


=item preserve_values ([PRESERVE])

Sets the "preserve values" flag, to control all future parsing of entries
from this file.  If PRESERVE isn't supplied, returns the current state of
the flag.  See L<Text::BibTeX::Value> for details on parsing in "value
preservation" mode.

=back

=cut

sub preserve_values
{
   my $self = shift;

   $self->{'preserve_values'} = shift if @_;
   $self->{'preserve_values'};
}


1;

=head1 SEE ALSO

L<Text::BibTeX>, L<Text::BibTeX::Entry>, L<Text::BibTeX::Structure>

=head1 AUTHOR

Greg Ward <gward@python.net>

=head1 COPYRIGHT

Copyright (c) 1997-2000 by Gregory P. Ward.  All rights reserved.  This file
is part of the Text::BibTeX library.  This library is free software; you
may redistribute it and/or modify it under the same terms as Perl itself.
