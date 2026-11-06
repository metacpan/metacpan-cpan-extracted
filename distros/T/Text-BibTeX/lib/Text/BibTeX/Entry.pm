# ----------------------------------------------------------------------
# NAME       : BibTeX/Entry.pm
# CLASSES    : Text::BibTeX::Entry
# RELATIONS  : base class for Text::BibTeX::StructuredEntry, and 
#              ultimately for all user-supplied structured entry classes
# DESCRIPTION: Provides an object-oriented interface to BibTeX entries.
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
package Text::BibTeX::Entry;

use 5.026;
use strict;
use warnings;
use Carp;
use Scalar::Util qw(blessed refaddr);
use Symbol ();
use Text::BibTeX qw(:metatypes :nodetypes);

our $VERSION = '1.00';

=head1 NAME

Text::BibTeX::Entry - read and parse BibTeX files

=head1 SYNOPSIS

   use Text::BibTeX::Entry;

   # ...assuming that $bibfile and $newbib are both objects of class
   # Text::BibTeX::File, opened for reading and writing (respectively):

   # Entry creation/parsing methods:
   $entry = Text::BibTeX::Entry->new();
   $entry->read ($bibfile);
   $entry->parse ($filename, $filehandle);
   $entry->parse_s ($entry_text);

   # or:
   $entry = Text::BibTeX::Entry->new( $bibfile );
   $entry = Text::BibTeX::Entry->new( $filename, $filehandle );
   $entry = Text::BibTeX::Entry->new( $entry_text );
   
   # Entry query methods
   warn "error in input" unless $entry->parse_ok;
   $metatype = $entry->metatype;
   $type = $entry->type;

   # if metatype is BTE_REGULAR or BTE_MACRODEF:
   $key = $entry->key;                  # only for BTE_REGULAR metatype
   $num_fields = $entry->num_fields;
   @fieldlist = $entry->fieldlist;
   $has_title = $entry->exists ('title');
   $title = $entry->get ('title');
   # or:
   ($val1,$val2,...$valn) = $entry->get ($field1, $field2, ..., $fieldn);

   # if metatype is BTE_COMMENT or BTE_PREAMBLE:
   $value = $entry->value;

   # Author name methods 
   @authors = $entry->split ('author');
   ($first_author) = $entry->names ('author');

   # Entry modification methods
   $entry->set_type ($new_type);
   $entry->set_key ($new_key);
   $entry->set ('title', $new_title);
   # or:
   $entry->set ($field1, $val1, $field2, $val2, ..., $fieldn, $valn);
   $entry->delete (@fields);
   $entry->set_fieldlist (\@fieldlist);

   # Entry output methods
   $entry->write ($newbib);
   $entry->print ($filehandle);
   $entry_text = $entry->print_s;

   # Reset internal parser state:
   $entry = Text::BibTeX::Entry->new();
   $entry->parse ($filename, undef);
   $entry->parse_s (undef);

   # or:
   $entry = Text::BibTeX::Entry->new( $filename, undef );
   $entry = Text::BibTeX::Entry->new( undef );

   # Miscellaneous methods
   $entry->warn ($entry_warning);
   # or:
   $entry->warn ($field_warning, $field);
   $entry->clone;

=head1 DESCRIPTION

C<Text::BibTeX::Entry> does all the real work of reading and parsing
BibTeX files.  (Well, actually it just provides an object-oriented Perl
front-end to a C library that does all that.  But that's not important
right now.)

BibTeX entries can be read either from C<Text::BibTeX::File> objects (using
the C<read> method), or directly from a filehandle (using the C<parse>
method), or from a string (using C<parse_s>).  The first is preferable,
since you don't have to worry about supplying the filename, and because of
the extra functionality provided by the C<Text::BibTeX::File> class.
Currently, this means that you may specify the I<database structure> to
which entries are expected to conform via the C<File> class.  This lets you
ensure that entries follow the rules for required fields and mutually
constrained fields for a particular type of database, and also gives you
access to all the methods of the I<structured entry class> for this
database structure.  See L<Text::BibTeX::Structure> for details on database
structures.

Once you have the entry, you can query it or change it in a variety of
ways.  The query methods are C<parse_ok>, C<type>, C<key>, C<num_fields>,
C<fieldlist>, C<exists>, and C<get>.  Methods for changing the entry are
C<set_type>, C<set_key>, C<set_fieldlist>, C<delete>, and C<set>.

Finally, you can output BibTeX entries, again either to an open
C<Text::BibTeX::File> object, a filehandle or a string.  (A filehandle or
C<File> object must, of course, have been opened in write mode.)  Output to
a C<File> object is done with the C<write> method, to a filehandle via
C<print>, and to a string with C<print_s>.  Using the C<File> class is
recommended for future extensibility, although it currently doesn't offer
anything extra.

=head1 METHODS

=head2 Entry creation/parsing methods

=over 4

=item new ([OPTS ,] [SOURCE])

Creates a new C<Text::BibTeX::Entry> object.  If the SOURCE parameter is
supplied, it must be one of the following: a C<Text::BibTeX::File> (or
descendant class) object, a filename/filehandle pair, or a string.  Calls
C<read> to read from a C<Text::BibTeX::File> object, C<parse> to read from
a filehandle, and C<parse_s> to read from a string.

A filehandle can be specified as a GLOB reference, or as an
C<IO::Handle> (or descendants) object, or as a C<FileHandle> (or
descendants) object.  (But there's really no point in using
C<FileHandle> objects, since C<Text::BibTeX> requires Perl 5.004, which
always includes the C<IO> modules.)  You can I<not> pass in the name of
a filehandle as a string, though, because C<Text::BibTeX::Entry>
conforms to the C<use strict> pragma (which disallows such symbolic
references).

The corresponding filename should be supplied in order to allow for
accurate error messages; if you simply don't have the filename, you can
pass C<undef> and you'll get error messages without a filename.  (It's
probably better to rearrange your code so that the filename is
available, though.)

Thus, the following are equivalent to read from a file named by
C<$filename> (error handling ignored):

   # good ol' fashioned filehandle and GLOB ref
   open (BIBFILE, $filename);
   $entry = Text::BibTeX::Entry->new($filename, \*BIBFILE);

   # newfangled IO::File thingy
   $file = IO::File->new($filename);
   $entry = Text::BibTeX::Entry->new($filename, $file);

But using a C<Text::BibTeX::File> object is simpler and preferred:

   $file  = Text::BibTeX::File->new($filename);
   $entry = Text::BibTeX::Entry->new($file);

Returns the new object, unless SOURCE is supplied and reading/parsing
the entry fails (e.g., due to end of file) -- then it returns false.

You may supply a reference to an option hash as first argument.
Supported options are:

=over 4 

=item BINMODE

Set the way Text::BibTeX deals with strings: C<'utf-8'> (the default)
to get Perl character strings, or C<'bytes'> to get byte strings exactly
as they appear in the input.  See L<Text::BibTeX/"STRINGS AND UNICODE">.
When reading from a C<Text::BibTeX::File>, the file's setting is used
unless you give one here.

   Text::BibTeX::Entry->new(
         { binmode => 'utf-8', normalization => 'NFD' },
         $file);

=item NORMALIZATION

The Unicode normalization form for strings in C<'utf-8'> mode: C<'NFC'>
(the default), C<'NFD'>, C<'NFKC'>, C<'NFKD'> or C<'none'>.

=back


=cut

sub new
{
   my ($class, @source) = @_;
   $class = ref ($class) || $class;

   my $self = {'file'     => undef,
               'type'     => undef,
               'key'      => undef,
               'status'   => undef,
               'metatype' => undef,
               'fields'   => [],
               'values'   => {},
               'errors'   => []};
   bless $self, $class;

   my $opts;
   $opts = shift @source if scalar(@source) and ref $source[0] eq "HASH";
   if ($opts) {
      @{$self}{qw(binmode normalization)} = Text::BibTeX::_options($opts);
   }

   if (@source)
   {
      my $status;

      if (@source == 1 && blessed($source[0]) && $source[0]->isa ('Text::BibTeX::File'))
      {
         my $file = $source[0];
         $status = $self->read ($file);
         if (my $structure = $file->structure)
         {
            $self->{structure} = $structure;
            bless $self, $structure->entry_class;
         }
      }
      elsif (@source == 2 && (defined ($source[0]) && ! ref ($source[0])))
          { $status = $self->parse ($source[0], $source[1]) }
      elsif (@source == 1 && ! ref ($source[0]))
          { $status = $self->parse_s ($source[0]) }
      else
          { croak "new: source argument must be either a Text::BibTeX::File " .
                  "(or descendant) object, filename/filehandle pair, or " .
                  "a string"; }

      return $status unless $status;    # parse failed -- tell our caller
   }
   $self;
}

# String conversion options for this entry
sub _binmode { $_[0]{binmode} // 'utf-8' }
sub _norm    { $_[0]{normalization} // 'NFC' }
sub _in      { Text::BibTeX::_in($_[0]->_binmode, $_[0]->_norm, $_[1]) }

=item clone

Clone a Text::BibTeX::Entry object, returning the clone. This re-uses the reference to any
Text::BibTeX::Structure or Text::BibTeX::File but copies everything else,
so that the clone can be modified apart from the original.

=cut

sub clone
{
  my $self = shift;
  my $clone = {};

  # Use the same structure object - won't be changed
  if ($self->{structure}) {
    $clone->{structure} = $self->{structure};
  }

  # Use the same file object - won't be changed
  if ($self->{file}) {
    $clone->{file} = $self->{file}
  }

  # These might be changed so make copies
  $clone->{binmode} = $self->{binmode};
  $clone->{normalization} = $self->{normalization};
  $clone->{type}     = $self->{type};
  $clone->{key}      = $self->{key};
  $clone->{status}   = $self->{status};
  $clone->{metatype} = $self->{metatype};
  $clone->{value}    = $self->{value} if exists $self->{value};
  $clone->{fields}   = [ @{$self->{fields}} ];
  $clone->{values}   = { %{$self->{values}} };
  $clone->{lines}    = { %{$self->{lines} || {}} };
  $clone->{errors}   = [ @{$self->{errors} || []} ];

  bless $clone, ref($self);
  return $clone;
}

=item read (BIBFILE)

Reads and parses an entry from BIBFILE, which must be a
C<Text::BibTeX::File> object (or descendant).  The next entry will be read
from the file associated with that object.

Returns the same as C<parse> (or C<parse_s>): false if no entry found
(e.g., at end-of-file), true otherwise.  To see if the parse itself failed
(due to errors in the input), call the C<parse_ok> method.

=cut

sub read
{
   my ($self, $source, $preserve) = @_;
   croak "`source' argument must be ref to open Text::BibTeX::File " .
         "(or descendant) object"
      unless (blessed($source) && $source->isa('Text::BibTeX::File'));

   $self->{'file'} = $source;        # store File object for later use
   ## Propagate flags
   for my $f (qw.binmode normalization.) {
      $self->{$f} = $source->{$f} unless defined $self->{$f};
   }
   $preserve = $self->_preserve ($preserve) ? 1 : 0;
   return $self->_finish(_parse ($self, $source->_parser, $preserve));
}


=item parse (FILENAME, FILEHANDLE)

Reads and parses the next entry from FILEHANDLE.  (That is, it scans the
input until an '@' sign is seen, and then slurps up to the next '@'
sign.  Everything between the two '@' signs [including the first one,
but not the second one -- it's pushed back onto the input stream for the
next entry] is parsed as a BibTeX entry, with the simultaneous
construction of an abstract syntax tree [AST].  The AST is traversed to
ferret out the most interesting information, and this is stuffed into a
Perl hash, which coincidentally is the C<Text::BibTeX::Entry> object
you've been tossing around.  But you don't need to know any of that -- I
just figured if you've read this far, you might want to know something
about the inner workings of this module.)

The success of the parse is stored internally so that you can later
query it with the C<parse_ok> method.  Even in the presence of syntax
errors, you'll usually get something resembling your input, but it's
usually not wise to try to do anything with it.  Just call C<parse_ok>,
and if it returns false then silently skip to the next entry.  The error
messages should be quite adequate for the user to figure out what's
wrong; they are reported with Perl's C<warn> (so they can be caught or
redirected like any other warning), and are also available from the
C<errors> method.  See L<Text::BibTeX::Error>.

If no '@' signs are seen on the input before reaching end-of-file, then
we've exhausted all the entries in the file, and C<parse> returns a
false value.  Otherwise, it returns a true value -- even if there were
syntax errors.  Hence, it's important to check C<parse_ok>.

The FILENAME parameter is only used for generating error messages, but
anybody using your program will certainly appreciate your setting it
correctly!

FILEHANDLE may be any Perl filehandle, including in-memory and tied
handles.  The parser reads ahead in the file, so don't read from the
handle yourself in between calls.  Passing C<undef> as FILEHANDLE
forgets about all the filehandles C<parse> has been reading from.  (It
is usually simpler to use a C<Text::BibTeX::File> object and the C<read>
method.)

=item parse_s (TEXT)

Parses a BibTeX entry (using the above rules) from the string TEXT.  The
string is not modified; repeatedly calling C<parse_s> with the same string
will give you the same results each time.  Thus, there's no point in
putting multiple entries in one string.

Passing C<undef> to TEXT will reset the state of the underlying
C parser, which may be required in order to parse multiple strings.

=back

=cut

sub _preserve
{
   my ($self, $preserve) = @_;

   $preserve = $self->{'file'}->preserve_values
      if ! defined $preserve && 
         defined $self->{'file'} &&
           $self->{'file'}->isa ('Text::BibTeX::File');
   require Text::BibTeX::Value if $preserve;
   $preserve;
}

# Parsers for raw filehandles passed to parse(), keyed on the handle
my %Parsers;

sub parse
{
   my ($self, $filename, $filehandle, $preserve) = @_;

   if (!defined $filehandle) {          # reset (forget) all parsers
      %Parsers = ();
      return;
   }

   my $handle = ref $filehandle ? $filehandle : \*{ Symbol::qualify($filehandle, caller) };
   $preserve = $self->_preserve ($preserve) ? 1 : 0;
   my $id = refaddr $handle;
   my $parser = $Parsers{$id} //= Text::BibTeX::Parser->new(
       $handle, $filename, $self->_binmode eq 'utf-8' ? 1 : 0, 0);
   my $found = _parse ($self, $parser, $preserve);
   delete $Parsers{$id} unless $found;  # at end of file
   return $self->_finish($found);
}


sub parse_s
{
   my ($self, $text, $preserve) = @_;

   return unless defined $text;
   $preserve = $self->_preserve ($preserve) ? 1 : 0;
   if ($self->_binmode eq 'utf-8') {
      if (!utf8::is_utf8($text) && $text =~ /[^\x00-\x7f]/) {
         my $c = $text;
         $text = $c if utf8::decode($c);
      }
   }
   else {
      $text = Text::BibTeX::_to_c('bytes', 'none', $text);
   }
   return $self->_finish(_parse_s ($self, $text, $preserve,
                                   $self->_binmode eq 'utf-8' ? 1 : 0));
}

# After parsing: put the entry's strings into normal form
sub _finish
{
   my ($self, $found) = @_;
   return $found unless $found;
   my $norm = $self->_norm;
   return $found if $self->_binmode ne 'utf-8' || $norm eq 'none';

   my $n = sub { Text::BibTeX::_normalise($norm, $_[0]) };
   for my $k (qw(type key)) {
      $self->{$k} = $n->($self->{$k}) if defined $self->{$k};
   }
   my $fix_value = sub {
      my $v = shift;
      return $n->($v) unless ref $v;
      $_->[1] = $n->($_->[1]) for $v->values;
      return $v;
   };
   if (exists $self->{value}) {
      $self->{value} = $fix_value->($self->{value});
   }
   if (grep { /[^\x00-\x7f]/ } @{$self->{fields}}) {
      my (%values, %lines);
      for my $f (@{$self->{fields}}) {
         my $nf = $n->($f);
         $values{$nf} = $self->{values}{$f};
         $lines{$nf} = $self->{lines}{$f};
         $f = $nf;
      }
      $lines{$_} = $self->{lines}{$_} for qw(START STOP);
      $self->{values} = \%values;
      $self->{lines} = \%lines;
   }
   $_ = $fix_value->($_) for values %{$self->{values}};
   return $found;
}


=head2 Entry query methods

=over 4

=item parse_ok ()

Returns false if there were any serious errors encountered while parsing
the entry.  (A "serious" error is a lexical or syntax error; warnings,
such as "undefined macro", don't count.)

=item errors ()

Returns the list of L<Text::BibTeX::Error> objects for all the problems
-- serious or not -- found while the entry was parsed (including any
"junk" found before it in the file).

=item type ()

Returns the type of the entry.  (The `type' is the word that follows the
'@' sign; e.g. `article', `book', `inproceedings', etc. for the standard
BibTeX styles.)

=item metatype ()

Returns the metatype of the entry.  (The `metatype' is a numeric value used
to classify entry types into four groups: comment, preamble, macro
definition (C<@string> entries), and regular (all other entry types).
C<Text::BibTeX> exports four constants for these metatypes: C<BTE_COMMENT>,
C<BTE_PREAMBLE>, C<BTE_MACRODEF>, and C<BTE_REGULAR>.)

=item key ()

Returns the key of the entry.  (The key is the token immediately
following the opening `{' or `(' in "regular" entries.  Returns C<undef>
for entries that don't have a key, such as macro definition (C<@string>)
entries.)

=item num_fields ()

Returns the number of fields in the entry.  (Note that, currently, this is
I<not> equivalent to putting C<scalar> in front of a call to C<fieldlist>.
See below for the consequences of calling C<fieldlist> in a scalar
context.)

=item fieldlist ()

Returns the list of fields in the entry.  

B<WARNING> In scalar context, it no longer returns a
reference to the object's own list of fields.

=cut

sub parse_ok   { shift->{'status'}; }

sub metatype   { shift->{'metatype'} }

sub type       { shift->{'type'} }

sub key        { shift->{'key'} }

sub num_fields { scalar @{shift->{'fields'}}; }

sub fieldlist  { @{shift->{'fields'}} }
  
=item exists (FIELD)

Returns true if a field named FIELD is present in the entry, false
otherwise.  

=item get (FIELD, ...)

Returns the value of one or more FIELDs, as a list of values.  For example:

   $author = $entry->get ('author');
   ($author, $editor) = $entry->get ('author', 'editor');

If a FIELD is not present in the entry, C<undef> will be returned at its
place in the return list.  However, you can't completely trust this as a
test for presence or absence of a field; it is possible for a field to be
present but undefined.  Currently this can only happen due to certain
syntax errors in the input, or if you pass an undefined value to C<set>, or
if you create a new field with C<set_fieldlist> (the new field's value is
implicitly set to C<undef>).

Normally, the field value is what the input looks like after "maximal
processing"--quote characters are removed, whitespace is collapsed (the
same way that BibTeX itself does it), macros are expanded, and multiple
tokens are pasted together.  (See L<Text::BibTeX::Value/POST-PROCESSING>
for details.)

For example, if your input file has the following:

   @string{of = "of"}
   @string{foobars = "Foobars"}

   @article{foobar,
     title = {   The Mating Habits      } # of # " Adult   " # foobars
   }

then using C<get> to query the value of the C<title> field from the
C<foobar> entry would give the string "The Mating Habits of Adult Foobars".

However, in certain circumstances you may wish to preserve the values as
they appear in the input.  This is done by setting a C<preserve_values>
flag at some point; then, C<get> will return not strings but
C<Text::BibTeX::Value> objects.  Each C<Value> object is a list of
C<Text::BibTeX::SimpleValue> objects, which in turn consists of a simple
value type (string, macro, or number) and the text of the simple value.
Various ways to set the C<preserve_values> flag and the interface to
both C<Value> and C<SimpleValue> objects are described in
L<Text::BibTeX::Value>.

=item value ()

Returns the single string associated with C<@comment> and C<@preamble>
entries.  For instance, the entry

   @preamble{" This is   a preamble" # 
             {---the concatenation of several strings}}

would return a value of "This is a preamble---the concatenation of
several strings".

If this entry was parsed in "value preservation" mode, then C<value>
acts like C<get>, and returns a C<Value> object rather than a simple
string.

=back

=cut

sub exists
{
   my ($self, $field) = @_;
   exists $self->{values}{$self->_in($field)};
}

sub get
{
   my ($self, @fields) = @_;
   my @x = @{$self->{'values'}}{map { $self->_in($_) } @fields};
   return (@x > 1) ? @x : $x[0];
}

sub value      { shift->{'value'} }

sub errors     { @{shift->{'errors'} || []} }


=head2 Author name methods

This is the only part of the module that makes any assumption about the
nature of the data, namely that certain fields are lists delimited by a
simple word such as "and", and that the delimited sub-strings are human
names of the "First von Last" or "von Last, Jr., First" style used by
BibTeX.  If you are using this module for anything other than
bibliographic data, you can most likely forget about these two methods.
However, if you are in fact hacking on BibTeX-style bibliographic data,
these could come in very handy -- the name-parsing done by BibTeX is not
trivial, and the list-splitting would also be a pain to implement in
Perl because you have to pay attention to brace-depth.  (Not that it
wasn't a pain to implement in C -- it's just a lot more efficient than a
Perl implementation would be.)

Incidentally, both of these methods assume that the strings being split
have already been "collapsed" in the BibTeX way, i.e. all leading and
trailing whitespace removed and internal whitespace reduced to single
spaces.  This should always be the case when using these two methods on
a C<Text::BibTeX::Entry> object, but these are actually just front ends
to more general functions in C<Text::BibTeX>.  (More general in that you
supply the string to be parsed, rather than supplying the name of an
entry field.)  Should you ever use those more general functions
directly, you might have to worry about collapsing whitespace; see
L<Text::BibTeX> (the C<split_list> and C<split_name> functions in
particular) for more information.

Please note that the interface to author name parsing is experimental,
subject to change, and open to discussion.  Please let me know if you
have problems with it, think it's just perfect, or whatever.

=over 4

=item split (FIELD [, DELIM [, DESC]])

Splits the value of FIELD on DELIM (default: `and').  Don't assume that
this works the same as Perl's builtin C<split> just because the names are
the same: in particular, DELIM must be a simple string (no regexps), and
delimiters that are at the beginning or end of the string, or at non-zero
brace depth, or not surrounded by whitespace, are ignored.  Some examples
might illuminate matters:

   if field F is...                then split (F) returns...
   'Name1 and Name2'               ('Name1', 'Name2')
   'Name1 and and Name2'           ('Name1', undef, 'Name2')
   'Name1 and'                     ('Name1 and')
   'and Name2'                     ('and Name2')
   'Name1 {and} Name2 and Name3'   ('Name1 {and} Name2', 'Name3')
   '{Name1 and Name2} and Name3'   ('{Name1 and Name2}', 'Name3')

Note that a warning will be issued for empty names (as in the second
example above).  A warning ought to be issued for delimiters at the
beginning or end of a string, but currently this isn't done.  (Hmmm.)

DESC is a one-word description of the substrings; it defaults to 'name'.
It is only used for generating warning messages.

=item names (FIELD)

Splits FIELD as described above, and further splits each name into four
components: first, von, last, and jr.  

Returns a list of C<Text::BibTeX::Name> objects, each of which represents
one name.  Use the C<part> method to query these objects; see
L<Text::BibTeX::Name> for details on the interface to name objects (and on
name-parsing as well).

For example if this entry:

   @article{foo,
            author = {John Smith and 
                      Hacker, J. Random and
                      Ludwig van Beethoven and
                      {Foo, Bar and Company}}}

has been parsed into a C<Text::BibTeX::Entry> object C<$entry>, then

   @names = $entry->names ('author');

will put a list of C<Text::BibTeX::Name> objects in C<@names>.  These can
be queried individually as described in L<Text::BibTeX::Name>; for instance,

   @last = $names[0]->part ('last');

would put the list of tokens comprising the last name of the first author
into the C<@last> array: C<('Smith')>.

=cut

sub split
{
   my ($self, $field, $delim, $desc) = @_;

   return unless $self->exists($field);
   $field = $self->_in($field);
   $delim ||= 'and';
   $desc ||= 'name';

   Text::BibTeX::split_list($self->{values}{$field},
                            $delim,
                            ($self->{file} && $self->{file}{filename}),
                            $self->{lines}{$field},
                            $desc,
                            {binmode       => $self->_binmode,
                             normalization => $self->_norm});
}

sub names
{
   require Text::BibTeX::Name;

   my ($self, $field) = @_;
   my (@names, $i);

   my $filename = ($self->{'file'} && $self->{'file'}{'filename'});
   my $line = $self->{'lines'}{$self->_in($field)};

   @names = $self->split ($field);
   for $i (0 .. $#names)
   {
      # an empty name (eg. from "and and") becomes an empty Name object
      $names[$i] = Text::BibTeX::Name->new(
        {binmode => $self->_binmode, normalization => $self->_norm},
        $names[$i] // '', $filename, $line, $i + 1);
   }
   @names;
}

=back

=head2 Entry modification methods

=over 4

=item set_type (TYPE)

Sets the entry's type.

=item set_metatype (METATYPE)

Sets the entry's metatype (must be one of the four constants
C<BTE_COMMENT>, C<BTE_PREAMBLE>, C<BTE_MACRODEF>, and C<BTE_REGULAR>, which
are all optionally exported from C<Text::BibTeX>).

=item set_key (KEY)

Sets the entry's key.

=item set (FIELD, VALUE, ...)

Sets the value of field FIELD.  (VALUE might be C<undef> or unsupplied,
in which case FIELD will simply be set to C<undef> -- this is where the
difference between the C<exists> method and testing the definedness of
field values becomes clear.)

Multiple (FIELD, VALUE) pairs may be supplied; they will be processed in
order (i.e. the input is treated like a list, not a hash).  For example:

   $entry->set ('author', $author);
   $entry->set ('author', $author, 'editor', $editor);

VALUE can be either a simple string or a C<Text::BibTeX::Value> object;
it doesn't matter if the entry was parsed in "full post-processing" or
"preserve input values" mode.

=item delete (FIELD)

Deletes field FIELD from an entry.

=item set_fieldlist (FIELDLIST)

Sets the entry's list of fields to FIELDLIST, which must be a list
reference.  If any of the field names supplied in FIELDLIST are not
currently present in the entry, they are created with the value C<undef>
and a warning is printed.  Conversely, if any of the fields currently
present in the entry are not named in the list of fields supplied to
C<set_fields>, they are deleted from the entry and another warning is
printed.

=back

=cut

sub set_type
{
   my ($self, $type) = @_;

   $self->{'type'} = $self->_in($type);
}

sub set_metatype
{
   my ($self, $metatype) = @_;

   $self->{'metatype'} = $metatype;
}   

sub set_key
{
   my ($self, $key) = @_;

   $self->{'key'} = $self->_in($key);
}

sub set
{
   my $self = shift;
   croak "set: must supply an even number of arguments"
      unless (@_ % 2 == 0);
   my ($field, $value);

   while (@_)
   {
      ($field,$value) = ($self->_in(shift), $self->_in(shift));
      push (@{$self->{'fields'}}, $field)
         unless exists $self->{'values'}{$field};
      $self->{'values'}{$field} = $value;
   }
}

sub delete
{
   my ($self, @fields) = @_;
   my (%gone);

   @fields = map { $self->_in($_) } @fields;
   %gone = map {$_, 1} @fields;
   @{$self->{'fields'}} = grep (! $gone{$_}, @{$self->{'fields'}});
   delete @{$self->{'values'}}{@fields};
}

sub set_fieldlist
{
   my ($self, $fields) = @_;

   # Warn if any of the caller's fields aren't already present in the entry

   my ($field, %in_list);
   foreach $field (@$fields)
   {
      $in_list{$field} = 1;
      unless (exists $self->{'values'}{$field})
      {
         carp "Implicitly adding undefined field \"$field\"";
         $self->{'values'}{$field} = undef;
      }
   }

   # And see if there are any fields in the entry that aren't in the user's
   # list; delete them from the entry if so

   foreach $field (keys %{$self->{'values'}})
   {
      unless ($in_list{$field})
      {
         carp "Implicitly deleting field \"$field\"";
         delete $self->{'values'}{$field};
      }
   }

   # Now we can install (a copy of) the caller's desired field list;

   $self->{'fields'} = [@$fields];
}


=head2 Entry output methods

=over 4

=item write (BIBFILE)

Prints a BibTeX entry on the filehandle associated with BIBFILE (which
should be a C<Text::BibTeX::File> object, opened for output).  Currently
the printout is not particularly human-friendly; a highly configurable
pretty-printer will be developed eventually.

=item print (FILEHANDLE)

Prints a BibTeX entry on FILEHANDLE.

=item print_s ()

Prints a BibTeX entry to a string, which is the return value.

=cut

sub write
{
   my ($self, $bibfile) = @_;

   my $fh = $bibfile->{'handle'};
   $self->print ($fh);
}

sub print
{
   my ($self, $handle) = @_;

   $handle ||= \*STDOUT;
   print $handle $self->print_s;
}

sub print_s
{
   my $self = shift;
   my ($field, $output);

   sub value_to_string
   {
      my $value = shift;

      if (! ref $value)                 # just a string
      {
         return "{$value}";
      }
      else                              # a Text::BibTeX::Value object
      {
         confess "value is a reference, but not to Text::BibTeX::Value object"
            unless $value->isa ('Text::BibTeX::Value');
         my @values = $value->values;
         foreach (@values)
         {
            $_ = $_->type == &BTAST_STRING ? '{' . $_->text . '}' : $_->text;
         }
         return join (' # ', @values);
     }
   }

   carp "entry type undefined" unless defined $self->{'type'};
   carp "entry metatype undefined" unless defined $self->{'metatype'};

   # Regular and macro-def entries have to be treated differently when
   # printing the first line, because the former have keys and the latter
   # do not.
   if ($self->{'metatype'} == &BTE_REGULAR)
   {
      carp "entry key undefined" unless defined $self->{'key'};
      $output = sprintf ("@%s{%s,\n",
                         $self->{'type'} || '',
                         $self->{'key'}  || '');
   }
   elsif ($self->{'metatype'} == &BTE_MACRODEF)
   {
      $output = sprintf ("@%s{\n",
                         $self->{'type'} || '');
   }

   # Comment and preamble entries are treated the same -- we print out
   # the entire entry, on one line, right here.
   else                                 # comment or preamble
   {
      return sprintf ("@%s{%s}\n\n",
                      $self->{'type'},
                      value_to_string ($self->{'value'}));
   }

   # Here we print out all the fields/values of a regular or macro-def entry
   my @fields = @{$self->{'fields'}};
   while ($field = shift @fields)
   {
      my $value = $self->{'values'}{$field};
      if (! defined $value)
      {
         carp "field \"$field\" has undefined value\n";
         $value = '';
      }

      $output .= "  $field = ";
      $output .= value_to_string ($value);

      $output .= ",\n";
   }

   # Tack on the last line, and we're done!
   $output .= "}\n\n";
   $output;
}

=back

=head2 Miscellaneous methods

=over 4

=item warn (WARNING [, FIELD])

Prepends a bit of location information (filename and line number(s)) to
WARNING, appends a newline, and passes it to Perl's C<warn>.  If FIELD is
supplied, the line number given is just that of the field; otherwise, the
range of lines for the whole entry is given.  (Well, almost -- currently,
the line number of the last field is used as the last line of the whole
entry.  This is a bug.)

For example, if lines 10-15 of file F<foo.bib> look like this:

   @article{homer97,
     author = {Homer Simpson and Ned Flanders},
     title = {Territorial Imperatives in Modern Suburbia},
     journal = {Journal of Suburban Studies},
     year = 1997
   }

then, after parsing this entry to C<$entry>, the calls

   $entry->warn ('what a silly entry');
   $entry->warn ('what a silly journal', 'journal');

would result in the following warnings being issued:

   foo.bib, lines 10-14: what a silly entry
   foo.bib, line 13: what a silly journal

=cut

sub warn
{
   my ($self, $warning, $field) = @_;

   my $location = '';
   if ($self->{'file'})
   {
      $location = $self->{'file'}{'filename'} . ", ";
   }

   my $lines = $self->{'lines'};
   my $entry_range = ($lines->{'START'} == $lines->{'STOP'})
      ? "line $lines->{'START'}"
      : "lines $lines->{'START'}-$lines->{'STOP'}";

   if (defined $field)
   {
      $location .= (exists $lines->{$field})
         ? "line $lines->{$field}: "
         : "$entry_range (unknown field \"$field\"): ";
   }
   else
   {
      $location .= "$entry_range: ";
   }

   warn "$location$warning\n";
}


=item line ([FIELD])

Returns the line number of FIELD.  If the entry was parsed from a string,
this still works--it's just the line number relative to the start of the
string.  If the entry was parsed from a file, this works just as you'd
expect it to: it returns the absolute line number with respect to the
whole file.  Line numbers are one-based.

If FIELD is not supplied, returns a two-element list containing the line
numbers of the beginning and end of the whole entry.  (Actually, the
"end" line number is currently inaccurate: it's really the the line
number of the last field in the entry.  But it's better than nothing.)

=cut

sub line
{
   my ($self, $field) = @_;

   if (defined $field)
   {
      return $self->{'lines'}{$field};
   }
   else
   {
      return @{$self->{'lines'}}{'START','STOP'};
   }
}

=item filename ()

Returns the name of the file from which the entry was parsed.  Only
works if the file is represented by a C<Text::BibTeX::File> object---if
you just passed a filename/filehandle pair to C<parse>, you can't get
the filename back.  (Sorry.)

=cut

sub filename
{
   my $self = shift;

   $self->{'file'}{'filename'};         # ooh yuck -- poking into File object 
}

1;

=back

=head1 SEE ALSO

L<Text::BibTeX>, L<Text::BibTeX::File>, L<Text::BibTeX::Structure>

=head1 AUTHOR

Greg Ward <gward@python.net>

=head1 COPYRIGHT

Copyright (c) 1997-2000 by Gregory P. Ward.  All rights reserved.  This file
is part of the Text::BibTeX library.  This library is free software; you
may redistribute it and/or modify it under the same terms as Perl itself.

=cut
