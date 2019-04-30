# ----------------------------------------------------------------------
# NAME       : BibTeX/Bib.pm
# CLASSES    : Text::BibTeX::BibStructure, Text::BibTeX::BibEntry;
#              loads Text::BibTeX::BibSort and Text::BibTeX::BibFormat
#              for use by BibEntry
# RELATIONS  : BibStructure inherits from Structure
#              BibEntry inherits from BibSort and BibFormat, which
#                both inherit from StructuredEntry
# DESCRIPTION: Implements the "Bib" structure, which provides the
#              same functionality -- though in a completely different
#              context, and much more customizably -- as the standard
#              style files of BibTeX 0.99.
# CREATED    : 1997/09/21, Greg Ward
# MODIFIED   : 
# VERSION    : $Id$
# COPYRIGHT  : Copyright (c) 1997-2000 by Gregory P. Ward.  All rights
#              reserved.
# 
#              This file is part of the Text::BibTeX library.  This
#              library is free software; you may redistribute it and/or
#              modify it under the same terms as Perl itself.
# ----------------------------------------------------------------------

=head1 NAME

Text::BibTeX::Bib - defines the "Bib" database structure

=head1 SYNOPSIS

   $bibfile = Text::BibTeX::File $filename->new;
   $bibfile->set_structure ('Bib',
                            # Default option values:
                            sortby => 'name',
                            namestyle => 'full'
                            nameorder => 'first',
                            atitle => 1,
                            labels => 'numeric');

   # Alternate option values:
   $bibfile->set_option (sortby => 'year');
   $bibfile->set_option (namestyle => 'nopunct');
   $bibfile->set_option (namestyle => 'nospace');
   $bibfile->set_option (nameorder => 'last');
   $bibfile->set_option (atitle => 0);   
   $bibfile->set_option (labels => 'alpha');   # not implemented yet!

   # parse entry from $bibfile and automatically make it a BibEntry
   $entry = Text::BibTeX::Entry->new($bibfile);

   # or get an entry from somewhere else which is hard-coded to be
   # a BibEntry
   $entry = Text::BibTeX::BibEntry->new(...);

   $sortkey = $entry->sort_key;
   @blocks = $entry->format;

=head1 DESCRIPTION

(B<NOTE!> Do not believe everything you read in this document.  The
classes described here are unfinished and only lightly tested.  The
current implementation is a proof-of-principle, to convince myself (and
anyone who might be interested) that it really is possible to
reimplement BibTeX 0.99 in Perl using the core C<Text::BibTeX> classes;
this principle is vaguely demonstrated by the current C<Bib*> modules,
but not really proved.  Many important features needed to reimplement
the standard styles of BibTeX 0.99 are missing, even though this
document may brashly assert otherwise.  If you are interested in using
these classes, you should start by reading and grokking the code, and
contributing the missing bits and pieces that you need.)

C<Text::BibTeX::Bib> implements the database structure for
bibliographies as defined by the standard styles of BibTeX 0.99.  It
does this by providing two classes, C<BibStructure> and C<BibEntry> (the
leading C<Text::BibTeX> is implied, and will be omitted for the rest of
this document).  These two classes, being specific to bibliographic
data, are outside of the core C<Text::BibTeX> class hierarchy, but are
distributed along with it as they provide a canonical example of a
specific database structure using classes derived from the core
hierarchy.

C<BibStructure>, which derives from the C<Structure> class, deals with
the structure as a whole: it handles structure options and describes all
the types and fields that make up the database structure.  If you're
interested in writing your own database structure modules, the standard
interface for both of these is described in L<Text::BibTeX::Structure>;
if you're just interested in finding out the exact database structure or
the options supported by the C<Bib> structure, you've come to the right
place.  (However, you may have to wade through a bit of excess verbiage
due to this module's dual purpose: first, to reimplement the standard
styles of BibTeX 0.99, and second, to provide an example for other
programmers wishing to implement new or derived database structure
modules.)

C<BibEntry> derives from the C<StructuredEntry> class and provides
methods that operate on individual entries presumed to come from a
database conforming to the structure defined by the C<BibStructure>
class.  (Actually, to be completely accurate, C<BibEntry> inherits from
two intermediate classes, C<BibSort> and C<BibFormat>.  These two
classes just exist to reduce the amount of code in the C<Bib> module,
and thanks to the magic of inheritance, their existence is usually
irrelevant.  But you might want to consult those two classes if you're
interested in the gory details of sorting and formatting entries from
BibTeX 0.99-style bibliography databases.)

=cut


# first, the "structure class" (inherits from Text::BibTeX::Structure)

package Text::BibTeX::BibStructure;
use strict;
use vars qw(@ISA $VERSION);
@ISA = qw(Text::BibTeX::Structure);
$VERSION = '0.88';

=head1 STRUCTURE OPTIONS

C<BibStructure> handles several user-supplied "structure options" and
methods for dealing with them.  The options currently supported by the
C<Bib> database structure, and the values allowed for them, are:

=over 4

=item C<sortby>

How to sort entries.  Valid values: C<name> (sort on author names, year,
and title), C<year> (sort on year, author names, and title).  Sorting on
"author names" is a bit more complicated than just using the C<author>
field; see L<Text::BibTeX::BibSort> for details.  Default value: C<name>.

=item C<namestyle>

How to print author (and editor) names: C<full> for unabbreviated first
names, C<abbrev> for first names abbreviated with periods, C<nopunct>
for first names abbreviated with space but no periods, and C<nospace> to
abbreviate without space or periods.  Default value: C<full>.

=item C<nameorder>

The order in which to print names: C<first> for "first von last jr"
order, and C<last> for "von last jr first" order.  Default value:
C<first>.

=item C<atitle_lower>

A boolean option: if true, non-book titles will be changed to "sentence
capitalization:" words following colons and sentence-ending punctuation
will be capitalized, and everything else at brace-depth zero will be
changed to lowercase.  Default value: true.

=item C<labels>

The type of bibliographic labels to generate: C<numeric> or C<alpha>.
(Alphabetic labels are not yet implemented, so this option is currently
ignored.)  Default value: C<numeric>.

=back

Also, several "markup options" are supported.  Markup options are
distinct because they don't change how text is extracted from the
database entries and subsequently mangled; rather, they supply bits of
markup that go around the database-derived text.  Markup options are
always two-element lists: the first to "turn on" some feature of the
markup language, and the second to turn it off.  For example, if your
target language is LaTeX2e and you want journal names emphasized, you
would supply a list reference C<['\emph{','}']> for the C<journal_mkup>
option.  If you were instead generating HTML, you might supply
C<['E<lt>emphE<gt>','E<lt>/emphE<gt>']>.  To keep the structure module
general with respect to markup languages, all markup options are empty
by default.  (Or, rather, they are all references to lists consisting of
two empty strings.)

=over 4

=item C<name_mkup>

Markup to add around the list of author names.

=item C<atitle_mkup>

Markup to add around non-book (article) titles.

=item C<btitle_mkup>

Markup to add around book titles.

=item C<journal_mkup>

Markup to add around journal names.

=back

=cut

my %default_options =
   (sortby      => 'name',              # or 'year', 'none'
    namestyle   => 'full',              # or 'abbrev', 'nopunct', 'nospace'
    nameorder   => 'first',             # or 'last'
    atitle_lower=> 1,                   # mangle case of non-book titles?
    labels      => 'numeric',           # or 'alpha' (not yet supported!)
    name_mkup   => ['', ''],
    atitle_mkup => ['', ''],
    btitle_mkup => ['', ''],
    journal_mkup=> ['', ''],
   );


=head2 Option methods

As required by the C<Text::BibTeX::Structure> module,
C<Text::BibTeX::Bib> provides two methods for handling options:
C<known_option> and C<default_option>.  (The other two option methods,
C<set_options> and C<get_options>, are just inherited from
C<Text::BibTeX::Structure>.)

=over 4

=item known_option (OPTION)

Returns true if OPTION is one of the options on the above list.

=item default_option (OPTION)

Returns the default value of OPTION, or C<croak>s if OPTION is not a
supported option.

=back

=cut

sub known_option 
{
   my ($self, $option) = @_;
   return exists $default_options{$option};
}


sub default_option
{
   my ($self, $option) = @_;
   return exists $default_options{$option}
      ? $default_options{$option}
      : $self->SUPER::default_option ($option);
}


# The field lists in the following documentation are automatically
# generated by my `doc_structure' program -- I run it and read the
# output into this file.  Wouldn't it be cool if the module could just
# document itself?  Ah well, dreaming again...

=head1 DATABASE STRUCTURE

The other purpose of a structure class is to provide a method,
C<describe_entry>, that lists the allowed entry types and the known
fields for the structure.  Programmers wishing to write their own
database structure module should consult L<Text::BibTeX::Structure> for
the conventions and requirements of this method; the purpose of the
present document is to describe the C<Bib> database structure.

The allowed entry types, and the fields recognized for them, are:

=over 4

=item C<article>

Required fields: C<author>, C<title>, C<journal>, C<year>.
Optional fields: C<volume>, C<number>, C<pages>, C<month>, C<note>.

=item C<book>

Required fields: C<title>, C<publisher>, C<year>.
Optional fields: C<series>, C<address>, C<edition>, C<month>, C<note>.
Constrained fields: exactly one of C<author>, C<editor>; at most one of C<volume>, C<number>.

=item C<booklet>

Required fields: C<title>.
Optional fields: C<author>, C<howpublished>, C<address>, C<month>, C<year>, C<note>.

=item C<inbook>

Required fields: C<publisher>, C<year>.
Optional fields: C<series>, C<type>, C<address>, C<edition>, C<month>, C<note>.
Constrained fields: exactly one of C<author>, C<editor>; at least one of C<chapter>, C<pages>; at most one of C<volume>, C<number>.

=item C<incollection>

Required fields: C<author>, C<title>, C<booktitle>, C<publisher>, C<year>.
Optional fields: C<editor>, C<series>, C<type>, C<chapter>, C<pages>, C<address>, C<edition>, C<month>, C<note>.
Constrained fields: at most one of C<volume>, C<number>.

=item C<inproceedings>

=item C<conference>

Required fields: C<author>, C<title>, C<booktitle>, C<year>.
Optional fields: C<editor>, C<series>, C<pages>, C<address>, C<month>, C<organization>, C<publisher>, C<note>.
Constrained fields: at most one of C<volume>, C<number>.

=item C<manual>

Required fields: C<title>.
Optional fields: C<author>, C<organization>, C<address>, C<edition>, C<month>, C<year>, C<note>.

=item C<mastersthesis>

Required fields: C<author>, C<title>, C<school>, C<year>.
Optional fields: C<type>, C<address>, C<month>, C<note>.

=item C<misc>

Required fields: none.
Optional fields: C<author>, C<title>, C<howpublished>, C<month>, C<year>, C<note>.

=item C<phdthesis>

Required fields: C<author>, C<title>, C<school>, C<year>.
Optional fields: C<type>, C<address>, C<month>, C<note>.

=item C<proceedings>

Required fields: C<title>, C<year>.
Optional fields: C<editor>, C<series>, C<address>, C<month>, C<organization>, C<publisher>, C<note>.
Constrained fields: at most one of C<volume>, C<number>.

=item C<techreport>

Required fields: C<author>, C<title>, C<institution>, C<year>.
Optional fields: C<type>, C<number>, C<address>, C<month>, C<note>.

=item C<unpublished>

Required fields: C<author>, C<title>, C<note>.
Optional fields: C<month>, C<year>.

=back 

=cut

sub describe_entry
{
   my $self = shift;

   # Advantages of the current scheme (set all fields for a particular
   # entry type together):
   #   - groups fields more naturally (by entry type)
   #   - might lend itself to structuring things by 'type' in the object
   #     as well, making it easier to determine if a type is valid
   #   - prevents accidentally giving a type optional fields but no
   #     required fields -- currently this mistake would make the type
   #     'unknown'
   # 
   # Requirement of any scheme:
   #   - must be easy for derived classes to override/augment the field
   #     lists defined here! (ie. they should be able just to inherit 
   #     describe_entry; or explicitly call SUPER::describe_entry and then
   #     undo/change some of its definitions

   # Things that I don't think are handled by this scheme, but that
   # bibtex does look out for:
   #  * warns if month but no year
   #  * crossref stuff:
   #    - article can xref article; xref'd entry must have key or journal
   #    - book or inboox can xref book; xref'd entry must have editor,
   #      key, or series
   #    - incollection can xref a book and inproceedings can xref a 
   #      proceedings; xref'd entry must have editor, key, or booktitle

   $self->set_fields ('article',
                      [qw(author title journal year)],
                      [qw(volume number pages month note)]);
   $self->set_fields ('book',
                      [qw(title publisher year)],  
                      [qw(series address edition month note)],
                      [1, 1, [qw(author editor)]],
                      [0, 1, [qw(volume number)]]);
   $self->set_fields ('booklet',
                      [qw(title)],
                      [qw(author howpublished address month year note)]);
   $self->set_fields ('inbook',
                      [qw(publisher year)],
                      [qw(series type address edition month note)],
                      [1, 1, [qw(author editor)]],
                      [1, 2, [qw(chapter pages)]],
                      [0, 1, [qw(volume number)]]);
   $self->set_fields ('incollection',
                      [qw(author title booktitle publisher year)],
                      [qw(editor series type chapter pages address 
                          edition month note)],
                      [0, 1, [qw(volume number)]]);
   $self->set_fields ('inproceedings',
                      [qw(author title booktitle year)],
                      [qw(editor series pages address month 
                          organization publisher note)],
                      [0, 1, [qw(volume number)]]);
   $self->set_fields ('conference',
                      [qw(author title booktitle year)],
                      [qw(editor series pages address month 
                          organization publisher note)],
                      [0, 1, [qw(volume number)]]);
   $self->set_fields ('manual',
                      [qw(title)],
                      [qw(author organization address edition 
                          month year note)]);
   $self->set_fields ('mastersthesis',
                     [qw(author title school year)],
                     [qw(type address month note)]);
   $self->set_fields ('misc',
                      [],
                      [qw(author title howpublished month year note)]);
   $self->set_fields ('phdthesis',
                      [qw(author title school year)],
                      [qw(type address month note)]);
   $self->set_fields ('proceedings',
                      [qw(title year)],
                      [qw(editor series address month 
                          organization publisher note)],
                      [0, 1, [qw(volume number)]]);
   $self->set_fields ('techreport',
                      [qw(author title institution year)],
                      [qw(type number address month note)]);
   $self->set_fields ('unpublished',
                      [qw(author title note)],
                      [qw(month year)]);

}  # describe_entry


=head1 STRUCTURED ENTRY CLASS

The second class provided by the C<Text::BibTeX::Bib> module is
C<BibEntry> (again, a leading C<Text::BibTeX> is implied).  This being a
structured entry class, it derives from C<StructuredEntry>.  The
conventions and requirements for such a class are documented in
L<Text::BibTeX::Structure> for the benefit of programmers implementing
their own structure modules.

If you wish to write utilities making use of the C<Bib> database
structure, then you should call one of the "officially supported"
methods provided by the C<BibEntry> class.  Currently, there are only
two of these: C<sort_key> and C<format>.  These are actually implemented
in the C<BibSort> and C<BibFormat> classes, respectively, which are base
classes of C<BibEntry>.  Thus, see L<Text::BibTeX::BibSort> and
L<Text::BibTeX::BibFormat> for details on these two methods.

=cut

package Text::BibTeX::BibEntry;
use strict;
use vars qw(@ISA $VERSION);

$VERSION = '0.88';

use Text::BibTeX::BibSort;
use Text::BibTeX::BibFormat;

@ISA = qw(Text::BibTeX::BibSort Text::BibTeX::BibFormat);
 

1;

=head1 SEE ALSO

L<Text::BibTeX::Structure>, L<Text::BibTeX::BibSort>, 
L<Text::BibTeX::BibFormat>.

=head1 AUTHOR

Greg Ward <gward@python.net>

=head1 COPYRIGHT

Copyright (c) 1997-2000 by Gregory P. Ward.  All rights reserved.  This file
is part of the Text::BibTeX library.  This library is free software; you
may redistribute it and/or modify it under the same terms as Perl itself.
