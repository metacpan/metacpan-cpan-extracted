package XML::Atom::Syndication::Object;
use strict;

use base qw( Class::ErrorHandler );

use constant XMLNS => 'http://www.w3.org/XML/1998/namespace';

use Carp;
use XML::Elemental 2.01;
use XML::Elemental::Util qw( process_name );
use XML::Atom::Syndication::Util qw( nodelist utf8_off );
use XML::Atom::Syndication::Writer;

sub new {
    my $class = shift;
    my $atom = bless {}, $class;
    $atom->init(@_) or return $class->error($atom->errstr);
    $atom;
}

sub init {
    my $atom = shift;
    my %param = @_ == 1 ? (Elem => $_[0]) : @_;
    $atom->set_ns(\%param);
    unless ($atom->{elem} = $param{Elem}) {
        unless ($atom->element_name) {
            $atom->{name} = $param{Name}
              or croak('An Elem or Name parameter is required.');
        }
        $atom->{elem} = XML::Elemental::Element->new;
        $atom->{elem}->name('{' . $atom->ns . '}' . $atom->element_name);
    } else {
        unless ($atom->element_name) {
            my ($ns, $name) = process_name($atom->{elem}->name);
            $atom->{name} = $name;
        }
    }
    $atom;
}

sub ns           { $_[0]->{ns} }
sub elem         { $_[0]->{elem} }
sub element_name { $_[0]->{name} }

sub remove {
    my $atom = shift;
    _remove($atom->elem, @_);
}

sub as_xml {
    my $w = XML::Atom::Syndication::Writer->new;
    $w->set_prefix('', $_[0]->ns);
    $w->as_xml($_[0]->elem, 1);
}

#--- Atom common attributes

sub base {
    @_ > 1
      ? $_[0]->set_attribute(XMLNS, 'base', @_[1 .. $#_])
      : $_[0]->get_attribute(XMLNS, 'base');
}

sub lang {
    @_ > 1
      ? $_[0]->set_attribute(XMLNS, 'lang', @_[1 .. $#_])
      : $_[0]->get_attribute(XMLNS, 'lang');
}

#--- accessors

sub mk_accessors {
    my $class = shift;
    my $type  = shift;
    no strict 'refs';
    foreach my $e (@_) {
        my $accessor = join '::', $class, $e;
        if ($type eq 'element') {
            *$accessor = sub {
                @_ > 1
                  ? $_[0]->set_element($_[0]->ns, $e, @_[1 .. $#_])
                  : $_[0]->get_element($_[0]->ns, $e);
            };
        } elsif ($type eq 'attribute') {
            *$accessor = sub {
                @_ > 1
                  ? $_[0]->set_attribute($_[0]->ns, $e, @_[1 .. $#_])
                  : $_[0]->get_attribute($_[0]->ns, $e);
            };
        } else {    # type is the class to instaniate
            *$accessor = sub {
                @_ > 1
                  ? $_[0]->set_element($_[0]->ns, $e, @_[1 .. $#_])
                  : $_[0]->get_class($type, $_[0]->ns, $e);
            };
        }
    }
}

sub get_element {
    my ($atom, $ns, $name) = @_;
    my $ns_uri =
      ref($ns) eq 'XML::Atom::Syndication::Namespace' ? $ns->{uri} : $ns;
    my @nodes = nodelist($atom, $ns_uri, $name);
    return unless @nodes;
    wantarray
      ? map { utf8_off($_->text_content) } @nodes
      : utf8_off($nodes[0]->text_content);
}

sub get_class {
    my ($atom, $class, $ns, $name) = @_;
    my $ns_uri =
      ref($ns) eq 'XML::Atom::Syndication::Namespace' ? $ns->{uri} : $ns;
    my @nodes = nodelist($atom, $ns_uri, $name);
    return unless @nodes;
    eval "require $class";
    croak("Error creating accessor {$ns}$name: $@") if $@;
    wantarray
      ? map { $class->new(Elem => $_, Namespace => $ns_uri) } @nodes
      : $class->new(Elem => $nodes[0], Namespace => $ns_uri);
}

sub get_attribute {
    my $atom = shift;
    my ($val);
    if (@_ == 1) {
        my ($attr) = @_;
        $val = $atom->{elem}->attributes->{"{}$attr"};
    } elsif (@_ == 2) {
        my ($ns, $attr) = @_;
        $ns = '' if $atom->ns eq $ns;
        $val = $atom->{elem}->attributes->{"{$ns}$attr"};
    }
    utf8_off($val);
}

sub set_element {
    my $atom = shift;
    my ($ns, $name, $val, $attr, $add) = @_;
    $add = $attr if ref $val;
    my $ns_uri =
      ref($ns) eq 'XML::Atom::Syndication::Namespace' ? $ns->{uri} : $ns;
    unless ($add) {
        my @nodes = nodelist($atom, $ns_uri, $name);
        foreach my $node (@nodes) {
            _remove($node) || return $atom->error($node->errstr);
        }
    }
    if (my $class = ref $val) {
        $val = $val->elem if $class =~ /^XML::Atom::Syndication::/;
        $val->parent($atom->elem);
        push @{$atom->elem->contents}, $val;
    } elsif (defined $val) {
        my $elem = XML::Elemental::Element->new;
        $elem->name("{$ns_uri}$name");
        $elem->attributes($attr) if $attr;
        $elem->parent($atom->elem);
        push @{$atom->elem->contents}, $elem;
        use XML::Elemental::Characters;
        my $chars = XML::Elemental::Characters->new;
        $chars->data($val);
        $chars->parent($elem);
        push @{$elem->contents}, $chars;
    }
    $val;
}

sub set_attribute {
    my $atom = shift;
    if (@_ == 2) {
        my ($attr, $val) = @_;
        $atom->{elem}->attributes->{"{}$attr"} = $val;
    } elsif (@_ == 3) {
        my ($ns, $attr, $val) = @_;
        my $ns_uri =
          ref($ns) eq 'XML::Atom::Syndication::Namespace' ? $ns->{uri} : $ns;
        $ns_uri = '' if $atom->ns eq $ns_uri;
        $atom->{elem}->attributes->{"{$ns_uri}$attr"} = $val;
    }
}

#--- utility

sub _remove {
    my $elem   = shift;
    my $parent = $elem->parent
      or die 'Element parent is not defined';
    my @contents = grep { $elem ne $_ } @{$parent->contents};
    $parent->contents(\@contents);
    $elem->parent(undef);
    1;
}

our %NS_MAP = (
               '0.3' => 'http://purl.org/atom/ns#',
               '1.0' => 'http://www.w3.org/2005/Atom',
);
our %NS_VERSION = reverse %NS_MAP;

sub set_ns {
    my $atom  = shift;
    my $param = shift;
    if (my $ns = delete $param->{Namespace}) {
        $atom->{ns}      = $ns;
        $atom->{version} = $NS_VERSION{$ns};
    } else {
        my $version = delete $param->{Version} || '1.0';
        $version = '1.0' if $version == 1;
        my $ns = $NS_MAP{$version}
          or return $atom->error("Unknown version: $version");
        $atom->{ns}      = $ns;
        $atom->{version} = $version;
    }
}

1;

__END__

=begin

=head1 NAME

XML::Atom::Syndication::Object - base class for all complex
Atom elements.

=head1 METHODS

=over

=item Class->new(%params);

Constructor. A HASH can be passed to initialize the object. Recognized 
keys are:

=over

=item Elem

A L<XML::Elemental::Element> that will be used as the source for this object. 
This object can be retrieved or set using the C<elem> method.

=item Namespace

A string containing the namespace URI for the element.

=item Version

A SCALAR contain the Atom format version. This hash key can
optionally be used instead of setting the element official
Atom Namespace URIs using the Namespace key. Recognized
values are 1.0 and 0.3. 1.0 is used as the default if
Namespace and Version are not defined.

=back

=item $object->ns

A read-only accessor to the element's namespace URI.

=item $object->elem([$element])

An accessor that returns its underlying
L<XML::Elemental::Element> object. If C<$object> is provided
the element is set.

=item $object->element_name

Returns the Atom element name the object represents. 
B<This MUST be overwritten by all subclasses.>

=item $object->remove

"Disowns" the object from its parent.

=item $object->as_xml

Output the element and all of its descendants are a full XML
document using L<XML::Atom::Syndication::Writer>. The object
will be the root element of the document with its namespace
URI set as the default.

=back

=head2 ATOM COMMON ATTRIBUTES

This class supplies accessors to the Atom common attributes
that every Atom element is to support.

All of these accessors return a string. You can set these
attributes by passing in an optional string.

=over

=item base

An attribute that when used serves the function described in
section 5.1.1. of RFC3986 establishing the base URI/IRI
for resolving any relative references found within its
effective scope.

This attribute is represented as C<xml:base> in markup.

=item lang

An attribute whose content indicates the natural language
for the element and its descendants. See the XML 1.0
specification, Section 2.12 for more detail.

This attribute is represented as C<xml:lang> in markup.

=back

=head2 WORKING WITH OBJECT SETTERS

Elements supporting more then a simple string value require
a more sophisticated means for adding or replacing nodes in
an Atom document. These setters share a common method
signature that is detailed here.

Elements can be set in one of two ways -- with a string HASH
reference combination or with an appropriate object.

  $atom->element($var,$attr,$add);
  $atom->element($object,$add);
 
In the first example, a string ($var) is passed with an
optional HASH reference ($attr) representing the attributes
of the node. The keys of the hash referenced by $attr
MUST be in Clarkian notation, in which the element's URI 
is wrapped in curly braces { } and prepended to the 
element's local name.

The accessor with create a node from these parameters that
will be attached to the parent element.

Following the attribute hash with a true value ($add) will
append the resulting node to any existing nodes of the same
type. The default behavior is to remove any existing nodes
of the same type before the new node is created.

In the second example the element is set with a
L<XML::Elemental::Element> object or
L<XML::Atom::Syndication::Object> subclass ($object). You
can follow the object with an optional parameter ($add) to
signify if the node is to be appended or to replace any
similar elements.

=head2 GENERIC ACCESSORS

This class supplies several get and set accessors for accessing 
any element in the parse tree regardless of namespace. These 
accessors are also used in constructing the accessors for the
elements defined in the Atom Syndication Format specification.

=over

=item $object->get_element($ns,$name)

Retrieves the string values of any direct descendent of the
object with the same namespace URI and name. C<$ns> is a
SCALAR contain a namespace URI or a
L<XML::Atom::Syndication::Namespace> object. C<$name> is the
local name of the element to retrieve.

When called in a SCALAR context returns the first element's
value. In an ARRAY context it returns all values for the
element.

=item $object->get_class($class,$ns,$name)

Retrieves any direct descendants of the object with the same namespace and
name as an object of the class defined by $class. 

C<$ns> is a SCALAR contain a namespace URI or a
L<XML::Atom::Syndication::Namespace> object. C<$name> is the
local name of the element to retrieve. C<$class> is a
package name that is assumed to be a superclass of this base
class.

When called in a SCALAR context returns the first element.
In an ARRAY context it returns all objects for the element.

=item $object->set_element($ns,$name,$val[,$attr,$add])

Sets the value of an element as a direct descendent of the
object. C<$ns> is a SCALAR contain a namespace URI or a
L<XML::Atom::Syndication::Namespace> object. C<$name> is the
local name of the element to retrieve. C<$val> can either be
a string, L<XML::Elemental::Element> object, or some
appropriate XML::Atom::Syndication object. C<$attr> is an
optional HASH reference used to specify attributes when $val
is a string value. It is ignored otherwise. he keys of the
hash referenced by $attr MUST be in Clarkian notation, in
which the element's URI is wrapped in curly braces { } and
prepended to the element's local name.

C<$add> is an optional boolean that will create a new node
and append it to any existing values as opposed to
overwriting them which is the default behavior.

Returns C<$val> if successful and C<undef> otherwise. The
error message can be retrieved through the object's
C<errstr> method.

=item $object->get_attribute($ns,$attr)

=item $object->get_attribute($attr)

Retrieves the value of an attribute. If one parameter is
passed the sole attribute is assumed to be the attribute name in
the same namespace as the object. If two are passed in it is
assumed the first is either a
C<XML::Atom::Syndication::Namespace> object or SCALAR
containing the namespace URI and the second the local name.

=item $object->set_attribute($ns,$attr,$val)

=item $object->set_attribute($attr,$val)

Sets the value of an attribute. If two parameters are passed
the first is assumed to be the attribute name and the second
its value. If three parameters are passed the first is
considered to be either a
C<XML::Atom::Syndication::Namespace> object or SCALAR
containing the namespace URI followed by the attribute name 
and new value.

=head2 ATOM ELEMENT ACCESSORS

XML::Atom::Syndication::Object dynamically generates the appropriate
accessors for all defined elements in the Atom namespace. This is a 
more convenient and less verbose then using generic methods 
such as C<get_element> or C<set_attribute>.

For instance if you wanted the issued timestamp of an entry 
you could get it with either of these lines:

 $entry->set_element('http://www.w3.org/2005/Atom','issued','2005-04-22T20:16:00Z');
 $entry->get_element('http://www.w3.org/2005/Atom','issued');

 $entry->issued('2005-04-22T20:16:00Z');
 $entry->issued;

The second set of methods are the element accessors that we are
talking about.

See the Atom Syndication Format specification or the documentation for
the specific classes for which elements you can expect from each.

These Atom element accessors are generated in each class
using the C<mk_accessors> method.

=over

=item Class->mk_accessors($type,@names)

C<$type> defines what type of set and get methods will be
used to create an element accessor for each name defined by
the @names array. Recognized values are either 'element',
'attribute' or a class name that is a superclass of this
one.

The following chart defines which of the generic accessor
methods will be used in constructing the element accessors.

 type           set             get
 -------------- --------------- ---------------
 element        set_element     get_element
 attribute      set_attribute   set_attribute
 $class         set_element     get_class

=back


=head2 ERROR HANDLING

All subclasses of XML::Atom::Syndication::Object inherit two
methods from L<Class::ErrorHandler>.

=over

=item Class->error($message)

=item $object->error($message)

Sets the error message for either the class Class or the
object C<$object> to the message C<$message>. Returns
C<undef>.

=item Class->errstr

=item $object->errstr

Accesses the last error message set in the class Class or
the object C<$object>, respectively, and returns that error
message.

=back

=head1 AUTHOR & COPYRIGHT

Please see the L<XML::Atom::Syndication> manpage for author,
copyright, and license information.

=cut

=end
