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

use strict;
use Carp;
use IO::File;
use Text::BibTeX::Entry;

use vars qw'$VERSION';
$VERSION = 0.88;

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

=item open (FILENAME [OPTS])

Opens the file specified by FILENAME. OPTS is an hashref that can have
the following values:

=over 4

=item MODE

mode as specified by L<IO::File>

=item PERMS

permissions as specified by L<IO::File>. Can only be used in conjunction
with C<MODE>

=item BINMODE

By default, Text::BibTeX uses bytes directly. Thus, you need to encode
strings accordingly with the encoding of the files you are reading. You can
also select UTF-8. In this case, Text::BibTeX will return UTF-8 strings in
NFC mode. Note that at the moment files with BOM are not supported.

Valid values are 'raw/bytes' or 'utf-8'.

=item NORMALIZATION

By default, Text::BibTeX outputs UTF-8 in NFC form. You can change this by passing
the name of a different form.

Valid values are those forms supported by the Unicode::Normalize module
('NFD', 'NFDK' etc.)

=item RESET_MACROS

By default, Text::BibTeX accumulates macros. This means that when you open a second
file, macros defined by the first are still available. This may result on warnings
of macros being redefined.

This option can be used to force Text::BibTeX to clean up all macros definitions
(except for the month macros).

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
    my ($self) = shift;
    $self->{filename} = shift;

    $self->{binmode}       = 'bytes';
    $self->{normalization} = 'NFC';
    my @args = ( $self->{filename} );

    if ( ref $_[0] eq "HASH" ) {
        my $opts = {};
        $opts = shift;
        $opts->{ lc $_ } = $opts->{$_} for ( keys %$opts );
        $self->{binmode} = 'utf-8'
            if exists $opts->{binmode} && $opts->{binmode} =~ /utf-?8/i;
        $self->{normalization} = $opts->{normalization} if exists $opts->{normalization};

        if (exists $opts->{reset_macros} && $opts->{reset_macros}) {
          Text::BibTeX::delete_all_macros();
          Text::BibTeX::_define_months();
        }

        if ( exists $opts->{mode} ) {
            push @args, $opts->{mode};
            push @args, $opts->{perms} if exists $opts->{perms};
        }
    }
    else {
        push @args, @_;
    }

    $self->{handle} = IO::File->new;
    $self->{handle}->open(@args);    # filename, maybe mode, maybe perms
}


sub close
{
   my $self = shift;
   if ( $self->{handle} ) {
      Text::BibTeX::Entry->new ($self->{filename}, undef);   # resets parser
      $self->{handle}->close;
   }
}

sub eof
{
   eof (shift->{handle});
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
