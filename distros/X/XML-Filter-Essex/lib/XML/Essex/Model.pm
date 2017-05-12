package XML::Essex::Model;

$VERSION = 0.000_1;

=head1 NAME

XML::Essex::Model - Essex objects representing SAX events and DOM trees

=head1 SYNOPSIS

Used internally by Essex, see below for external API examples.

=head1 DESCRIPTION

A description of all of the events explicitly supported so far.
Unsupported events are still handled as anonymous events, see
L<XML::Essex::Event|XML::Essex::Event> for details.

=head2 A short word on abbreviations

A goal of essex is to allow code to be as terse or verbose as is
appropriate for the job at hand.  So almost every object may be
abbreviated.  So C<start_element> may be abbreviated as C<start_elt> for
both the C<isa()> method/function and for class creation.

All objects are actually blessed in to classes using the long name, like
C<XML::Essex::start_element> even if you use an abbreviation like
C<XML::Essex::start_elt->new> to create them.

=head2 Stringification

All events are stringifiable for debugging purposes and so that
attribute values, character data, comments, and processing instructions
may be matched with Perl string operations like regular expressions and
C<index()>.  It is usually more effective to use EventPath, but you can
use stringified values for things like complex regexp matching.

It is unwise to match other events with string operators because no XML
escaping of data is done, so "<" in an attribute value or character data
is stringified as "<", so C<print()>ing out the three events associated
with the sequence "<foo>&lt;bar/></foo>" will look like
"<foo><bar/></foo>", obviously not what the document intended.  Given
the rarity of such constructs in real life XML, though, this is
sufficient for debugging purposes, and does make it easy to match
against strings.  

Ordinarily, you tell C<get()> what kind of object you want using an
EventPath expression:

    my $start_element = get "start_element::*";

You can also just C<get()> whatever's next in the document or use a
union expression.  In this case, you may need to see what you've gotten.
The C<isa()> method (see below) and the C<isa()> functions (see
L<XML::Essex|XML::Essex/isa>) should be used to figure out what type of
object is being used before relying on the stringification:

    get until isa "chars" and /Bond, James Bond/;
    get until type eq "characters" and /Bond, James Bond/;
    get until isa( "chars" ) && /Bond, James Bond/;
    get "text()" until /Bond, James Bond/;

This makes it easier to match characters data, but other methods
should be used to select things like start tags and elements:

    get "start_element::*" until $_->name eq "address" && $_->{id} eq $id;
    get "start_element::address" until $_->{id} eq $id;

The lack of escaping only affects stringification of objects, for
instance:

    warn $_;  ## See what event is being dealt with right now
    /Bond, James Bond/  ## Match current event

.  Things are escaped properly when the put operator is used, using
C<put()> emits properly escaped XML.

Some observervations:

=over

=item * 

Stringifying an event does not produce a well formed chunk of
XML.  Events must be emitted through a downstream filter.

=item *

Events with no natural XML representation--like
start_document--stringify as their name: "start_document()".  If it's
not listed on this page, it stringifies this way.

=item *

Whitespace is inserted only where manditory inside XML constructs, and
is a single space.  It is left unmolested in character data, comments,
processing instructions (other than C<< <?xml ...?> >>, which is parsed
by all XML parsers).

=item *

Attributes in start_element events are stringified in alphabetical order
according to Perl's C<sort()> function.

=item *

Processing instructions, including the C<< <?xml...?> >> declaration,
often have things that look like attributes but are not, so the items
above about whitespace and attribute sort order do not apply.  Actually,
the C<< <?xml ... ?> >> declaration is well defined and there will
be only a single whitespace character, though the pseudo-attributes
version, encoding and standalone will not be sorted.

=item *

No escapes are used.  See above.

=item *

Character data is catenated, including mixed data and CDATA, in to
single strings.  CDATA sections are tracked and may be analyzed.

=item *

Namespaces are stringified according to any prefixes that have been
registered, otherwise they stringify in james clark notation
(C<"{}foo">), except for the empty namespace URI, which alway
stringifies as "" (ie no prefix).  See L<XML::Essex's Namspaces
section|XML::Essex/Namespaces> for details.

=back

=head1 Common Methods

All of the objects in the model provide the following methods.  These
methods are exported as functions from the L<XML::Essex|XML::Essex>
module for convenience (those functions are wrappers around these
methods).

=over

=item isa

Returns TRUE if the object is of the type, abbreviated type, or class
passed.  So, for an object encapsulating a characters event, returns
TRUE for any of:

    XML::Essex::Event             ## The base class for all events
    XML::Essex::start_document    ## The actuall class name
    start_document                ## The event type
    start_doc                     ## The event type, abbreviated

=item class

Returns the class name, such as C<XML::Essex::start_document>.

=item type

Returns the class name, such as C<start_document>.

=item types

Returns the class name, the type name and any abbreviations. The
abbreviations are sorted from longest to shortest.

=back

=head1 start_document

aka: start_doc

    my $e = start_doc \%values;    ## %values is not defined in SAX1/SAX2

Stringifies as: C<< start_document($reserved) >>

where $reserved is a character string that may sometime include
info passed in the start_document event, probably formatted as
attributes.

=cut

use XML::Essex::Event;

{
    use strict;
    use Carp ();

    sub _jclarkify {
        my ( $name ) = @_;

        return $name if substr( $name, 0, 1 ) eq "{";

        if ( $name =~ /(.*):(.*)/ ) {  ## prefix notation
            ## "TODO: Namespace prefix access for attrs";
            return "{foo}$name";
        }

        ## TODO: default to default ns instead of empty ns
        return "{}$name";
    }


    sub _split_name {
        my ( $name ) = @_;

        return ( $1, $2 ) if /^\{(.*)\}(.*)\z/;

        ## TODO: prefix => URI Namespace mapping
        return ( "http://foo/", $2 ) if $name =~ /(.*):(.*)/;

        ## TODO: default to default ns instead of empty ns
        return ( "", $name );
    }


    sub _render_name {
        my ( $ns, $local_name ) = @_;

        $local_name = "*UNDEFINED NAME*" unless defined $local_name;

        return $local_name unless defined $ns && length $ns;

        ## TODO: ns => prefix mapping
        return "foo:$local_name" if $ns =~ /foo/;

        return "{$ns}$local_name";
    }

    sub _render_event_name {
        _render_name @{$_[0]}{qw( NamespaceURI LocalName )};
    }
}

{
    package XML::Essex::Event::start_document;

    @ISA = qw( XML::Essex::Event );

    use strict;

    sub type { "start_document" }

    sub types { ( __PACKAGE__, "start_document", "start_doc" ) }

    sub isa {
        my $self = shift;
        return $_[0] eq "start_document"
            || $_[0] eq "start_doc"
            || $self->SUPER::isa( @_ );
    }

    @XML::Essex::Event::start_doc::ISA = qw( XML::Essex::Event::start_document );
    sub XML::Essex::Event::start_doc::new {
        my $proto = shift;
        $proto = __PACKAGE__
            if ! ref $proto && $proto eq "XML:Essex::start_doc";
        $proto->XML::Essex::Event::start_document::new( @_ )
    }
}

=head1 xml_decl

aka: (no abbreviations)

    my $e = xml_decl;

    my $e = xml_decl
        Version    => "1",
        Encoding   => "UTF-8",
        Standalone => "yes";

    my $e = xml_decl {
        Version    => "1",
        Encoding   => "UTF-8",
        Standalone => "yes"
    };


Stringifies as: C<< <?xml version="$version" encoding="$enc"
standalone="$yes_or_no"?> >>

Note that this does not follow the sorted attribute order behavior of
start_element, as the seeming attributes here are not attributes, like
processing instructions that have pretend attributes.

=cut

{
    package XML::Essex::Event::xml_decl;

    @ISA = qw( XML::Essex::Event );

    use strict;

    use overload '""' => \&_stringify;

    sub type { "xml_decl" }

    sub types { ( __PACKAGE__, "xml_decl" ) }

    sub _stringify {
        my $self = shift;
        return join "",
            qq[<?xml version="$$self->{Version}"],
            exists $$self->{Encoding} && $$self->{Encoding}
                ? qq[ encoding="$$self->{Encoding}"] : (),
            exists $$self->{Standalone} && defined $$self->{Standalone}
                ? qq[ standalone="$$self->{Standalone}"] : (),
            qq[?>];
    }

    sub isa {
        my $self = shift;
        return $_[0] eq "xml_decl"
            || $self->SUPER::isa( @_ );
    }

}

=head1 end_document

aka: end_doc

    my $e = end_doc \%values;    ## %values is not defined in SAX1/SAX2

Stringifies as: C<< end_document($reserved) >>

where $reserved is a character string that may sometime include
info passed in the end_document event, probably formatted as
attributes.

=cut

{
    package XML::Essex::Event::end_document;

    @ISA = qw( XML::Essex::Event );

    use strict;

    sub type { "end_document" }

    sub types { ( __PACKAGE__, "end_document", "end_doc" ) }

    sub isa {
        my $self = shift;
        return $_[0] eq "end_document"
            || $_[0] eq "end_doc"
            || $self->SUPER::isa( @_ );
    }

    @XML::Essex::Event::end_doc::ISA = qw( XML::Essex::Event::end_document );
    sub XML::Essex::Event::end_doc::new {
        my $proto = shift;
        $proto = __PACKAGE__
            if ! ref $proto && $proto eq "XML:Essex::end_doc";
        $proto->XML::Essex::Event::end_document::new( @_ )
    }
}

=head1 start_element

aka: start_elt

    my $e = start_elt foo => { attr => "val"  };
    my $e = start_elt $start_elt;  ## Copy constructor
    my $e = start_elt $end_elt;    ## end_elt deconstructor
    my $e = start_elt $elt;        ## elt deconstructor

Stringifies as: C<< <foo attr1="$val1" attr2="val2"> >>

The element name and any attribute names are prefixed according to
namespace mappings registered in the Essex processor, the prefixes they
had in the source document are ignored.  If no prefix has been mapped,
jclark notation (C<{http:...}foo>) is used.  Then they are sorted
according to Perl's C<sort()> function, so jclarked attribute names come
last, as it happens.

TODO: Support attribute ordering via consecutive {...} sets.

Attributes may be accessed using hash dereferences:

    get "start_element::*" until $_->{id} eq "10";  ## No namespace prefix
    get "start_element::*" until $_->{"{}id"} eq "10";
    get "start_element::*" until $_->{"{http://foo/}id"} eq "10";
    get "start_element::*" until $_->{"foo:id"} eq "10";

and the attribute names may be obtained by:

    keys %$_;

.  Keys are returned in no predictable order, see
L<Namespaces|XML::Essex/Namespaces> for details on the three formats
keys may be returned in.

=head2 Methods

=over

=cut

{
    package XML::Essex::Event::start_element;

    @ISA = qw( XML::Essex::Event );

    use strict;

    use overload(
        '""' => \&_stringify,
        '%{}' => \&_hash_deref,
    );

    sub new {
        my $self = shift->SUPER::new(
            ! ref $_[0]
                ? do {
                    my $elt_name = shift;
                    my $attrs = shift;
                    (
                        Name      => $elt_name,
                        LocalName => $elt_name,
                        $attrs
                            ? (
                                Attributes => {
                                    map { ( "{}$_" => {
                                        Name      => $_,
                                        LocalName => $_,
                                        Value     => $attrs->{$_},
                                    } ) } keys %$attrs
                                }
                            )
                            : (),
                    )
                }
                : @_
        );

        delete $$self->{StartElement};  ## In case an ::element was passed in
        delete $$self->{EndElement};    ## In case an ::element was passed in
        delete $$self->{Content};       ## In case an ::element was passed in
        return $self;
    }

    sub type { "start_element" }

    sub types { ( __PACKAGE__, "start_element", "start_elt" ) }

    sub _stringify {
        my $self = shift;

        my $name = $$self->{LocalName};

        if ( defined $$self->{NamespaceURI} 
            && length $$self->{NamespaceURI}
        ) {
            ## TODO namespace -> prefix translation
            $name = "foo:$name";
        }

## Work around some odd thread safety thing.
## TODO: See if this can be removed with perl5.8.1
my $s = $$self;
my $a = $s->{Attributes};

        my $foo = join "",
            qq[<],
            $name,
            keys %$a
                ? sort map {
                    my $name = $_->{LocalName};

                    if ( defined $_->{NamespaceURI} 
                        && length $_->{NamespaceURI}
                    ) {
                        ## TODO namespace -> prefix translation
                        $name = "foo:$name";
                    }

                    join "", qq[ ], $name, qq[="], $_->{Value}, qq["];
                } values %$a
                : (),
            qq[>];

        return $foo;
    }

    sub _hash_deref {
        my $self = shift;
        $$self->{_TiedAttributes} ||= do {
            my %h;
            tie
               %h,
               "XML::Essex::Event::_tied_attributes",
               $$self->{Attributes};
            \%h;
        };
        return $$self->{_TiedAttributes};
    }

    sub isa {
        my $self = shift;
        return $_[0] eq "start_element"
            || $_[0] eq "start_elt"
            || $self->SUPER::isa( @_ );
    }

    sub generate_SAX {
        my $self = shift;
        return $self->SUPER::generate_SAX( @_ )
            unless exists $$self->{_TiedAttributes};

        my $ta = delete $$self->{_TiedAttributes};

        my $r;

        my $ok = eval {
            $r = $self->SUPER::generate_SAX( @_ );
            1;
        };
        $$self->{_TiedAttributes} = $ta;
        die $@ unless $ok;

        return $r;
    }

    @XML::Essex::Event::start_elt::ISA = qw( XML::Essex::Event::start_element );
    sub XML::Essex::Event::start_elt::new {
        my $proto = shift;
        $proto = __PACKAGE__
            if ! ref $proto && $proto eq "XML:Essex::start_elt";
        $proto->XML::Essex::Event::start_element::new( @_ )
    }

=item name

Returns the name of the node according to the namespace stringification
rules.

=cut

    sub name {
        my $self = shift;
        return XML::Essex::Model::_render_event_name( $$self );
    }

=item jclark_name

Returns the name of the node in James Clark notation.

=cut

    sub jclark_name {
        my $self = shift;
        return join( "",
            "{",
            defined $$self->{NamespaceURI}
                ? $$self->{NamespaceURI} : "",
            "}",
            $$self->{LocalName}
        );
    }

=item jclark_keys

    my @keys = $e->jclark_keys

Returns a list of attribute names in jclark notation ("{...}name").

=cut

    sub jclark_keys { keys %{${shift()}->{Attributes}} }

    package XML::Essex::Event::_tied_attributes;

    ## tie %h, "XML...", $event;

    sub TIEHASH {
        my $proto = shift;
        return bless {
            Attributes => shift,
            Wrappers   => {},
        }, $proto;
    }

    sub EXISTS {
        return
            exists shift->{Attributes}->{XML::Essex::Model::_jclarkify shift};
    }

    sub FETCH {
        my $self = shift;
        my $name = XML::Essex::Model::_jclarkify shift;

        return $self->{Wrappers}->{$name} 
            ||= XML::Essex::Event::attribute->new(
                $self->{Attributes}->{$name} ||= do {
                    my ( $ns, $name ) = XML::Essex::Model::_split_name $name;
                    {
                        LocalName    => $name,
                        NamespaceURI => $ns,
                        Value        => "",
                    }
                }
            );
    }

    sub STORE {
        my $self = shift;
        my $name = XML::Essex::Model::_jclarkify shift;
        my $value = shift;

        $self->{Attributes}->{$name} ||= do {
            my ( $ns, $name ) = XML::Essex::Model::_split_name $name;
            {
                LocalName    => $name,
                NamespaceURI => $ns,
            }
        };

        $self->{Attributes}->{$name}->{Value} = $value;
    }

    sub DELETE {
        my $self = shift;
        my $name = XML::Essex::Model::_jclarkify shift;
        delete $self->{Attributes}->{$name};
        delete $self->{Wrappers}->{$name};
    }

    sub FIRSTKEY {
        my $self = shift;
        keys %{$self->{Attributes}};  ## reset each()'s state
        ## TODO: apply ns=>prefix mappings
        my $r = each %{$self->{Attributes}};
        $r =~ s/^\{\}//;
        return $r;
    }

    sub NEXTKEY {
        my $self = shift;
        ## TODO: apply ns=>prefix mappings
        my $r = each %{$self->{Attributes}};
        $r =~ s/^\{\}//;
        return $r;
    }
}

=back

=head1 attribute

aka: attr

    my $name_attr = $start_elt->{name};
    my $attr      = attr $name;
    my $attr      = attr $name => $value;
    my $attr      = attr {
        LocalName    => $local_name,
        NamespaceURI => $ns_uri,
        Value        => $value,
    };


Stringifies as its value:   C<< harvey >>

This is not a SAX event, but an object returned from within element or
start_element objects that gives you access to the C<NamespaceUri>,
C<LocalName>, and C<Value> fields of the attribute.  Does not give
access to the Name or Prefix fields present in SAX events.

If you create an attribute with an undefined value, it will stringify
as the C<undef>ined value.  Attributes that are created without an
explicit C<undef>ined C<Value> field will be given the defaul value
of "", including attributes that are autovivified.  This allows

    get "*" until $_->{id} eq "10";

to work.  This has the side effect of addingan C<id=""> attribute to all
elements without an C<id> attribute.  To avoid the side effect, use the
C<exists> function to detect nonexistant attributes:

    get "*" until exists $_->{id} and $_->{id} eq "10";

=cut

{
    package XML::Essex::Event::attribute;

    @ISA = qw( XML::Essex::Event );

    use strict;

    use overload '""' => \&_stringify;

    sub new {
        my $self = shift->SUPER::new(
            ! ref $_[0]
                ? do {
                    my ( $ns, $name ) = XML::Essex::Model::_split_name shift;
                    my $value = @_ ? shift : "";
                    (
                        NamespaceURI => $ns,
                        LocalName    => $name,
                        Value        => $value,
                        Name         => undef,
                        Prefix       => undef,
                    )
                }
                : @_
        );

        delete $$self->{StartElement};  ## In case an ::element was passed in
        delete $$self->{EndElement};    ## In case an ::element was passed in
        delete $$self->{Content};       ## In case an ::element was passed in
        return $self;
    }

    sub type { "attribute" }

    sub types { ( __PACKAGE__, "attribute", "attr" ) }

    sub _stringify { ${shift()}->{Value} }

    sub isa {
        my $self = shift;
        return $_[0] eq "attribute"
            || $_[0] eq "attr"
            || $self->SUPER::isa( @_ );
    }

    @XML::Essex::Event::attr::ISA = qw( XML::Essex::Event::attribute );
    sub XML::Essex::Event::attr::new {
        my $proto = shift;
        $proto = __PACKAGE__
            if ! ref $proto && $proto eq "XML:Essex::attr";
        $proto->XML::Essex::Event::attribute::new( @_ )
    }
}


=head1 end_element

aka: end_elt

    my $e = end_element "foo";
    my $e = end_element $start_elt;
    my $e = end_element $end_elt;
    my $e = end_element $elt;

Stringifies as: C<< </foo> >>

See L<start_element|/start_element> for details on namespace handling.

=cut

{
    package XML::Essex::Event::end_element;

    @ISA = qw( XML::Essex::Event );

    use strict;

    use overload '""' => \&_stringify;

    sub new {
        my $self = shift->SUPER::new(
            ! ref $_[0]
                ? do {
                    my $elt_name = shift;
                    (
                        Name      => $elt_name,
                        LocalName => $elt_name,
                    )
                }
                : shift
        );

        delete $$self->{StartElement}; ## In case an ::element was passed in
        delete $$self->{Content};      ## In case an ::element was passed in
        delete $$self->{EndElement};   ## In case an ::element was passed in
        delete $$self->{Attributes};   ## ::element or ::start_element
        return $self;
    }

    sub type { "end_element" }

    sub types { ( __PACKAGE__, "end_element", "end_elt" ) }

    sub _stringify {
        my $self = shift;

        my $name = $$self->{LocalName};

        if ( defined $$self->{NamespaceURI} 
            && length $$self->{NamespaceURI}
        ) {
            ## TODO namespace -> prefix translation
            $name = "foo:$name";
        }

        return join $name, qq[</], qq[>];
    }

    sub isa {
        my $self = shift;
        return $_[0] eq "end_element"
            || $_[0] eq "end_elt"
            || $self->SUPER::isa( @_ );
    }

    @XML::Essex::Event::end_elt::ISA = qw( XML::Essex::Event::end_element );
    sub XML::Essex::Event::end_elt::new {
        my $proto = shift;
        $proto = __PACKAGE__
            if ! ref $proto && $proto eq "XML:Essex::end_elt";
        $proto->XML::Essex::Event::end_element::new( @_ )
    }
}

=head1 element

aka: elt

    my $e = elt foo => "content", $other_elt, "more content", $pi, ...;
    my $e = elt foo => { attr1 => "val1" }, "content", ...;

Stringifies as: C<< <foo attr1="val1">content</foo> >>

Never stringifies as an empty element tag (C<< <foo/> >>), although
downstream filters and handlers may choose to do that.

Constructs an element.  An element is a sequence of events between a
matching start_element and end_element, inclusive.

Attributes may be accessed using Perl hash dereferencing, as with
start_element events, see L</start_element> for details.

Content may be accessed using Perl array dereferencing:

    my @content = @$_;
    unshift @$_, "prefixed content";
    push    @$_, "appended content";

Note that

    my $elt2 = elt $elt1;   ## doesn't copy content, just name+attra

only copies the name and attributes, it does I<not> copy the content.
To copy content do either of:

    my $elt2 = elt $elt1, @$elt1;
    my $elt2 = $elt1->clone;

This is because the first parameter is converted to a start/end_element
pair and any content is ignored.  This is so that:

    my $elt2 = elt $elt1, "new content";

creates an element with the indicated content.

=head2 Methods

=over

=cut


{
    package XML::Essex::Event::element;

    @ISA = qw( XML::Essex::Event );

    use strict;

    use overload(
        '""'  => \&_stringify,
        '%{}' => sub { ${shift()}->{StartElement}->_hash_deref },
        '@{}' => sub { ${shift()}->{Content} },
    );

    sub new {
        my $proto = shift;
        my $self = $proto->SUPER::new;

        if ( @_ ) {
            my $arg1 = shift;

            $arg1 = $$arg1->{StartElement}
                if UNIVERSAL::isa( $arg1, __PACKAGE__ );

            $$self->{StartElement} = do {
                my @args;
                push @args, shift while @_ && ref $_[0] eq "HASH";
                XML::Essex::Event::start_element->new( $arg1, @args );
            };

            if ( @_ && UNIVERSAL::isa( $_[-1], "XML::Essex::Model::end_element" ) ) {
                $$self->{EndElement} = pop;
            }

            @{$$self->{Content}} = map
                ! ref $_         ? XML::Essex::Event::characters->new( $_ )
                : ref eq "ARRAY" ? XML::Essex::Event::element->new( @$_ )
                : Carp::croak( "$_ is not a content for $self" ),
                @_;
        }

        return $self;
    }

    sub _set_default_end_element {
        my $self = shift;

        return if $$self->{EndElement};

        $$self->{EndElement} = 
            XML::Essex::Event::end_element->new( $$self->{StartElement} );
    }

    ## Utility functions used in XML::Handler::Essex to build elements
    ## from incoming events.
    sub _start_element {
        my $self = shift;
        $$self->{StartElement} = shift if @_;
        $$self->{StartElement};
    }

    sub _add_content {
        my $self = shift;
        push @{$$self->{Content}}, shift;
    }

    sub _end_element {
        my $self = shift;
        $$self->{EndElement} = shift if @_;
        $$self->{EndElement};
    }

    sub clone {
        my $clone = shift->SUPER::clone;

        $_ = $_->clone for $clone->{StartElement},
            @{$clone->{Content}},
            $clone->{EndElement};

        return $clone;
    }

    sub type { "element" }

    sub types { ( __PACKAGE__, "element", "elt" ) }

    sub _stringify {
        my $self = shift;

        Carp::croak "Can't stringify element with no start_element event"
            unless $$self->{StartElement};

        $self->_set_default_end_element;

        return join "",
            $$self->{StartElement},
            @{$$self->{Content}},
            $$self->{EndElement};
    }


    sub isa {
        my $self = shift;
        return $_[0] eq "element"
            || $_[0] eq "elt"
            || $self->SUPER::isa( @_ );
    }

    sub generate_SAX {
        my $self = shift;
        Carp::croak "Can't generate SAX events for element with no start_element event"
            unless $$self->{StartElement};

        $self->_set_default_end_element;

        $_->generate_SAX( @_ )
            for $$self->{StartElement},
                @{$$self->{Content}},
                $$self->{EndElement};
    }

    @XML::Essex::Event::elt::ISA = qw( XML::Essex::Event::element );
    sub XML::Essex::Event::elt::new {
        my $proto = shift;
        $proto = __PACKAGE__
            if ! ref $proto && $proto eq "XML:Essex::elt";
        $proto->XML::Essex::Event::element::new( @_ )
    }

=item jclark_keys

Returns the names of attributes as a list of JamesClarkified
keys, just like start_element's C<jclark_keys()>.

=cut

    sub jclark_keys { ${shift()}->{StartElement}->jclark_keys }

=item name

Returns the name of the node according to the namespace stringification
rules.

=cut

    sub name { ${shift()}->{StartElement}->name }

=item jclark_name

Returns the name of the node in James Clark notation.

=cut

    sub jclark_name { ${shift()}->{StartElement}->jclark_name }
}

=back

=head1 characters

aka: chars

    my $e = chars "A stitch", " in time", " saves nine";
    my $e = chars {
        Data => "A stitch in time saves nine",
    };

Stringifies like a string: C<< A stitch in time saves nine. >>

Character events are aggregated.

TODO: make that aggregation happen.

=cut

{
    package XML::Essex::Event::characters;

    @ISA = qw( XML::Essex::Event );

    use strict;

    use overload '""' => \&_stringify;

    sub new {
        my $self = shift->SUPER::new(
            ! ref $_[0]
                ? (
                    Data => join( "", @_ ),
                )
                : shift
        );

        return $self;
    }

    sub type { "characters" }

    sub types { ( __PACKAGE__, "characters", "chars" ) }

    sub _stringify { ${shift()}->{Data} };

    sub isa {
        my $self = shift;
        return $_[0] eq "characters"
            || $_[0] eq "chars"
            || $self->SUPER::isa( @_ );
    }

    @XML::Essex::Event::chars::ISA = qw( XML::Essex::Event::characters );
    sub XML::Essex::Event::chars::new {
        my $proto = shift;
        $proto = __PACKAGE__
            if ! ref $proto && $proto eq "XML:Essex::chars";
        $proto->XML::Essex::Event::characters::new( @_ )
    }
}

=head1 comment

aka: (no abbreviation)

    my $e = comment "A stitch in time saves nine";
    my $e = comment {
        Data => "A stitch in time saves nine",
    };

Stringifies like a string: C<< A stitch in time saves nine. >>

=cut

{
    package XML::Essex::Event::comment;

    @ISA = qw( XML::Essex::Event );

    use strict;

    use overload '""' => \&_stringify;

    sub new {
        my $self = shift->SUPER::new(
            ! ref $_[0]
                ? (
                    Data => shift,
                )
                : shift
        );

        return $self;
    }

    sub type { "comment" }

    sub types { ( __PACKAGE__, "comment" ) }

    sub _stringify { ${shift()}->{Data} };

    sub isa {
        my $self = shift;
        return $_[0] eq "comment"
            || $self->SUPER::isa( @_ );
    }
}

=head1 Implementation Details

=head2 References and blessed, tied or overloaded SAX events.

Instances of the Essex object model classes carry a reference to the
original data (SAX events), rather than copying it.  This means that
there are fewer copies (a good thing; though there is an increased cost
of getting at any data in the events) and that upstream filters may send
blessed, tied, or overloaded objects to us and they will not be molested
unless the Essex filter messes with them.  There is also an
implementation reason for this, it makes overloading hash accesses
like C<$_->{}> easier to implement.

Passing an Essex event to a constructor for a new Essex event does
result in a deep copy of the referenced data (via
C<XML::Essex::Event::clone()>).

=head2 Class files, or the lack thereof

The objects in the Essex object model are not available independantly
as class files.  You must use C<XML::Essex::Model> to get at them.  This
is because there is a set of event types used in almost all SAX filters
and it is cheaper to compile one file containing these than to open
multiple files.

This does not mean that all classes are loaded when the
XML::Essex::Model is C<use()>ed or C<require()>ed, rare events are
likely to be autoloaded.

=head2 Class names

In order to allow

    my $e = XML::Essex::start_elt( ... );

to work as expected--in case the calling package prefers not to import
C<start_elt()>, for instance--the objects in the model are all in the
XML::Essex::Event::... namespace, like
C<XML::Essex::Event::start_element>.

=head1 TODO

=over

=item Allow escaping to be configured

=item Allow " vs. ' for attr quotes to be configured.

=item Allow CDATA to be tested for, either by stringifying it or by
allowing it to be returned as an array or something.

=back

=for the future
=head1 LIMITATIONS

=head1 COPYRIGHT

    Copyright 2002, R. Barrie Slaymaker, Jr., All Rights Reserved

=head1 LICENSE

You may use this module under the terms of the BSD, Artistic, oir GPL licenses,
any version.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1;
