# ----------------------------------------------------------------------
# NAME       : Text::BibTeX::Value
# CLASSES    : Text::BibTeX::Value, Text::BibTeX::SimpleValue
# RELATIONS  : 
# DESCRIPTION: Provides interfaces to BibTeX values (list of simple
#              values) and simple values (string/macro/number).
# CREATED    : 1998/03/12, Greg Ward
# MODIFIED   : 
# VERSION    : $Id$
# COPYRIGHT  : Copyright (c) 1997-2000 by Gregory P. Ward.  All rights
#              reserved.
# 
#              This file is part of the Text::BibTeX library.  This
#              library is free software; you may redistribute it and/or
#              modify it under the same terms as Perl itself.
# ----------------------------------------------------------------------

package Text::BibTeX::Value;

use strict;
use Scalar::Util 'blessed';
use Carp;

use vars qw'$VERSION';
$VERSION = 0.88;

=head1 NAME

Text::BibTeX::Value - interfaces to BibTeX values and simple values

=head1 SYNOPSIS

   use Text::BibTeX;

   $entry = Text::BibTeX::Entry->new;

   # set the 'preserve_values' flag to 1 for this parse
   $entry->parse ($filename, $filehandle, 1);

   # 'get' method now returns a Text::BibTeX::Value object 
   # rather than a string
   $value = $entry->get ($field);

   # query the `Value' object (list of SimpleValue objects)
   @all_values = $value->values;
   $first_value = $value->value (0);
   $last_value = $value->value (-1);

   # query the simple value objects -- type will be one of BTAST_STRING,
   # BTAST_MACRO, or BTAST_NUMBER
   use Text::BibTex (':nodetypes');   # import "node type" constants
   $is_macro = ($first_value->type == BTAST_MACRO);
   $text = $first_value->text;

=head1 DESCRIPTION

The C<Text::BibTeX::Value> module provides two classes,
C<Text::BibTeX::Value> and C<Text::BibTeX::SimpleValue>, which respectively
give you access to BibTeX "compound values" and "simple values".  Recall
that every field value in a BibTeX entry is the concatenation of one or
more simple values, and that each of those simple values may be a literal
string, a macro (abbreviation), or a number.  Normally with
C<Text::BibTeX>, field values are "fully processed," so that you only have
access to the string that results from expanding macros, converting numbers
to strings, concatenating all sub-strings, and collapsing whitespace in the
resulting string.

For example, in the following entry:

   @article{homer97,
     author = "Homer Simpson" # and # "Ned Flanders",
     title = {Territorial Imperatives in Modern Suburbia},
     journal = jss,
     year = 1997
   }

we see the full range of options.  The C<author> field consists of three
simple values: a string, a macro (C<and>), and another string.  The
C<title> field is a single string, and the C<journal> and C<year> fields
are, respectively, a single macro and a single number.  If you parse
this entry in the usual way:

   $entry = Text::BibTeX::Entry->new($entry_text);

then the C<get> method on C<$entry> would return simple strings.
Assuming that the C<and> macro is defined as C<" and ">, then

   $entry->get ('author')

would return the Perl string C<"Homer Simpson and Ned Flanders">.

However, you can also request that the library preserve the input values
in your entries, i.e. not lose the information about which values use
macros, which values are composed of multiple simple values, and so on.
There are two ways to make this request: per-file and per-entry.  For a
per-file request, use the C<preserve_values> method on your C<File>
object:

   $bibfile = Text::BibTeX::File->new($filename);
   $bibfile->preserve_values (1);

   $entry = Text::BibTeX::Entry->new($bibfile);
   $entry->get ($field);        # returns a Value object

   $bibfile->preserve_values (0);
   $entry = Text::BibTeX::Entry->new($bibfile);
   $entry->get ($field);        # returns a string

If you're not using a C<File> object, or want to control things at a
finer scale, then you have to pass in the C<preserve_values> flag when
invoking C<read>, C<parse>, or C<parse_s> on your C<Entry> objects:

   # no File object, parsing from a string
   $entry = Text::BibTeX::Entry->new;
   $entry->parse_s ($entry_text, 0);  # preserve_values=0 (default)
   $entry->get ($field);        # returns a string

   $entry->parse_s ($entry_text, 1);
   $entry->get ($field);        # returns a Value object

   # using a File object, but want finer control
   $entry->read ($bibfile, 0);  # now get will return strings (default)
   $entry->read ($bibfile, 1);  # now get will return Value objects
   
A compound value, usually just called a value, is simply a list of
simple values.  The C<Text::BibTeX::Value> class (hereinafter
abbreviated as C<Value>) provides a simple interface to this list; you
can request the whole list, or an individual member of the list.  The
C<SimpleValue> class gives you access to the innards of each simple
value, which consist of the I<type> and the I<text>.  The type just
tells you if this simple value is a string, macro, or number; it is
represented using the Perl translation of the "node type" enumeration
from C.  The possible types are C<BTAST_STRING>, C<BTAST_NUMBER>, and
C<BTAST_MACRO>.  The text is just what appears in the original entry
text, be it a string, number, or macro.

For example, we could parse the above entry in "preserve values" mode as
follows:

   $entry->parse_s ($entry_text, 1);   # preserve_values is 1

Then, using the C<get> method on C<$entry> would return not a string,
but a C<Value> object.  We can get the list of all simple values using
the C<values> method, or a single value using C<value>:

   $author = $entry->get ('author');   # now a Text::BibTeX::Value object
   @all_values = $author->values;      # array of Text::BibTeX::SimpleValue
   $second = $author->value (1);       # same as $all_values[1]

The simple values may be queried using the C<Text::BibTeX::SimpleValue>
methods, C<type> and C<text>:

   $all_values[0]->type;               # returns BTAST_STRING
   $second->type;                      # returns BTAST_MACRO

   $all_values[0]->text;               # "Homer Simpson"
   $second->text;                      # "and" (NOT the macro expansion!)

   $entry->get ('year')->value (0)->text;   # "1997"

=head1 METHODS

Normally, you won't need to create C<Value> or C<SimpleValue>
objects---they'll be created for you when an entry is parsed, and
returned to you by the C<get> method in the C<Entry> class.  Thus, the
query methods (C<values> and C<value> for the C<Value> class, C<type>
and C<text> for C<SimpleValue>) are probably all you need to worry
about.  If you wish, though, you can create new values and simple values
using the two classes' respective constructors.  You can also put
newly-created C<Value> objects back into an existing C<Entry> object
using the C<set> entry method; it doesn't matter how the entry was
parsed, this is acceptable anytime.

=head2 Text::BibTeX::Value methods

=over 4

=item new (SVAL, ...)

Creates a new C<Value> object from a list of simple values.  Each simple
value, SVAL, may be either a C<SimpleValue> object or a reference to a
two-element list containing the type and text of the simple value.  For
example, one way to recreate the C<author> field of the example entry in
L<"DESCRIPTION"> would be:

   $and_macro = Text::BibTeX::SimpleValue->new (BTAST_MACRO, 'and');
   $value = Text::BibTeX::Value->new 
      ([BTAST_STRING, 'Homer Simpson'],
       $and_macro,
       [BTAST_STRING, 'Ned Flanders']);

The resulting C<Value> object could then be installed into an entry
using the C<set> method of the C<Entry> class.

=cut

sub new
{
   my $class = shift;

   $class = ref $class || $class;
   my $self = bless [], $class;
   while (my $sval = shift)
   {
      $sval = Text::BibTeX::SimpleValue->new(@$sval)
         if ref $sval eq 'ARRAY' && @$sval == 2;
      croak "simple value is neither a two-element array ref " .
            "nor a Text::BibTeX::SimpleValue object"
         unless blessed($sval) && $sval->isa('Text::BibTeX::SimpleValue');
      push (@$self, $sval);
   }

   $self;
}

=item values ()

Returns the list of C<SimpleValue> objects that make up a C<Value> object.

=item value (NUM)

Returns the NUM'th C<SimpleValue> object from the list of C<SimpleValue>
objects that make up a C<Value> object.  This is just like a Perl array
reference: NUM is zero-based, and negative numbers count from the end of
the array.

=back

=cut

# A Text::BibTeX::Value object is just an array ref; that array is a list
# of Text::BibTeX::SimpleValue objects.  Most of the real work for Value
# and SimpleValue is done behind the scenes when an entry is parsed, in
# BibTeX.xs and btxs_support.c.

sub values { @{$_[0]} }

sub value { $_[0]->[$_[1]] }


package Text::BibTeX::SimpleValue;

use strict;
use Carp;
use Text::BibTeX qw(:nodetypes);

use vars qw($VERSION);
$VERSION = '0.88';


=head2 Text::BibTeX::SimpleValue methods

=over

=item new (TYPE, TEXT)

Creates a new C<SimpleValue> object with the specified TYPE and TEXT.
TYPE must be one of the allowed types for BibTeX simple values,
i.e. C<BTAST_STRING>, C<BTAST_NUMBER>, or C<BTAST_MACRO>.  You'll
probably want to import these constants from C<Text::BibTeX> using the
C<nodetypes> export tag:

   use Text::BibTeX qw(:nodetypes);

TEXT may be any string.  Note that if TYPE is C<BTAST_NUMBER> and TEXT
is not a string of digits, the C<SimpleValue> object will be created
anyways, but a warning will be issued.  No warning is issued about
non-existent macros.

=cut

sub new
{
   my ($class, $type, $text) = @_;

   croak "invalid simple value type ($type)"
      unless ($type == &BTAST_STRING ||
              $type == &BTAST_NUMBER ||
              $type == &BTAST_MACRO);
   croak "invalid simple value text (must be a simple string or number)"
      unless defined $text && ! ref $text;
   carp "warning: creating a 'number' simple value with non-numeric text"
      if $type == &BTAST_NUMBER && $text !~ /^\d+$/;

   $class = ref $class || $class;
   my $self = bless [undef, undef], $class;
   $self->[0] = $type;
   $self->[1] = $text;
   $self;
}


=item type ()

Returns the type of a simple value.  This will be one of the allowed
"node types" as described under L</new> above.

=item text ()

Returns the text of a simple value.  This is just the text that appears
in the original entry---unexpanded macro name, or unconverted number.
(Of course, converting numbers doesn't make any difference from Perl; in
fact, it's all the same in C too, since the C code just keeps numbers as
strings of digits.  It's simply a matter of whether the string of digits
is represented as a string or a number, which you might be interested in
knowing if you want to preserve the structure of the input as much
possible.)

=back

=cut

sub type { shift->[0] }

sub text { shift->[1] }

1;

=head1 SEE ALSO

L<Text::BibTeX>, L<Text::BibTeX::File>, L<Text::BibTeX::Entry>

=head1 AUTHOR

Greg Ward <gward@python.net>

=head1 COPYRIGHT

Copyright (c) 1997-2000 by Gregory P. Ward.  All rights reserved.  This file
is part of the Text::BibTeX library.  This library is free software; you
may redistribute it and/or modify it under the same terms as Perl itself.

=cut
