package Treex::PML::Factory;

use 5.008;
use strict;
use warnings;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.24'; # version template
}
use Carp;
use UNIVERSAL::DOES;

my $default_factory;

sub DOES {
  my ($self,$role)=@_;
  if ($role eq __PACKAGE__) {
    # we don't implement Treex::PML::Factory interface, but anything derived from use is assumed to do so
    return ref($role) eq __PACKAGE__ ? 0 : 1;
  } else {
    return $self->DOES($role);
  }
}

sub new {
  my $class = shift;
  return bless {@_}, $class;
}

sub make_default {
  my $obj = shift;
  my $class = ref($obj) || $obj;

  die __PACKAGE__." is not a proper factory and cannot be made default!\n"
    if $class eq __PACKAGE__;

  my $prev = Treex::PML::Factory->get_default_factory;
  unless ((ref($prev)||'') eq $class) {
    Treex::PML::Factory->set_default_factory(ref($obj) ? $obj : $class->new(@_));
  }
  return $prev;
}

sub set_default_factory {
  my ($self,$factory)=@_;
  die __PACKAGE__."->set_default_factory: argument must implement ".__PACKAGE__."!"
    unless UNIVERSAL::DOES::does($factory,__PACKAGE__);
  $default_factory = $factory;
}

sub get_default_factory {
  return $default_factory;
}

BEGIN {
  no strict 'refs';
  for my $method (qw(
		      createPMLSchema createPMLInstance
		      createDocument createDocumentFromFile
		      createFSFormat
		      createNode createTypedNode createList createSeq
		      createAlt createContainer createStructure
		   )) {
    *$method = sub { shift; $default_factory->$method(@_) }
  }
}

1;
__END__

=head1 NAME

Treex::PML::Factory - a base class for Treex::PML object factories

=head1 SYNOPSIS

   use Treex::PML;
   use MyTreex::PML::Factory;

   MyTreex::PML::Factory->make_default();

   # These class methods invoke similarly named methods on the default
   # factory; the default factory method's are responsible for
   # creating and returning the corresponding objects.

   Treex::PML::Factory->createPMLSchema(...)
   Treex::PML::Factory->createPMLInstance(...)

   Treex::PML::Factory->createDocument(..)
   Treex::PML::Factory->createDocumentFromFile(..)

   Treex::PML::Factory->createFSFormat(..)

   Treex::PML::Factory->createNode(..)
   Treex::PML::Factory->createTypedNode($decl,...);

   Treex::PML::Factory->createList(...)
   Treex::PML::Factory->createSeq(...)
   Treex::PML::Factory->createAlt(...)
   Treex::PML::Factory->createContainer(...)
   Treex::PML::Factory->createStructure(...)

=head1 DESCRIPTION

This class maintains a default factory for creating Treex::PML objects and
delegates C<create...()> methods called as class methods to the
default factory.

Note that this class does not implement a factory,
L<Treex::PML::StandardFactory> does that.

This class provides means for creating various types of Treex::PML-like
objects without having to name particular classes. The user can plug
in their own default factory in order to replace the default Treex::PML
class hierarchy with their own one. The classes in the user hierarchy
typically derive from the corresponding classes in the Treex::PML
hierarchy; if not, they must at least implement the same interfaces
and use the same types of references for the underlying objects (or
overloading to them, so that also low-level code using HASH or ARRAY
dereferencing on objects still works).

User can define factory by implementing all the C<create*> methods as
object methods. The factory must be derived from the 'Treex::PML::Factory'
class or, alternatively, provide a constructor 'new' and implement the
DOES method which then returns true if 'Treex::PML::Factory' is passed to
it as an argument.

=head2 CLASS METHODS

=over 5

=item $class->make_default()

If inherited by a customized factory class, makes the invocant class
the default factory. Every factory class should either inherit this
method or reimplement it using a call to
C<< Treex::PML::Factory->set_default_factory >>.

=item $class->new(name=>value, ...)

If inherited by a customized factory class, creates a new instance of
that class. The default constructor will create a blessed hash
reference using the constructor arguments to populate the hash with
name=>value pairs.

=item Treex::PML::Factory->get_default_factory()

Returns the default factory (usually a singleton Treex::PML::Factory object).

=item Treex::PML::Factory->set_default_factory($default_factory)

Change the default factory to a given object (the object must implment
the Treex::PML::Factory interface).

=back

=head2 METHODS FOR CREATING OBJECTS

The following functions B<must be implemented by custom factory classes
as object methods>, but should be called as class methods of the
'Treex::PML::Factory' class. The class methods of
'Treex::PML::Factory' delegate the call to the default factory.

=over 5


=item Treex::PML::Factory->createPMLSchema({ option => value, ... })

Parses an XML representation of a PML Schema from a string,
filehandle, local file, or URL, processing the modular instructions as
described in

  L<http://ufal.mff.cuni.cz/jazz/PML/doc/pml_doc.html#processing>

and returns the corresponding object implementing the interface or
L<Treex::PML::Schema>. One of the following options must be given:

=over 5

=item C<string>

a XML string to parse

=item C<filename>

a file name or URL

=item C<fh>

a file-handle (IO::File, IO::Pipe, etc.) open for reading

=back

The following options are optional:

=over 5

=item C<base_url>

base URL for referred schemas (usefull when parsing from a file-handle or a string)

=item C<use_resources>

if this option is used with a true value, the parser will attempt to
locate referred schemas also in L<Treex::PML> resource paths.

=item C<revision>, C<minimal_revision>, C<maximal_revision>

put constraints on the revision number of the schema.

=item C<validate>

if this option is used with a true value, the parser will validate the
schema on the fly using a RelaxNG grammar given using the
C<relaxng_schema> parameter; if C<relaxng_schema> is not given, the
file 'pml_schema_inline.rng' searched for in L<Treex::PML> resource paths
is assumed.

=item C<relaxng_schema>

a particular RelaxNG grammar to validate against. The value may be an
URL or filename for the grammar in the RelaxNG XML format, or a
XML::LibXML::RelaxNG object representation. The compact format is not
supported.

=back

=item Treex::PML::Factory->createPMLInstance({ option=>value, ...})

Without arguments (the option HashRef) creates a empty object implementing
the L<Treex::PML::Instance> interface.

If called with the option HashRef, a new object implementing the
L<Treex::PML::Instance> interface is created and its content is read
from a given XML input in the PML format.  The input can be a file,
filehandle, string, or a DOM tree. The arguments are described in the
documentation of the the C<load()> method of L<Treex::PML::Instance>.

=item Treex::PML::Factory->createDocument({ option => value, ... })

Creates a new empty object implementing the L<Treex::PML::Document>
interface. The options are used to initialize the object's attributes
and include: C<name>, C<format>, C<trees>, C<backend>, C<FS>, C<hint>,
C<patterns>, C<tail>, C<save_status>. See the documentation of
the C<create()> method of L<Treex::PML::Document> for details.

=item Treex::PML::Factory->createDocumentFromFile($filename, { option => value, ... })

Creates a new object implementing the L<Treex::PML::Document> interface and
reads its content from a given file. The arguments are described in
the documentation of the the C<load()> method of
L<Treex::PML::Document>.

=item Treex::PML::Factory->createFSFormat($definition)

Return a new object implementing the L<Treex::PML::FSFormat> interface.
The argument can be a HashRef containing the FS format definition in
parsed from, or an ARRAY reference (whose elements are individual
lines of the FS format definition) or a GLOB reference with an input
stream from which the FS format definition is to be read.

=item Treex::PML::Factory->createNode($hashRef?,$reuse?)

Return a new node object implementing the L<Treex::PML::Node> interface,
using given HashRef reference as the source of initial set of attributes;
if the C<$reuse> argument is true, the HashRef may be actually
blessed into the new class (if supported by the implementation).

=item Treex::PML::Factory->createTypedNode($pml_type_decl,...);

or

=item Treex::PML::Factory->createTypedNode($type_name,$pml_schema,...);

Return a new node object implementing the L<Treex::PML::Node>
interface, associated with the given PML type (passed either as a
L<Treex::PML::Schema::Decl> object or as the type name followed by a PML
schema object).

=item Treex::PML::Factory->createList($arrayRef?,$reuse?)

Return a new list (object implementing the L<Treex::PML::List> interface),
populated with the values passed in the (optional) ArrayRef.
If the C<$reuse> argument is true, the given ArrayRef may actually be
reblessed into the target class (if supported by the implementation).

=item Treex::PML::Factory->createAlt($arrayRef?,$reuse?)

Return a new alternative (object implementing the L<Treex::PML::Alt> interface),
populated with the values passed in the (optional) ArrayRef.
If the C<$reuse> argument is true, the given ArrayRef may actually be
reblessed into the target class (if supported by the implementation).

=item Treex::PML::Factory->createSeq($arrayRef?, $content_pattern?,$reuse?)

Return a new sequence (object implementing the L<Treex::PML::Seq>
interface).  The object gets populated by elements from a given
ArrayRef (if given). Each element of the ArrayRef should be a
L<Treex::PML::Seq::Element> object. The second optional argument is a
regular expression constraint which can be stored in the object and
used later for validating its content (see validate() method of
L<Treex::PML::Seq>). If the C<$reuse> argument is true, the ArrayRef
can be used directly as the container for the content of the sequence
(if supported by the implementation); otherwise it is copied.

=item Treex::PML::Factory->createContainer($value?, $hashRef?, $reuse?)

Create a new container (object implementing the L<Treex::PML::Container>
interface). The the initial value for the container's value with $value
and its attributes with the name-value pairs from the given
HashRef. If $reuse is true, the HashRef passed  may actually be reblessed into the target class (if supported
by the implementation).

=item Treex::PML::Factory->createStructure($hashRef?, $reuse?)

Create a new structure (object implementing the L<Treex::PML::Struct>
interface).  The structure is initialized with the name-value pairs
from the given HashRef (optional). If $reuse is true, the HashRef may
actually be reblessed into the target class (if supported by the
implementation).

=item DOES($interface)

Check whether the class implements a given interface (role). Note, the
class Treex::PML::Factory itself does not implement the
Treex::PML::Factory interface, but assumes that anything derived from
it does!

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<Treex::PML>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Petr Pajas

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut

