# ----------------------------------------------------------------------
# NAME       : BibTeX/Structure.pm
# CLASSES    : Text::BibTeX::Structure, Text::BibTeX::StructuredEntry
# RELATIONS  : 
# DESCRIPTION: Provides the two base classes needed to implement
#              Text::BibTeX structure modules.
# CREATED    : in original form: Apr 1997
#              completely redone: Oct 1997
# MODIFIED   : 
# VERSION    : $Id$
# COPYRIGHT  : Copyright (c) 1997-2000 by Gregory P. Ward.  All rights
#              reserved.
# 
#              This file is part of the Text::BibTeX library.  This
#              library is free software; you may redistribute it and/or
#              modify it under the same terms as Perl itself.
# ----------------------------------------------------------------------

package Text::BibTeX::Structure;

require 5.004;                              # for 'isa' and 'can' 

use strict;
use Carp;

use vars qw'$VERSION';
$VERSION = 0.88;

use Text::BibTeX ('check_class');

=head1 NAME

Text::BibTeX::Structure - provides base classes for user structure modules

=head1 SYNOPSIS

   # Define a 'Foo' structure for BibTeX databases: first, the
   # structure class:

   package Text::BibTeX::FooStructure;
   @ISA = ('Text::BibTeX::Structure');

   sub known_option 
   {
      my ($self, $option) = @_;

      ...
   }

   sub default_option
   {
      my ($self, $option) = @_;

      ...
   }

   sub describe_entry
   {
      my $self = shift;

      $self->set_fields ($type,
                         \@required_fields,
                         \@optional_fields,
                         [$constraint_1, $constraint_2, ...]);
      ...
   }


   # Now, the structured entry class

   package Text::BibTeX::FooEntry;
   @ISA = ('Text::BibTeX::StructuredEntry');

   # define whatever methods you like

=head1 DESCRIPTION

The module C<Text::BibTeX::Structure> provides two classes that form the
basis of the B<btOOL> "structure module" system.  This system is how
database structures are defined and imposed on BibTeX files, and
provides an elegant synthesis of object-oriented techniques with
BibTeX-style database structures.  Nothing described here is
particularly deep or subtle; anyone familiar with object-oriented
programming should be able to follow it.  However, a fair bit of jargon
in invented and tossed around, so pay attention.

A I<database structure>, in B<btOOL> parlance, is just a set of allowed
entry types and the rules for fields in each of those entry types.
Currently, there are three kinds of rules that apply to fields: some
fields are I<required>, meaning they must be present in every entry for
a given type; some are I<optional>, meaning they may be present, and
will be used if they are; other fields are members of I<constraint
sets>, which are explained in L<"Field lists and constraint sets">
below.

A B<btOOL> structure is implemented with two classes: the I<structure
class> and the I<structured entry class>.  The former defines everything
that applies to the structure as a whole (allowed types and field
rules).  The latter provides methods that operate on individual entries
which conform (or are supposed to conform) to the structure.  The two
classes provided by the C<Text::BibTeX::Structure> module are
C<Text::BibTeX::Structure> and C<Text::BibTeX::StructuredEntry>; these
serve as base classes for, respectively, all structure classes and all
structured entry classes.  One canonical structure is provided as an
example with B<btOOL>: the C<Bib> structure, which (via the
C<BibStructure> and C<BibEntry> classes) provides the same functionality
as the standard style files of BibTeX 0.99.  It is hoped that other
programmers will write new bibliography-related structures, possibly
deriving from the C<Bib> structure, to emulate some of the functionality
that is available through third-party BibTeX style files.

The purpose of this manual page is to describe the whole "structure
module" system.  It is mainly for programmers wishing to implement a new
database structure for data files with BibTeX syntax; if you are
interested in the particular rules for the BibTeX-emulating C<Bib>
structure, see L<Text::BibTeX::Bib>.

Please note that the C<Text::BibTeX> prefix is dropped from most module
and class names in this manual page, except where necessary.

=head1 STRUCTURE CLASSES

Structure classes have two roles: to define the list of allowed types
and field rules, and to handle I<structure options>.

=head2 Field lists and constraint sets

Field lists and constraint sets define the database structure for a
particular entry type: that is, they specify the rules which an entry
must follow to conform to the structure (assuming that entry is of an
allowed type).  There are three components to the field rules for each
entry type: a list of required fields, a list of optional fields, and
I<field constraints>.  Required and optional fields should be obvious to
anyone with BibTeX experience: all required fields must be present, and
any optional fields that are present have some meaning to the structure.
(One could conceive of a "strict" interpretation, where any field not
mentioned in the official definition is disallowed; this would be
contrary to the open spirit of BibTeX databases, but could be useful in
certain applications where a stricter level of control is desired.
Currently, B<btOOL> does not offer such an option.)

Field constraints capture the "one or the other, but not both" type of
relationships present for some entry types in the BibTeX standard style
files.  Most BibTeX documentation glosses over the distinction between
mutually constrained fields and required/optional fields.  For instance,
one of the standard entry types is C<book>, and "C<author> or C<editor>"
is given in the list of required fields for that type.  The meaning of
this is that an entry of type C<book> must have I<either> the C<author>
or C<editor> fields, but not both.  Likewise, the "C<volume> or
C<number>" are listed under the "optional fields" heading for C<book>
entries; it would be more accurate to say that every C<book> entry may
have one or the other, or neither, of C<volume> or C<number>---but not
both.

B<btOOL> attempts to clarify this situation by creating a third category
of fields, those that are mutually constrained.  For instance, neither
C<author> nor C<editor> appears in the list of required fields for
the C<inbook> type according to B<btOOL>; rather, a field constraint is
created to express this relationship:

   [1, 1, ['author', 'editor']]

That is, a field constraint is a reference to a three-element list.  The
last element is a reference to the I<constraint set>, the list of fields
to which the constraint applies.  (Calling this a set is a bit
inaccurate, as there are conditions in which the order of fields
matters---see the C<check_field_constraints> method in L<"METHODS 2:
BASE STRUCTURED ENTRY CLASS">.)  The first two elements are the minimum
and maximum number of fields from the constraint set that must be
present for an entry to conform to the constraint.  This constraint thus
expresses that there must be exactly one (>= 1 and <= 1) of the fields
C<author> and C<editor> in a C<book> entry.

The "either one or neither, but not both" constraint that applies to the
C<volume> and C<number> fields for C<book> entries is expressed slightly
differently: 

   [0, 1, ['volume', 'number']]

That is, either 0 or 1, but not the full 2, of C<volume> and C<number>
may be present.

It is important to note that checking and enforcing field constraints is
based purely on counting which fields from a set are actually present;
this mechanism can't capture "x must be present if y is" relationships.

The requirements imposed on the actual structure class are simple: it
must provide a method C<describe_entry> which sets up a fancy data
structure describing the allowed entry types and all the field rules for
those types.  The C<Structure> class provides methods (inherited by a
particular structure class) to help particular structure classes create
this data structure in a consistent, controlled way.  For instance, the
C<describe_structure> method in the BibTeX 0.99-emulating
C<BibStructure> class is quite simple:

   sub describe_entry
   {
      my $self = shift;

      # series of 13 calls to $self->set_fields (one for each standard
      # entry type)
   }

One of those calls to the C<set_fields> method defines the rules for
C<book> entries:

   $self->set_fields ('book',
                      [qw(title publisher year)],  
                      [qw(series address edition month note)],
                      [1, 1, [qw(author editor)]],
                      [0, 1, [qw(volume number)]]);

The first field list is the list of required fields, and the second is
the list of optional fields.  Any number of field constraints may follow
the list of optional fields; in this case, there are two, one for each
of the constraints (C<author>/C<editor> and C<volume>/C<number>)
described above.  At no point is a list of allowed types explicitly
supplied; rather, each call to C<set_fields> adds one more allowed type.

New structure modules that derive from existing ones will probably use the
C<add_fields> method (and possibly C<add_constraints>) to augment an
existing entry type.  Adding new types should be done with C<set_fields>,
though.

=head2 Structure options

The other responsibility of structure classes is to handle I<structure
options>.  These are scalar values that let the user customize the
behaviour of both the structure class and the structured entry class.
For instance, one could have an option to enable "extended structure",
which might add on a bunch of new entry types and new fields.  (In this
case, the C<describe_entry> method would have to pay attention to this
option and modify its behaviour accordingly.)  Or, one could have
options to control how the structured entry class sorts or formats
entries (for bibliography structures such as C<Bib>).

The easy way to handle structure options is to provide two methods,
C<known_option> and C<default_option>.  These return, respectively,
whether a given option is supported, and what its default value is.  (If
your structure doesn't support any options, you can just inherit these
methods from the C<Structure> class.  The default C<known_option>
returns false for all options, and its companion C<default_option>
crashes with an "unknown option" error.)

Once C<known_option> and C<default_option> are provided, the structure
class can sit back and inherit the more visible C<set_options> and
C<get_options> methods from the C<Structure> class.  These are the
methods actually used to modify/query options, and will be used by
application programs to customize the structure module's behaviour, and
by the structure module itself to pay attention to the user's wishes.

Options should generally have pure string values, so that the generic
set_options method doesn't have to parse user-supplied strings into some
complicated structure.  However, C<set_options> will take any scalar
value, so if the structure module clearly documents its requirements,
the application program could supply a structure that meets its needs.
Keep in mind that this requires cooperation between the application and
the structure module; the intermediary code in
C<Text::BibTeX::Structure> knows nothing about the format or syntax of
your structure's options, and whatever scalar the application passes via
C<set_options> will be stored for your module to retrieve via
C<get_options>.

As an example, the C<Bib> structure supports a number of "markup"
options that allow applications to control the markup language used for
formatting bibliographic entries.  These options are naturally paired,
as formatting commands in markup languages generally have to be turned
on and off.  The C<Bib> structure thus expects references to two-element
lists for markup options; to specify LaTeX 2e-style emphasis for book
titles, an application such as C<btformat> would set the C<btitle_mkup>
option as follows:

   $structure->set_options (btitle_mkup => ['\emph{', '}']);

Other options for other structures might have a more complicated
structure, but it's up to the structure class to document and enforce
this.

=head1 STRUCTURED ENTRY CLASSES

A I<structured entry class> defines the behaviour of individual entries
under the regime of a particular database structure.  This is the
I<raison d'E<ecirc>tre> for any database structure: the structure class
merely lays out the rules for entries to conform to the structure, but
the structured entry class provides the methods that actually operate on
individual entries.  Because this is completely open-ended, the
requirements of a structured entry class are much less rigid than for a
structure class.  In fact, all of the requirements of a structured entry
class can be met simply by inheriting from
C<Text::BibTeX::StructuredEntry>, the other class provided by the
C<Text::BibTeX::Structure> module.  (For the record, those requirements
are: a structured entry class must provide the entry
parse/query/manipulate methods of the C<Entry> class, and it must
provide the C<check>, C<coerce>, and C<silently_coerce> methods of the
C<StructuredEntry> class.  Since C<StructuredEntry> inherits from
C<Entry>, both of these requirements are met "for free" by structured
entry classes that inherit from C<Text::BibTeX::StructuredEntry>, so
naturally this is the recommended course of action!)

There are deliberately no other methods required of structured entry
classes.  A particular application (eg. C<btformat> for bibliography
structures) will require certain methods, but it's up to the application
and the structure module to work out the requirements through
documentation.

=head1 CLASS INTERACTIONS

Imposing a database structure on your entries sets off a chain reaction
of interactions between various classes in the C<Text::BibTeX> library
that should be transparent when all goes well.  It could prove confusing
if things go wrong and you have to go wading through several levels of
application program, core C<Text::BibTeX> classes, and some structure
module.

The justification for this complicated behaviour is that it allows you
to write programs that will use a particular structured module without
knowing the name of the structure when you write the program.  Thus, the
user can supply a database structure, and ultimately the entry objects
you manipulate will be blessed into a class supplied by the structure
module.  A short example will illustrate this.

Typically, a C<Text::BibTeX>-based program is based around a kernel of
code like this:

   $bibfile = Text::BibTeX::File->new("foo.bib");
   while ($entry = Text::BibTeX::Entry->new($bibfile))
   {
      # process $entry
   }

In this case, nothing fancy is happening behind the scenes: the
C<$bibfile> object is blessed into the C<Text::BibTeX::File> class, and
C<$entry> is blessed into C<Text::BibTeX::Entry>.  This is the
conventional behaviour of Perl classes, but it is not the only possible
behaviour.  Let us now suppose that C<$bibfile> is expected to conform
to a database structure specified by C<$structure> (presumably a
user-supplied value, and thus unknown at compile-time):

   $bibfile = Text::BibTeX::File->new("foo.bib");
   $bibfile->set_structure ($structure);
   while ($entry = Text::BibTeX::Entry->new($bibfile))
   {
      # process $entry
   }

A lot happens behind the scenes with the call to C<$bibfile>'s
C<set_structure> method.  First, a new structure object is created from
C<$structure>.  The structure name implies the name of a Perl
module---the structure module---which is C<require>'d by the
C<Structure> constructor.  (The main consequence of this is that any
compile-time errors in your structure module will not be revealed until
a C<Text::BibTeX::File::set_structure> or
C<Text::BibTeX::Structure::new> call attempts to load it.)

Recall that the first responsibility of a structure module is to define
a structure class.  The "structure object" created by the
C<set_structure> method call is actually an object of this class; this
is the first bit of trickery---the structure object (buried behind the
scenes) is blessed into a class whose name is not known until run-time.

Now, the behaviour of the C<Text::BibTeX::Entry::new> constructor
changes subtly: rather than returning an object blessed into the
C<Text::BibTeX::Entry> class as you might expect from the code, the
object is blessed into the structured entry class associated with
C<$structure>.  

For example, if the value of C<$structure> is C<"Foo">, that means the
user has supplied a module implementing the C<Foo> structure.
(Ordinarily, this module would be called C<Text::BibTeX::Foo>---but you
can customize this.)  Calling the C<set_structure> method on C<$bibfile>
will attempt to create a new structure object via the
C<Text::BibTeX::Structure> constructor, which loads the structure module
C<Text::BibTeX::Foo>.  Once this module is successfully loaded, the new
object is blessed into its structure class, which will presumably be
called C<Text::BibTeX::FooStructure> (again, this is customizable).  The
new object is supplied with the user's structure options via the
C<set_options> method (usually inherited), and then it is asked to
describe the actual entry layout by calling its C<describe_entry>
method.  This, in turn, will usually call the inherited C<set_fields>
method for each entry type in the database structure.  When the
C<Structure> constructor is finished, the new structure object is stored
in the C<File> object (remember, we started all this by calling
C<set_structure> on a C<File> object) for future reference.

Then, when a new C<Entry> object is created and parsed from that
particular C<File> object, some more trickery happens.  Trivially, the
structure object stored in the C<File> object is also stored in the
C<Entry> object.  (The idea is that entries could belong to a database
structure independently of any file, but usually they will just get the
structure that was assigned to their database file.)  More importantly,
the new C<Entry> object is re-blessed into the structured entry class
supplied by the structure module---presumably, in this case,
C<Text::BibTeX::FooEntry> (also customizable).

Once all this sleight-of-hand is accomplished, the application may treat
its entry objects as objects of the structured entry class for the
C<Foo> structure---they may call the check/coerce methods inherited from
C<Text::BibTeX::StructuredEntry>, and they may also call any methods
specific to entries for this particular database structure.  What these
methods might be is up to the structure implementor to decide and
document; thus, applications may be specific to one particular database
structure, or they may work on all structures that supply certain
methods.  The choice is up to the application developer, and the range
of options open to him depends on which methods structure implementors
provide.

=head1 EXAMPLE

For example code, please refer to the source of the C<Bib> module and
the C<btcheck>, C<btsort>, and C<btformat> applications supplied with
C<Text::BibTeX>.

=head1 METHODS 1: BASE STRUCTURE CLASS

The first class provided by the C<Text::BibTeX::Structure> module is
C<Text::BibTeX::Structure>.  This class is intended to provide methods
that will be inherited by user-supplied structure classes; such classes
should not override any of the methods described here (except
C<known_option> and C<default_option>) without very good reason.
Furthermore, overriding the C<new> method would be useless, because in
general applications won't know the name of your structure class---they
can only call C<Text::BibTeX::Structure::new> (usually via
C<Text::BibTeX::File::set_structure>).

Finally, there are three methods that structure classes should
implement: C<known_option>, C<default_option>, and C<describe_entry>.
The first two are described in L<"Structure options"> above, the latter
in L<"Field lists and constraint sets">.  Note that C<describe_entry>
depends heavily on the C<set_fields>, C<add_fields>, and
C<add_constraints> methods described here.

=head2 Constructor/simple query methods

=over 4

=item new (STRUCTURE, [OPTION =E<gt> VALUE, ...])

Constructs a new structure object---I<not> a C<Text::BibTeX::Structure>
object, but rather an object blessed into the structure class associated
with STRUCTURE.  More precisely:

=over 4

=item *

Loads (with C<require>) the module implementing STRUCTURE.  In the
absence of other information, the module name is derived by appending
STRUCTURE to C<"Text::BibTeX::">---thus, the module C<Text::BibTeX::Bib>
implements the C<Bib> structure.  Use the pseudo-option C<module> to
override this module name.  For instance, if the structure C<Foo> is
implemented by the module C<Foo>:

   $structure = Text::BibTeX::Structure->new
      ('Foo', module => 'Foo');

This method C<die>s if there are any errors loading/compiling the
structure module.

=item *

Verifies that the structure module provides a structure class and a
structured entry class.  The structure class is named by appending
C<"Structure"> to the name of the module, and the structured entry class
by appending C<"Entry">.  Thus, in the absence of a C<module> option,
these two classes (for the C<Bib> structure) would be named
C<Text::BibTeX::BibStructure> and C<Text::BibTeX::BibEntry>.  Either or
both of the default class names may be overridden by having the
structure module return a reference to a hash (as opposed to the
traditional C<1> returned by modules).  This hash could then supply a
C<structure_class> element to name the structure class, and an
C<entry_class> element to name the structured entry class.

Apart from ensuring that the two classes actually exist, C<new> verifies
that they inherit correctly (from C<Text::BibTeX::Structure> and
C<Text::BibTeX::StructuredEntry> respectively), and that the structure
class provides the required C<known_option>, C<default_option>, and
C<describe_entry> methods.

=item * 

Creates the new structure object, and blesses it into the structure
class.  Supplies it with options by passing all (OPTION, VALUE) pairs to
its C<set_options> method.  Calls its C<describe_entry> method, which
should list the field requirements for all entry types recognized by
this structure.  C<describe_entry> will most likely use some or all of
the C<set_fields>, C<add_fields>, and C<add_constraints>
methods---described below---for this.

=back

=cut

sub new 
{
   my ($type, $name, %options) = @_;

   # - $type is presumably "Text::BibTeX::Structure" (if called from 
   #   Text::BibTeX::File::set_structure), but shouldn't assume that
   # - $name is the name of the user-supplied structure; it also 
   #   determines the module we will attempt to load here, unless 
   #   a 'module' option is given in %options
   # - %options is a mix of options recognized here (in particular
   #   'module'), by Text::BibTeX::StructuredEntry (? 'check', 'coerce', 
   #   'warn' flags), and by the user structure classes

   my $module = (delete $options{'module'}) || ('Text::BibTeX::' . $name);

   my $module_info = eval "require $module";
   die "Text::BibTeX::Structure: unable to load module \"$module\" for " .
       "user structure \"$name\": $@\n"
      if $@;

   my ($structure_class, $entry_class);
   if (ref $module_info eq 'HASH')
   {
      $structure_class = $module_info->{'structure_class'};
      $entry_class = $module_info->{'entry_class'};
   }
   $structure_class ||= $module . 'Structure';
   $entry_class ||= $module . 'Entry';

   check_class ($structure_class, "user structure class",
                'Text::BibTeX::Structure',
                ['known_option', 'default_option', 'describe_entry']);
   check_class ($entry_class, "user entry class",
                'Text::BibTeX::StructuredEntry',
                []);

   my $self = bless {}, $structure_class;
   $self->{entry_class} = $entry_class;
   $self->{name} = $name;
   $self->set_options (%options);       # these methods are both provided by 
   $self->describe_entry;               # the user structure class
   $self;
}


=item name ()

Returns the name of the structure described by the object.

=item entry_class ()

Returns the name of the structured entry class associated with this
structure.

=back

=cut

sub name        { shift->{'name'} }

sub entry_class { shift->{'entry_class'} }


=head2 Field structure description methods

=over 4

=item add_constraints (TYPE, CONSTRAINT, ...)

Adds one or more field constraints to the structure.  A field constraint
is specified as a reference to a three-element list; the last element is
a reference to the list of fields affected, and the first two elements
are the minimum and maximum number of fields from the constraint set
allowed in an entry of type TYPE.  See L<"Field lists and constraint
sets"> for a full explanation of field constraints.

=cut

sub add_constraints
{
   my ($self, $type, @constraints) = @_;
   my ($constraint);

   foreach $constraint (@constraints)
   {
      my ($min, $max, $fields) = @$constraint;
      croak "add_constraints: constraint record must be a 3-element " .
            "list, with the last element a list ref"
         unless (@$constraint == 3 && ref $fields eq 'ARRAY');
      croak "add_constraints: constraint record must have 0 <= 'min' " .
            "<= 'max' <= length of field list"
         unless ($min >= 0 && $max >= $min && $max <= @$fields);
      map { $self->{fields}{$type}{$_} = $constraint } @$fields;
   }
   push (@{$self->{fieldgroups}{$type}{'constraints'}}, @constraints);

}  # add_constraints


=item add_fields (TYPE, REQUIRED [, OPTIONAL [, CONSTRAINT, ...]])

Adds fields to the required/optional lists for entries of type TYPE.
Can also add field constraints, but you can just as easily use
C<add_constraints> for that.

REQUIRED and OPTIONAL, if defined, should be references to lists of
fields to add to the respective field lists.  The CONSTRAINTs, if given,
are exactly as described for C<add_constraints> above.

=cut

sub add_fields                          # add fields for a particular type
{
   my ($self, $type, $required, $optional, @constraints) = @_;

   # to be really robust and inheritance-friendly, we should:
   #  - check that no field is in > 1 list (just check $self->{fields} 
   #    before we start assigning stuff)
   #  - allow sub-classes to delete fields or move them to another group

   if ($required)
   {
      push (@{$self->{fieldgroups}{$type}{'required'}}, @$required);
      map { $self->{fields}{$type}{$_} = 'required' } @$required;
   }

   if ($optional)
   {
      push (@{$self->{fieldgroups}{$type}{'optional'}}, @$optional);
      map { $self->{fields}{$type}{$_} = 'optional' } @$optional;
   }

   $self->add_constraints ($type, @constraints);

}  # add_fields


=item set_fields (TYPE, REQUIRED [, OPTIONAL [, CONSTRAINTS, ...]])

Sets the lists of required/optional fields for entries of type TYPE.
Identical to C<add_fields>, except that the field lists and list of
constraints are set from scratch here, rather than being added to.

=back

=cut

sub set_fields
{
   my ($self, $type, $required, $optional, @constraints) = @_;
   my ($constraint, $field);

   undef %{$self->{fields}{$type}};

   if ($required)
   {
      $self->{fieldgroups}{$type}{'required'} = $required;
      map { $self->{fields}{$type}{$_} = 'required' } @$required;
   }

   if ($optional)
   {
      $self->{fieldgroups}{$type}{'optional'} = $optional;
      map { $self->{fields}{$type}{$_} = 'optional' } @$optional;
   }

   undef @{$self->{fieldgroups}{$type}{'constraints'}};
   $self->add_constraints ($type, @constraints);

}  # set_fields


=head2 Field structure query methods

=over 4

=item types ()

Returns the list of entry types supported by the structure.

=item known_type (TYPE)

Returns true if TYPE is a supported entry type.

=item known_field (TYPE, FIELD)

Returns true if FIELD is in the required list, optional list, or one of
the constraint sets for entries of type TYPE.

=item required_fields (TYPE)

Returns the list of required fields for entries of type TYPE.

=item optional_fields ()

Returns the list of optional fields for entries of type TYPE.

=item field_constraints ()

Returns the list of field constraints (in the format supplied to
C<add_constraints>) for entries of type TYPE.

=back

=cut

sub types
{
   my $self = shift;

   keys %{$self->{'fieldgroups'}};
}

sub known_type
{
   my ($self, $type) = @_;

   exists $self->{'fieldgroups'}{$type};
}

sub _check_type
{
   my ($self, $type) = @_;

   croak "unknown entry type \"$type\" for $self->{'name'} structure"
      unless exists $self->{'fieldgroups'}{$type};
}

sub known_field
{
   my ($self, $type, $field) = @_;

   $self->_check_type ($type);
   $self->{'fields'}{$type}{$field};    # either 'required', 'optional', or
}                                       # a constraint record (or undef!)

sub required_fields 
{
   my ($self, $type) = @_;

   $self->_check_type ($type);
   @{$self->{'fieldgroups'}{$type}{'required'}};
}

sub optional_fields 
{
   my ($self, $type) = @_;

   $self->_check_type ($type);
   @{$self->{'fieldgroups'}{$type}{'optional'}};
}

sub field_constraints
{
   my ($self, $type) = @_;

   $self->_check_type ($type);
   @{$self->{'fieldgroups'}{$type}{'constraints'}};
}


=head2 Option methods

=over 4

=item known_option (OPTION)

Returns false.  This is mainly for the use of derived structures that
don't have any options, and thus don't need to provide their own
C<known_option> method.  Structures that actually offer options should
override this method; it should return true if OPTION is a supported
option.

=cut

sub known_option
{
   return 0;
}


=item default_option (OPTION)

Crashes with an "unknown option" message.  Again, this is mainly for use
by derived structure classes that don't actually offer any options.
Structures that handle options should override this method; every option
handled by C<known_option> should have a default value (which might just
be C<undef>) that is returned by C<default_option>.  Your
C<default_options> method should crash on an unknown option, perhaps by
calling C<SUPER::default_option> (in order to ensure consistent error
messages).  For example:

   sub default_option
   {
      my ($self, $option) = @_;
      return $default_options{$option}
         if exists $default_options{$option};
      $self->SUPER::default_option ($option);   # crash
   }

The default value for an option is returned by C<get_options> when that
options has not been explicitly set with C<set_options>.

=cut

sub default_option
{
   my ($self, $option) = @_;

   croak "unknown option \"$option\" for structure \"$self->{'name'}\"";
}


=item set_options (OPTION =E<gt> VALUE, ...)

Sets one or more option values.  (You can supply as many 
C<OPTION =E<gt> VALUE> pairs as you like, just so long as there are an even
number of arguments.)  Each OPTION must be handled by the structure
module (as indicated by the C<known_option> method); if not
C<set_options> will C<croak>.  Each VALUE may be any scalar value; it's
up to the structure module to validate them.

=cut

sub set_options
{
   my $self = shift;
   my ($option, $value);

   croak "must supply an even number of arguments (option/value pairs)"
      unless @_ % 2 == 0;
   while (@_)
   {
      ($option, $value) = (shift, shift);
      croak "unknown option \"$option\" for structure \"$self->{'name'}\""
         unless $self->known_option ($option);
      $self->{'options'}{$option} = $value;
   }
}


=item get_options (OPTION, ...)

Returns the value(s) of one or more options.  Any OPTION that has not
been set by C<set_options> will return its default value, fetched using
the C<default_value> method.  If OPTION is not supported by the
structure module, then your program either already crashed (when it
tried to set it with C<set_option>), or it will crash here (thanks to
calling C<default_option>).

=back

=cut

sub get_options
{
   my $self = shift;
   my ($options, $option, $value, @values);

   $options = $self->{'options'};
   while (@_)
   {
      $option = shift;
      $value = (exists $options->{$option})
         ? $options->{$option}
         : $self->default_option ($option);
      push (@values, $value);
   }

   wantarray ? @values : $values[0];
}



# ----------------------------------------------------------------------
# Text::BibTeX::StructuredEntry methods dealing with entry structure

package Text::BibTeX::StructuredEntry;
use strict;
use vars qw(@ISA $VERSION);
$VERSION = 0.88;

use Carp;

@ISA = ('Text::BibTeX::Entry');
use Text::BibTeX qw(:metatypes display_list);

=head1 METHODS 2: BASE STRUCTURED ENTRY CLASS

The other class provided by the C<Structure> module is
C<StructuredEntry>, the base class for all structured entry classes.
This class inherits from C<Entry>, so all of its entry
query/manipulation methods are available.  C<StructuredEntry> adds
methods for checking that an entry conforms to the database structure
defined by a structure class.

It only makes sense for C<StructuredEntry> to be used as a base class;
you would never create standalone C<StructuredEntry> objects.  The
superficial reason for this is that only particular structured-entry
classes have an actual structure class associated with them,
C<StructuredEntry> on its own doesn't have any information about allowed
types, required fields, field constraints, and so on.  For a deeper
understanding, consult L<"CLASS INTERACTIONS"> above.

Since C<StructuredEntry> derives from C<Entry>, it naturally operates on
BibTeX entries.  Hence, the following descriptions refer to "the
entry"---this is just the object (entry) being operated on.  Note that
these methods are presented in bottom-up order, meaning that the methods
you're most likely to actually use---C<check>, C<coerce>, and
C<silently_coerce> are at the bottom.  On a first reading, you'll
probably want to skip down to them for a quick summary.

=over 4

=item structure ()

Returns the object that defines the structure the entry to which is
supposed to conform.  This will be an instantiation of some structure
class, and exists mainly so the check/coerce methods can query the
structure about the types and fields it recognizes.  If, for some
reason, you wanted to query an entry's structure about the validity of
type C<foo>, you might do this:

   # assume $entry is an object of some structured entry class, i.e.
   # it inherits from Text::BibTeX::StructuredEntry
   $structure = $entry->structure;
   $foo_known = $structure->known_type ('foo');

=cut

sub structure
{
   my $self = shift;
   $self->{'structure'};
}


=item check_type ([WARN])

Returns true if the entry has a valid type according to its structure.
If WARN is true, then an invalid type results in a warning being
printed.

=cut

sub check_type
{
   my ($self, $warn) = @_;

   my $type = $self->{'type'};
   if (! $self->{'structure'}->known_type ($type))
   {
      $self->warn ("unknown entry type \"$type\"") if $warn;
      return 0;
   }
   return 1;
}


=item check_required_fields ([WARN [, COERCE]])

Checks that all required fields are present in the entry.  If WARN is
true, then a warning is printed for every missing field.  If COERCE is
true, then missing fields are set to the empty string.

This isn't generally used by other code; see the C<check> and C<coerce>
methods below.

=cut

sub check_required_fields
{
   my ($self, $warn, $coerce) = @_;
   my ($field, $warning);
   my $num_errors = 0;
   
   foreach $field ($self->{'structure'}->required_fields ($self->type))
   {
      if (! $self->exists ($field))
      {
         $warning = "required field '$field' not present" if $warn;
         if ($coerce)
         {
            $warning .= " (setting to empty string)" if $warn;
            $self->set ($field, '');
         }
         $self->warn ($warning) if $warn;
         $num_errors++;
      }
   }
   
   # Coercion is always successful, so if $coerce is true return true.
   # Otherwise, return true if no errors found.

   return $coerce || ($num_errors == 0);

}  # check_required_fields


=item check_field_constraints ([WARN [, COERCE]])

Checks that the entry conforms to all of the field constraints imposed
by its structure.  Recall that a field constraint consists of a list of
fields, and a minimum and maximum number of those fields that must be
present in an entry.  For each constraint, C<check_field_constraints>
simply counts how many fields in the constraint's field set are present.
If this count falls below the minimum or above the maximum for that
constraint and WARN is true, a warning is issued.  In general, this
warning is of the form "between x and y of fields foo, bar, and baz must
be present".  The more common cases are handled specially to generate
more useful and human-friendly warning messages.

If COERCE is true, then the entry is modified to force it into
conformance with all field constraints.  How this is done depends on
whether the violation is a matter of not enough fields present in the
entry, or of too many fields present.  In the former case, just enough
fields are added (as empty strings) to meet the requirements of the
constraint; in the latter case, fields are deleted.  Which fields to add
or delete is controlled by the order of fields in the constraint's field
list.

An example should clarify this.  For instance, a field constraint
specifying that exactly one of C<author> or C<editor> must appear in an
entry would look like this:

   [1, 1, ['author', 'editor']]

Suppose the following entry is parsed and expected to conform to this
structure:

   @inbook{unknown:1997a,
     title = "An Unattributed Book Chapter",
     booktitle = "An Unedited Book",
     publisher = "Foo, Bar \& Company",
     year = 1997
   }

If C<check_field_constraints> is called on this method with COERCE true
(which is done by any of the C<full_check>, C<coerce>, and
C<silently_coerce> methods), then the C<author> field is set to the
empty string.  (We go through the list of fields in the constraint's
field set in order -- since C<author> is the first missing field, we
supply it; with that done, the entry now conforms to the
C<author>/C<editor> constraint, so we're done.)

However, if the same structure was applied to this entry:

   @inbook{smith:1997a,
     author = "John Smith",
     editor = "Fred Jones",
     ...
   }

then the C<editor> field would be deleted.  In this case, we allow the
first field in the constraint's field list---C<author>.  Since only one
field from the set may be present, all fields after the first one are in
violation, so they are deleted.

Again, this method isn't generally used by other code; rather, it is
called by C<full_check> and its friends below.

=cut

sub check_field_constraints
{
   my ($self, $warn, $coerce) = @_;

   my $num_errors = 0;
   my $constraint;

   foreach $constraint ($self->{'structure'}->field_constraints ($self->type))
   {
      my ($warning);
      my ($min, $max, $fields) = @$constraint;

      my $field;
      my $num_seen = 0;
      map { $num_seen++ if $self->exists ($_) } @$fields;

      if ($num_seen < $min || $num_seen > $max)
      {
         if ($warn)
         {
            if ($min == 0 && $max > 0)
            {
               $warning = sprintf ("at most %d of fields %s may be present",
                                   $max, display_list ($fields, 1));
            }
            elsif ($min < @$fields && $max == @$fields)
            {               
               $warning = sprintf ("at least %d of fields %s must be present",
                                   $min, display_list ($fields, 1));
            }
            elsif ($min == $max)
            {
               $warning = sprintf ("exactly %d of fields %s %s be present",
                                   $min, display_list ($fields, 1),
                                   ($num_seen < $min) ? "must" : "may");
            }
            else
            {
               $warning = sprintf ("between %d and %d of fields %s " . 
                                   "must be present", 
                                   $min, $max, display_list ($fields, 1))
            }
         }

         if ($coerce)
         {
            if ($num_seen < $min)
            {
               my @blank = @{$fields}[$num_seen .. ($min-1)];
               $warning .= sprintf (" (setting %s to empty string)",
                                    display_list (\@blank, 1))
                  if $warn;
               @blank = map (($_, ''), @blank);
               $self->set (@blank);
            }
            elsif ($num_seen > $max)
            {
               my @delete = @{$fields}[$max .. ($num_seen-1)];
               $warning .= sprintf (" (deleting %s)",
                                    display_list (\@delete, 1))
                  if $warn;
               $self->delete (@delete);
            }
         }  # if $coerce

         $self->warn ($warning) if $warn;
         $num_errors++;
      }  # if $num_seen out-of-range

   }  # foreach $constraint

   # Coercion is always successful, so if $coerce is true return true.
   # Otherwise, return true if no errors found.

   return $coerce || ($num_errors == 0);

}  # check_field_constraints


=item full_check ([WARN [, COERCE]])

Returns true if an entry's type and fields are all valid.  That is, it
calls C<check_type>, C<check_required_fields>, and
C<check_field_constraints>; if all of them return true, then so does
C<full_check>.  WARN and COERCE are simply passed on to the three
C<check_*> methods: the first controls the printing of warnings, and the
second decides whether we should modify the entry to force it into
conformance.

=cut

sub full_check
{
   my ($self, $warn, $coerce) = @_;

   return 1 unless $self->metatype == &BTE_REGULAR;
   return unless $self->check_type ($warn);
   return $self->check_required_fields ($warn, $coerce) &&
          $self->check_field_constraints ($warn, $coerce);
}


# Front ends for full_check -- there are actually four possible wrappers,
# but having both $warn and $coerce false is pointless.

=item check ()

Checks that the entry conforms to the requirements of its associated
database structure: the type must be known, all required fields must be
present, and all field constraints must be met.  See C<check_type>,
C<check_required_fields>, and C<check_field_constraints> for details.

Calling C<check> is the same as calling C<full_check> with WARN true and
COERCE false.

=item coerce ()

Same as C<check>, except entries are coerced into conformance with the
database structure---that is, it's just like C<full_check> with both
WARN and COERCE true.

=item silently_coerce ()

Same as C<coerce>, except warnings aren't printed---that is, it's just
like C<full_check> with WARN false and COERCE true.

=back

=cut

sub check { shift->full_check (1, 0) }

sub coerce { shift->full_check (1, 1) }

sub silently_coerce { shift->full_check (0, 1) }

1;

=head1 SEE ALSO

L<Text::BibTeX>, L<Text::BibTeX::Entry>, L<Text::BibTeX::File>

=head1 AUTHOR

Greg Ward <gward@python.net>

=head1 COPYRIGHT

Copyright (c) 1997-2000 by Gregory P. Ward.  All rights reserved.  This file
is part of the Text::BibTeX library.  This library is free software; you
may redistribute it and/or modify it under the same terms as Perl itself.
