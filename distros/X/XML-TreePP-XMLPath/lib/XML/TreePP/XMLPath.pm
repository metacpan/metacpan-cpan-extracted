=pod

=head1 NAME

XML::TreePP::XMLPath - Similar to XPath, defines a path as an accessor to nodes of an XML::TreePP parsed XML Document.

=head1 SYNOPSIS

    use XML::TreePP;
    use XML::TreePP::XMLPath;
    
    my $tpp = XML::TreePP->new();
    my $tppx = XML::TreePP::XMLPath->new();
    
    my $tree = { rss => { channel => { item => [ {
        title   => "The Perl Directory",
        link    => "http://www.perl.org/",
    }, {
        title   => "The Comprehensive Perl Archive Network",
        link    => "http://cpan.perl.org/",
    } ] } } };
    my $xml = $tpp->write( $tree );

Get a subtree of the XMLTree:

    my $xmlsub = $tppx->filterXMLDoc( $tree , q{rss/channel/item[title="The Comprehensive Perl Archive Network"]} );
    print $xmlsub->{'link'};

Iterate through all attributes and Elements of each <item> XML element:

    my $xmlsub = $tppx->filterXMLDoc( $tree , q{rss/channel/item} );
    my $h_attr = $tppx->getAttributes( $xmlsub );
    my $h_elem = $tppx->getElements( $xmlsub );
    foreach $attrHash ( @{ $h_attr } ) {
        while my ( $attrKey, $attrVal ) = each ( %{$attrHash} ) {
            ...
        }
    }
    foreach $elemHash ( @{ $h_elem } ) {
        while my ( $elemName, $elemVal ) = each ( %{$elemHash} ) {
            ...
        }
    }

EXAMPLE for using XML::TreePP::XMLPath to access a non-XML compliant tree of
PERL referenced data.

    use XML::TreePP::XMLPath;
    
    my $tppx = new XML::TreePP::XMLPath;
    my $hashtree = {
        config => {
            nodes => {
                "10.0.10.5" => {
                    options => [ 'option1', 'option2' ],
                    alerts => {
                        email => 'someone@nowhere.org'
                    }
                }
            }
        }
    };
    print $tppx->filterXMLDoc($hashtree, '/config/nodes/10.0.10.5/alerts/email');
    print "\n";
    print $tppx->filterXMLDoc($hashtree, '/config/nodes/10.0.10.5/options[2]');
    print "\n";

Result
    
    someone@nowhere.org
    option2

=head1 DESCRIPTION

A pure PERL module to compliment the pure PERL XML::TreePP module. XMLPath may
be similar to XPath, and it does attempt to conform to the XPath standard when
possible, but it is far from being fully XPath compliant.

Its purpose is to implement an XPath-like accessor methodology to nodes in a
XML::TreePP parsed XML Document. In contrast, XPath is an accessor methodology
to nodes in an unparsed (or raw) XML Document.

The advantage of using XML::TreePP::XMLPath over any other PERL implementation
of XPath is that XML::TreePP::XMLPath is an accessor to XML::TreePP parsed
XML Documents. If you are already using XML::TreePP to parse XML, you can use
XML::TreePP::XMLPath to access nodes inside that parsed XML Document without
having to convert it into a raw XML Document.

As an additional side-benefit, any PERL HASH/ARRY reference data structure can
be accessible via the XPath accessor method provided by this module. It does
not have to a parsed XML structure. The last example in the SYNOPSIS illustrates
this.

=head1 REQUIREMENTS

The following perl modules are depended on by this module:
( I<Note: Dependency on Params::Validate was removed in version 0.52; Dependency on Data::Dump was removed in version 0.64> )

=over 4

=item *     XML::TreePP

=item *     Data::Dumper

=back

=head1 IMPORTABLE METHODS

When the calling application invokes this module in a use clause, the following
methods can be imported into its space.

=over 4

=item *     C<parseXMLPath>

=item *     C<assembleXMLPath>

=item *     C<filterXMLDoc>

=item *     C<getValues>

=item *     C<getAttributes>

=item *     C<getElements>

=back

Example:

    use XML::TreePP::XMLPath qw(parseXMLPath filterXMLDoc getValues getAttributes getElements);

=head1 REMOVED METHODS

The following methods are removed in the current release.

=over 4

=item *     C<validateAttrValue>

=item *     C<getSubtree>

=back

=head1 XMLPath PHILOSOPHY

=head2 General Illustration of XMLPath

Referring to the following XML Data.

    <paragraph>
        <sentence language="english">
            <words>Do red cats eat yellow food</words>
            <punctuation>?</punctuation>
        </sentence>
        <sentence language="english">
            <words>Brown cows eat green grass</words>
            <punctuation>.</punctuation>
        </sentence>
    </paragraph>

Where the path "C<paragraph/sentence[@language=english]/words>" has two matches:
"C<Do red cats eat yellow food>" and "C<Brown cows eat green grass>".

Where the path "C<paragraph/sentence[@language]>" has the same previous two
matches.

Where the path "C<paragraph/sentence[2][@language=english]/words>" has one
match: "C<Brown cows eat green grass>".

And where the path "C<paragraph/sentence[punctuation=.]/words>" matches 
"C<Brown cows eat green grass>"

So that "C<[@attr=val]>" is identified as an attribute inside the
"<tag attr='val'></tag>"

And "C<[attr=val]>" is identified as a nested attribute inside the
"<tag><attr>val</attr></tag>"

And "C<[2]>" is a positional argument identifying the second node in a list
"<tag><attr>value-1</attr><attr>value-2</attr></tag>".

And "C<@attr>" identifies all nodes containing the C<@attr> attribute.
"<tag><item attr="value-A">value-1</item><item attr="value-B">value-2</item></tag>".

After XML::TreePP parses the above XML, it looks like this:

    {
      paragraph => {
            sentence => [
                  {
                    "-language" => "english",
                    punctuation => "?",
                    words => "Do red cats eat yellow food",
                  },
                  {
                    "-language" => "english",
                    punctuation => ".",
                    words => "Brown cows eat green grass",
                  },
                ],
          },
    }

=head2 Noting Attribute Identification in Parsed XML

Note that attributes are specified in the XMLPath as C<@attribute_name>, but
after C<XML::TreePP::parse()> parses the XML Document, the attribute name is
identified as C<-attribute_name> in the resulting parsed document.
This can be changed in Object Oriented mode using the
C<$tppx->tpp->set(attr_prefix=>'@')> method to set the attr_prefix attribute in
the XML::TreePP object referenced internally. It should only be changed if the
XML Document is provided as already parsed, and the attributes are represented
with a value other than the default.
This document uses the default value of C<-> in its examples.

XMLPath requires attributes to be specified as C<@attribute_name> and takes care
of the conversion from C<@> to C<-> behind the scenes when accessing the
XML::TreePP parsed XML document.

Child elements on the next level of a parent element are accessible as
attributes as C<attribute_name>. This is the same format as C<@attribute_name>
except without the C<@> symbol. Specifying the attribute without an C<@> symbol
identifies the attribute as a child element of the parent element being
evaluated.

=head2 Noting Text (CDATA) Identification in Parsed XML

Additionally, the values of child elements are identified in XML parsed by
C<XML::TreePP::parse()> with the C<#> pound/hash symbol. This can be changed
via the C<text_node_key> property in the C<XML::TreePP> object referenced by
C<XML::TreePP::XMLPath->tpp()>. C<XML::TreePP::XMLPath> derives the value to
use from this.

=head2 Accessing Child Element Values in XMLPath

Child element values are only accessible as C<CDATA>. That is when the
element being evaluated is C<animal>, the attribute (or child element) is
C<cat>, and the value of the attribute is C<tiger>, it is presented as this:

    <jungle>
        <animal>
            <cat>tiger</cat>
        </animal>
    </jungle>

The XMLPath used to access the key=value pair of C<cat=tiger> for element
C<animal> would be as follows:

    jungle/animal[cat='tiger']

And in version 0.52, in this second case, the above XMLPath is still valid:

    <jungle>
        <animal>
            <cat color="black">tiger</cat>
        </animal>
    </jungle>

In version 0.52, the period (.) is supported as it is in XPath to represent
the current context node. As such, the following XMLPaths would also be valid:

    jungle/animal/cat[.='tiger']
    jungle/animal/cat[@color='black'][.='tiger']

One should realize that in these previous two XMLPaths, the element C<cat> is
being evaluated, and not the element C<animal> as in the first case. And will
be undesirable if you want to evaluate C<animal> for results.

To perform the same evaluation, but return the matching C<animal> node, the
following XMLPath can be used:

    jungle/animal[cat='tiger']

To evaluate C<animal> and C<cat>, but return the matching C<cat> node, the
following XMLPaths can be used:

    jungle/animal[cat='tiger']/cat
    jungle/animal/cat[.='tiger']

The first path analyzes C<animal>, and the second path analyzes C<cat>. But
both matches the same node "<cat color='black>tiger</cat>".

=head2 Matching Attributes

Prior to version 0.52, attributes could only be used in XMLPath to evaluate
an element for a result set.
As of version 0.52, attributes can now be matched in XMLPath to return their
values.

This next example illustrates:

    <jungle>
        <animal>
            <cat color="black">tiger</cat>
        </animal>
    </jungle>
    
    /jungle/animal/cat[.='tiger']/@color

The result set of this XMLPath would be "C<black>".

=head1 METHODS

=cut

package XML::TreePP::XMLPath;

use 5.005;
use strict;
use warnings;
use Exporter;
use Carp;
use XML::TreePP;
use Data::Dumper;

BEGIN {
    use vars          qw(@ISA @EXPORT @EXPORT_OK);
    @ISA            = qw(Exporter);
    @EXPORT         = qw();
    @EXPORT_OK      = qw(&charlexsplit &getAttributes &getElements &getSubtree &parseXMLPath &assembleXMLPath &filterXMLDoc &getValues);

    use vars          qw($REF_NAME);
    $REF_NAME       = "XML::TreePP::XMLPath";  # package name

    use vars          qw( $VERSION $TPPKEYS );
    $VERSION        = '0.72';
    $TPPKEYS        = "force_array force_hash cdata_scalar_ref user_agent http_lite lwp_useragent base_class elem_class xml_deref first_out last_out indent xml_decl output_encoding utf8_flag attr_prefix text_node_key ignore_error use_ixhash";

    use vars          qw($DEBUG $DEBUGMETHOD $DEBUGNODE $DEBUGPATH $DEBUGFILTER $DEBUGDUMP);
    $DEBUG          = 0;
    $DEBUGMETHOD    = 1;
    $DEBUGNODE      = 2;
    $DEBUGPATH      = 3;
    $DEBUGFILTER    = 4;
    $DEBUGDUMP      = 7;
}


=pod

=head2 tpp

=over

This module is an extension of the XML::TreePP module. As such, it uses the
module in many different methods to parse XML Documents, and to get the value
of C<XML::TreePP> properties like C<attr_prefix> and C<text_node_key>.

The C<XML::TreePP> module, however, is only loaded into C<XML::TreePP::XMLPath>
when it becomes necessary to perform the previously described requests. For the
aformentioned properties C<attr_prefix> and C<text_node_key>, default values
are used if a C<XML::TreePP> object has not been loaded.

To avoid having this module load the XML::TreePP module,
do not pass in unparsed XML documents. The caller would instead want to
parse the XML document with C<XML::TreePP::parse()> before passing it in.
Passing in an unparsed XML document causes this module to load C<XML::TreePP>
in order to parse it for processing.

Alternately, If the caller has loaded a copy of C<XML::TreePP>, that object
instance can be assigned to be used by the instance of this module using this
method. In doing so, when XML::TreePP is needed, the instance provided is used
instead of loading another copy.

If this module has loaded an instance of <XML::TreePP>, this instance can be
directly accessed or retrieved through this method. For example, the
aformentioned properties can be set.

    $tppx->tpp->set('attr_prefix','@');  # default is (-) dash
    $tppx->tpp->set('text_node_key','#');  # default is (#) pound

If you want to only get the internally loaded instance of C<XML::TreePP>, but
do not want to load a new instance and instead have undef returned if an
instance is not already loaded, then use the C<get()> method.

    my $tppobj = $tppx->get( 'tpp' );
    warn "XML::TreePP is not loaded in XML::TreePP::XMLPath.\n" if !defined $tppobj;

This method was added in version 0.52

=over 4

=item * B<XML::TreePP>

An instance of XML::TreePP that this object should use instead of, when needed,
loading its own copy. If not provided, the currently loaded instance is
returned. If an instance is not loaded, an instance is loaded and then returned.

=item * I<returns>

Returns the result of setting an instance of XML::TreePP in this object.
Or returns the internally loaded instance of XML::TreePP.
Or loads a new instance of XML::TreePP and returns it.

=back

    $tppx->tpp( new XML::TreePP );  # Sets the XML::TreePP instance to be used by this object
    $tppx->tpp();  # Retrieve the currently loaded XML::TreePP instance

=back

=cut

sub tpp(@) {
    my $self    = shift if ref($_[0]) eq $REF_NAME || undef;
    if (!defined $self) {
        return new XML::TreePP;
    } else {
        return $self->{'tpp'} = shift if @_ >= 1 && ref($_[0]) eq "XML::TreePP";
        return $self->{'tpp'} if defined $self->{'tpp'} && ref($self->{'tpp'}) eq "XML::TreePP";
        $self->{'tpp'} = new XML::TreePP;
        return $self->{'tpp'};
    }
}


=pod

=head2 set

=over

Set the value for a property in this object instance.
This method can only be accessed in object oriented style.

This method was added in version 0.52

=over 4

=item * B<propertyname>

The property to set the value for.

=item * B<propertyvalue>

The value of the property to set.
If no value is given, the property is deleted.

=item * I<returns>

Returns the result of setting the value of the property, or the result of
deleting the property.

=back

    $tppx->set( 'property_name' );            # deletes the property property_name
    $tppx->set( 'property_name' => 'val' );   # sets the value of property_name

=back

=cut

sub set(@) {
    my $self    = shift if ref($_[0]) eq $REF_NAME || return undef;
    my %args    = @_;
    while (my ($key,$val) = each %args) {
        if ( defined $val ) {
            $self->{$key} = $val;
        }
        else {
            delete $self->{$key};
        }
    }
}


=pod

=head2 get

=over

Retrieve the value set for a property in this object instance.
This method can only be accessed in object oriented style.

This method was added in version 0.52

=over 4

=item * B<propertyname>

The property to get the value for

=item * I<returns>

Returns the value of the property requested

=back

    $tppx->get( 'property_name' );

=back

=cut

sub get(@) {
    my $self    = shift if ref($_[0]) eq $REF_NAME || return undef;
    my $key     = shift;
    return $self->{$key} if exists $self->{$key};
    return undef;
}


=pod

=head2 new

=over

Create a new object instances of this module.

=over 4

=item * B<tpp>

An instance of XML::TreePP to be used instead of letting this module load its
own.

=item * I<returns>

An object instance of this module.

=back

    $tppx = new XML::TreePP::XMLPath();

=back

=cut

# new
#
# It is not necessary to create an object of this module.
# However, if you choose to do so any way, here is how you do it.
#
#    my $obj = new XML::TreePP::XMLPath;
#
# This module supports being called by two methods.
# 1. By importing the functions you wish to use, as in:
#       use XML::TreePP::XMLPath qw( function1 function2 );
#       function1( args )
# 2. Or by calling the functions in an object oriented manor, as in:
#       my $tppx = new XML::TreePP::XMLPath()
#       $tppx->function1( args )
# Using either method works the same and returns the same output.
#
sub new {
    my $pkg	= shift;
    my $class	= ref($pkg) || $pkg;
    my $self	= bless {}, $class;

    my %args    = @_;
    $self->tpp($args{'tpp'}) if exists $args{'tpp'};

    return $self;
}


=pod

=head2 charlexsplit

=over

An analysis method for single character boundary and start/stop tokens

=over 4

=item * B<string>

The string to analyze

=item * B<boundry_start>

The single character starting boundary separating wanted elements

=item * B<boundry_stop>

The single character stopping boundary separating wanted elements

=item * B<tokens>

A { start_char => stop_char } hash reference of start/stop tokens.
The characters in C<string> contained within a start_char and stop_char are not
evaluated to match boundaries.

=item * B<boundry_begin>

Provide "1" if the beginning of the string should be treated as a 
C<boundry_start> character.

=item * B<boundry_end>

Provide "1" if the ending of the string should be treated as a C<boundry_stop>
character.

=item * B<escape_char>

The character that indicates the next character in the string is to be escaped.
The default value is the backward slash (\). And example is used in the
following string:

    'The Cat\'s Meow'

Without a recognized escape character, the previous string would fail to be
recognized properly.

This optional parameter was introduced in version 0.70. 

=item * I<returns>

An array reference of elements

=back

    $elements = charlexsplit (
                        string         => $string,
                        boundry_start  => $charA,   boundry_stop   => $charB,
                        tokens         => \@tokens,
                        boundry_begin  => $char1,   boundry_end    => $char2 );

=back

=cut

# charlexsplit
# @brief    A lexical analysis function for single character boundary and start/stop tokens
# @param    string          the string to analyze
# @param    boundry_start   the single character starting boundary separating wanted elements
# @param    boundry_stop    the single character stopping boundary separating wanted elements
# @param    tokens          a { start_char => stop_char } hash reference of start/stop tokens
# @param    boundry_begin   set to "1" if the beginning of the string should be treated as a 'boundry_start' character
# @param    boundry_end     set to "1" if the ending of the string should be treated as a 'boundry_stop' character
# @param    escape_char     the character that indicates the next character in the string is to be escaped. default is '\'
# @return   an array reference of the resulting parsed elements
#
# Example:
# {
# my @el = charlexsplit   (
#   string        => q{abcdefg/xyz/path[@key='val'][@key2='val2']/last},
#   boundry_start => '/',
#   boundry_stop  => '/',
#   tokens        => [qw( [ ] ' ' " " )],
#   boundry_begin => 1,
#   boundry_end   => 1
#   );
# print join(', ',@el),"\n";
# my @el2 = charlexsplit (
#   string        => $el[2],
#   boundry_start => '[',
#   boundry_stop  => ']',
#   tokens        => [qw( ' ' " " )],
#   boundry_begin => 0,
#   boundry_end   => 0
#   );
# print join(', ',@el2),"\n";
# my @el3 = charlexsplit (
#   string        => $el2[0],
#   boundry_start => '=',
#   boundry_stop  => '=',
#   tokens        => [qw( ' ' " " )],
#   boundry_begin => 1,
#   boundry_end   => 1
#   );
# print join(', ',@el3),"\n";
#
# OUTPUT:
# abcdefg, xyz, path[@key='val'][@key2='val2'], last
# @key='val', @key2='val2'
# @key, 'val'
#
sub charlexsplit (@) {
    my $self            = shift if ref($_[0]) eq $REF_NAME || undef;
    my %args            = @_;
    my @warns;
    push(@warns,'string')           if !defined $args{'string'};
    push(@warns,'boundry_start')    if !exists $args{'boundry_start'};
    push(@warns,'boundry_stop')     if !exists $args{'boundry_stop'};
    push(@warns,'tokens')           if !exists $args{'tokens'};
    if (@warns) { carp ('method charlexsplit(@) requires the arguments: '.join(', ',@warns).'.'); return undef; }

    my $string          = $args{'string'};        # The string to parse
    my $boundry_start   = $args{'boundry_start'}; # The boundary character separating wanted elements
    my $boundry_stop    = $args{'boundry_stop'};  # The boundary character separating wanted elements
    my %tokens          = @{$args{'tokens'}};     # The start=>stop characters that must be paired inside an element
    my $boundry_begin   = $args{'boundry_begin'} || 0;
    my $boundry_end     = $args{'boundry_end'} || 0;
    my $escape_char     = $args{'escape_char'} || "\\";


    # split the string into individual characters
    my @string  = split(//,$string);

    # initialize variables
    my $next = undef;
    my $current_element = undef;
    my @elements;
    my $collect = 0;
    my $escape_char_flag = 0;

    if ($boundry_begin == 1) {
        $collect = 1;
    }
    CHAR: foreach my $c (@string) {
        if ($c eq $escape_char) {
            $current_element .= $c;
            $escape_char_flag = 1;
            next CHAR;
        }
        if ($escape_char_flag) {
            $current_element .= $c;
            $escape_char_flag = 0;
            next CHAR;
        }
        if (!defined $next) {       # If not looking for the 'stop' matching token
            if ($c eq $boundry_stop) {                  # If this character matches the boundry_stop character...
                if (defined $current_element) {         # -and the current_element is defined...
                    push(@elements,$current_element);   # -put the current element in the elements array...
                    $current_element = undef;           # -stop collecting elements.
                }
                if ($boundry_start ne $boundry_stop) {  # -and the start and stop boundaries are different
                    $collect = 0;                       # -turn off collection
                } else {
                    $collect = 1;                       # -but keep collection on if the boundaries are the same
                }
                next CHAR;              # Process the next character if this character matches the boundry_stop character.
            }
            if ($c eq $boundry_start) {                 # If this character matches the boundry_start character...
                $collect = 1;                           # -turn on collection
                next CHAR;              # Process the next character if this character matches the boundry_start character.
            }
        }   # continue if the current character does not match stop|start boundry, or if we are looking for the 'stop' matching token (do not turn off collection)
        TKEY: foreach my $tkey (keys %tokens) {
            if (! defined $next) {  # If not looking for the 'stop' matching token
                if ($c eq $tkey) {          # If this character matches the 'start' matching token...
                    $next = $tokens{$tkey}; # -start looking for the 'stop' matching token
                    last TKEY;
                }
            } elsif
               (defined $next) {                # If I am looking for the 'stop' matching token
                if ($c eq $next) {          # If this character matches the 'stop' matching token...
                    $next = undef;          # -then I am no longer looking for the 'stop' matching token.
                    last TKEY;
                }
            }
        }
        if ($collect == 1) {
            $current_element .= $c;
        }
    }
    if ($boundry_end == 1) {
        if (defined $current_element) {
            push(@elements,$current_element);
            $current_element = undef;
        }
    }

    return \@elements if @elements >= 1;
    return undef;
}


=pod

=head2 parseXMLPath

=over

Parse a string that represents the XMLPath to a XML element or attribute in a
XML::TreePP parsed XML Document.

Note that the XML attributes, known as "@attr" are transformed into "-attr".
The preceding (-) minus in place of the (@) at is the recognized format of
attributes in the XML::TreePP module.

Being that this is intended to be a submodule of XML::TreePP, the format of 
'@attr' is converted to '-attr' to conform with how XML::TreePP handles
attributes.

See: C<XML::TreePP->set( attr_prefix => '@' )> for more information.
This module supports the default format, '-attr', of attributes. But this can
be changed by setting the 'attr_prefix' property in the internally referenced
XML::TreePP object using the C<set()> method in object oriented programming.
Example:

    my $tppx = new XML::TreePP::XMLPath();
    $tppx->tpp->set( attr_prefix => '@' );

B<XMLPath Filter by index and existence>
Also, as of version 0.52, there are two additional types of XMLPaths understood.

I<XMLPath with indexes, which is similar to the way XPath does it>

    $path = '/books/book[5]';

This defines the fifth book in a list of book elements under the books root.
When using this to get the value, the 5th book is returned.
When using this to test an element, there must be 5 or more books to return true.

I<XMLPath by existence, which is similar to the way XPath does it>

    $path = '/books/book[author]';

This XMLPath represents all book elements under the books root which have 1 or
more author child element. It does not evaluate if the element or attribute to
evaluate has a value. So it is a test for existence of the element or attribute.

=over 4

=item * B<XMLPath>

The XML path to be parsed.

=item * I<returns>

An array reference of array referenced elements of the XMLPath.

=back

    $parsedXMLPath = parseXMLPath( $XMLPath );

=back

=cut

# parseXMLPath
# something like XPath parsing, but it is not
# @param    xmlpath     the XML path to be parsed
# @return   an array reference of hash reference elements of the path
#
# Example:
# use Data::Dumper;
# print Dumper (parseXMLPath(q{abcdefg/xyz/path[@key='val'][key2=val2]/last}));
#
# OUTPUT:
#  $VAR1 = [
#          [ 'abcdefg', undef ],
#          [ 'xyz', undef ],
#          [ 'path', 
#            [
#              [ '-key', 'val' ],
#              [ 'key2', 'val2' ]
#            ]
#          ],
#          [ 'last', undef ]
#        ];
#
# Philosophy:
# <paragraph>
#     <sentence language="english">
#         <words>Do red cats eat yellow food</words>
#         <punctuation>?</punctuation>
#     </sentence>
#     <sentence language="english">
#         <words>Brown cows eat green grass</words>
#         <punctuation>.</punctuation>
#     </sentence>
# <paragraph>
# Where the path 'paragraph/sentence[@language=english]/words' matches 'Do red cats eat yellow food'
# (Note this is because it is the first element of a multi element match)
# And the path 'paragraph/sentence[punctuation=.]/words' matches 'Brown cows eat green grass'
# So that '@attr=val' is identified as an attribute inside the <tag attr=val></tag>
# And 'attr=val' is identified as a nested attribute inside the <tag><attr>val</attr></tag>
#
# Note the format of '@attr' is converted to '-attr' to conform with how XML::TreePP handles this
#
sub parseXMLPath ($) {
    my $self        = shift if ref($_[0]) eq $REF_NAME || undef;
    unless (@_ == 1) { carp 'method parseXMLPath($) requires one argument.'; return undef; }
    my $path        = shift;
    my $hpath       = [];
    my ($tpp,$xml_text_id,$xml_attr_id);

    if ((defined $self) && (defined $self->get('tpp'))) {
        $tpp         = $self ? $self->tpp() : tpp();
        $xml_text_id = $tpp->get( 'text_node_key' ) || '#text';
        $xml_attr_id = $tpp->get( 'attr_prefix' )   || '-';
    } else {
        $xml_text_id = '#text';
        $xml_attr_id = '-';
    }

    my $h_el = charlexsplit   (
        string        => $path,
        boundry_start => '/',
        boundry_stop  => '/',
        tokens        => [qw( [ ] ' ' " " )],
        boundry_begin => 1,
        boundry_end   => 1
        );
    foreach my $el (@{$h_el}) {
        # See: XML::TreePP->set( attr_prefix => '@' );, where default is '-'
        $el =~ s/^\@/$xml_attr_id/;
        my $h_param = charlexsplit (
            string        => $el,
            boundry_start => '[',
            boundry_stop  => ']',
            tokens        => [qw( ' ' " " )],
            boundry_begin => 0,
            boundry_end   => 0
        ) || undef;
        if (defined $h_param) {
            my ($el2) = $el =~ /^([^\[]*)/;
            my $ha_param = [];
            foreach my $param (@{$h_param}) {
                my ($attr,$val);
                #
                # define string values here
                # defined first, as string is recognized as the default
                ($attr,$val) = $param =~ /([^\=]*)\=[\'\"]?(.*[^\'\"])[\'\"]?/;
                if ((! defined $attr) && (! defined $val)) {
                    ($attr) = $param =~ /([^\=]*)\=[\'\"]?[\'\"]?/;
                    $val = '';
                }
                if ((! defined $attr) && (! defined $val)) {
                    ($attr) = $param =~ /^([^\=]*)$/;
                    $val = undef;
                }
                #
                # define literal values here, which are not string-values
                # defined second, as literals are strictly defined
                if ($param =~ /^(\d*)$/) {
                    # It is a positional argument, ex: /books/book[3]
                    $attr = $1;
                    $val  = undef;
                } elsif ($param =~ /^([^\=]*)$/) {
                    # Only the element/attribute is defined, ex: /path[@attr]
                    $attr = $1;
                    $val  = undef;
                }
                #
                # Internal - convert the attribute identifier
                # See: XML::TreePP->set( attr_prefix => '@' );, where default is '-'
                $attr =~ s/^\@/$xml_attr_id/;
                #
                # push the result
                push (@{$ha_param},[$attr, $val]);
            }
            push (@{$hpath},[$el2, $ha_param]);
        } else {
            push (@{$hpath},[$el, undef]);
        }

    }
    return $hpath;
}

=pod

=head2 assembleXMLPath

=over

Assemble an ARRAY or HASH ref structure representing an XMLPath. This method
can be used to construct an XMLPath array ref that has been parsed by the
parseXMLPath method.

Note that the XML attributes can be identified as "-attribute" or "@attribute".
When identified as "-attribute', they are transformed into "@attribute" upon
assembly. The preceding minus (-) in place of the at (@) is the recognized
format of attributes in the C<XML::TreePP> module, though can be changed. See
the C<parseXMLPath> method for further information.

This method was added in version 0.70.


=over 4

=item * B<parsed-XMLPath>

The XML path to be assembled, represented as either an ARRAY or HASH reference.

=item * I<returns>

An XMLPath.

=back

    $XMLPath = assembleXMLPath( $parsedXMLPath );

or

    my $xmlpath = q{/books/book[5]/cats[@author="The Cat's Meow"]/tigers[meateater]};
    
    my $ppath = $tppx->parseXMLPath($xpath);
    ## $ppath == [['books',undef],['book',[['5',undef]]],['cats',[['-author','The Cat\'s Meow']]],['tigers',[['meateater',undef]]]]

    my $apath = [ 'books', ['book', 5], ['cats',[['@author' => "The Cat's Meow"]]], ['tigers',['meateater']] ];
    my $hpath = { books => { book => { -attrs => [5], cats => { -attrs => [['-author' => "The Cat's Meow"]], tigers => { -attrs => ["meateater"] } } } } };
    
    print "original: ",$xmlpath,"\n";
    print "      re: ",$tppx->assembleXMLPath($ppath),"\n";
    print "   array: ",$tppx->assembleXMLPath($apath),"\n";
    print "    hash: ",$tppx->assembleXMLPath($hpath),"\n";

output

    original: /books/book[5]/cats[@author="The Cat's Meow"]/tigers[meateater]
          re: /books/book[5]/cats[@author="The Cat's Meow"]/tigers[meateater]
       array: /books/book[5]/cats[@author="The Cat's Meow"]/tigers[meateater]
        hash: /books/book[5]/cats[@author="The Cat's Meow"]/tigers[meateater]

=back

=cut

sub assembleXMLPath ($) {
    my $self        = shift if ref($_[0]) eq $REF_NAME || undef;
    unless (@_ == 1) { carp 'method assembleXMLPath($) requires one argument.'; return undef; }
    my $ref_path    = shift;
    my $path        = undef;
    my ($tpp,$xml_text_id,$xml_attr_id);

    if ((defined $self) && (defined $self->get('tpp'))) {
        $tpp         = $self ? $self->tpp() : tpp();
        $xml_text_id = $tpp->get( 'text_node_key' ) || '#text';
        $xml_attr_id = $tpp->get( 'attr_prefix' )   || '-';
    } else {
        $xml_text_id = '#text';
        $xml_attr_id = '-';
    }

    my $assemble_attributes = sub ($) {
        my $attrs = shift || return undef;
        if ((defined $attrs) && (! ref $attrs)) {
            return ('['.$attrs.']');
        }
        elsif (ref $attrs eq "SCALAR") {
            return ('['.${$attrs}.']');
        }
        return undef unless ref $attrs eq "ARRAY";
        my $path;
        foreach my $itemattr (@{$attrs}) {
            my ($key,$val);
            if (ref $itemattr eq "ARRAY") {
                ($key,$val) = @{$itemattr};
            }
            else {
                $key = $itemattr;
            }
            next unless defined $key;
            
            if (($key =~ /^\d+$/) && (! defined $val)) {
                $path .= ('['.$key.']');
            }
            elsif (($key =~ /^\-(.*)/) || ($key =~ /^\@(.*)/)) {
                my $keystring = $1;
                if (defined $val) {
                    $val =~ s/\"/\\\"/g;
                    $path .= ('[@'.$keystring.'="'.$val.'"]');
                }
                else {
                    $path .= ('[@'.$keystring.']');
                }
            }
            else {
                if (defined $val) {
                    $val =~ s/\"/\\\"/g;
                    $path .= ('['.$key.'="'.$val.'"]');
                }
                else {
                    $path .= ('['.$key.']');
                }
            }
        }
        return $path;
    };

    # Reassemble a path parsed by parseXMLPath()
    if (ref $ref_path eq "ARRAY") {
        foreach my $pathitem (@{$ref_path}) {
            $path .= "/";
            my ($param,$attrs);
            if (ref $pathitem eq "ARRAY") {
                ($param,$attrs) = @{$pathitem};
            }
            else {
                $param = $pathitem;
            }
            $path .= $param;
            if (my $param_attrs = $assemble_attributes->($attrs)) {
                $path .= $param_attrs;
            }
        }
    }
    # Assemble a path represented by a hash
    elsif (ref $ref_path eq "HASH") {
        my $recurse = sub ($) {};
        $recurse = sub ($) {
            my $this_path = shift;
            my $path;
            foreach my $pathitem (keys %{$this_path}) {
                next if $pathitem eq "-attrs";
                $path .= "/";
                $path .= $pathitem;
                my $attrs = $this_path->{$pathitem}->{'-attrs'};
                if (my $pathitem_attrs = $assemble_attributes->($attrs)) {
                    $path .= $pathitem_attrs;
                }
                if (my $recursed_path = $recurse->($this_path->{$pathitem})) {
                    $path .= $recursed_path;
                }
                last;
            }
            return $path;
        };
        $path = $recurse->($ref_path);
    }

    return $path;
}

=pod

=head2 filterXMLDoc

=over

To filter down to a subtree or set of subtrees of an XML document based on a
given XMLPath

This method can also be used to determine if a node within an XML tree is valid
based on the given filters in an XML path.

This method replaces the two methods C<getSubtree()> and C<validateAttrValue()>.

This method was added in version 0.52

=over 4

=item * B<XMLDocument>

The XML document tree, or subtree node to validate.
This is an XML document either given as plain text string, or as parsed by the
C<XML::TreePP->parse()> method.

The XMLDocument, when parsed, can be an ARRAY of multiple elements to evaluate,
which would be validated as follows:

    # when path is: context[@attribute]
    # returning: $subtree[item] if valid (returns all validated [item])
    $subtree[item]->{'-attribute'} exists
    # when path is: context[@attribute="value"]
    # returning: $subtree[item] if valid (returns all validated [item])
    $subtree[item]->{'-attribute'} eq "value"
    $subtree[item]->{'-attribute'}->{'value'} exists
    # when path is: context[5]
    # returning: $subtree[5] if exists (returns the fifth item if validated)
    $subtree['itemnumber']
    # when path is: context[5][element="value"]
    # returning: $subtree[5] if exists (returns the fifth item if validated)
    $subtree['itemnumber']->{'element'} eq "value"
    $subtree['itemnumber']->{'element'}->{'value'} exists

Or the XMLDocument can be a HASH which would be a single element to evaluate.
The XMLSubTree would be validated as follows:

    # when path is: context[element]
    # returning: $subtree if validated
    $subtree{'element'} exists
    # when path is: context[@attribute]
    # returning: $subtree if validated
    $subtree{'-attribute'} eq "value"
    $subtree{'-attribute'}->{'value'} exists

=item * B<XMLPath>

The path within the XML Tree to retrieve. See C<parseXMLPath()>

=item * B<structure> => C<TargetRaw> | C<RootMAP> | C<ParentMAP>  (optional)

This optional argument defines the format of the search results to be returned.
The default structure is C<TargetRaw>

TargetRaw - Return references to xml document fragments matching the XMLPath
filter. If the matching xml document fragment is a string, then the string is
returned as a non-reference.

RootMap - Return a Map of the entire xml document, a result set (list) of the
definitive XMLPath (mapped from the root) to the found targets, which includes:
(1) a reference map from root (/) to all matching child nodes
(2) a reference to the xml document from root (/)
(3) a list of targets as absolute XMLPath strings for the matching child nodes

    { root      => HASHREF,
      path      => '/',
      target    => [ "/nodename[#]/nodename[#]/nodename[#]/targetname" ],
      child     =>
        [{ name => nodename, position => #, child => [{
            [{ name => nodename, position => #, child => [{
                [{ name => nodename, position => #, target => targetname }]
            }] }]
        }] }]
    }

ParentMap - Return a Map of the parent nodes to found target nodes in the xml
document, which includes:
(1) a reference map from each parent node to all matching child nodes
(2) a reference to xml document fragments from the parent nodes

    [
    { root      => HASHREF,
      path      => '/nodename[#]/nodename[6]/targetname',
      child => [{ name => nodename, position => 6, target => targetname }]
    },
    { root      => HASHREF,
      path      => '/nodename[#]/nodename[7]/targetname',
      child => [{ name => nodename, position => 7, target => targetname }]
    },
    ]

=item * I<returns>

The parsed XML Document subtrees that are validated, or undef if not validated

You can retrieve the result set in one of two formats.

    # Option 1 - An ARRAY reference to a list
    my $result = filterXMLDoc( $xmldoc, '/books' );
    # $result is:
    # [ { book => { title => "PERL", subject => "programming" } },
    #   { book => { title => "All About Backpacks", subject => "hiking" } } ]
    
    # Option 2 - A list, or normal array
    my @result = filterXMLDoc( $xmldoc, '/books/book[subject="camping"]' );
    # $result is:
    # ( { title => "campfires", subject => "camping" },
    #   { title => "tents", subject => "camping" } )

=back

    my $result = filterXMLDoc( $XMLDocument , $XMLPath );
    my @result = filterXMLDoc( $XMLDocument , $XMLPath );

=back

=cut

sub filterXMLDoc (@) {
    my $self        = shift if ref($_[0]) eq $REF_NAME || undef;
    unless (@_ >= 2) { carp 'method filterXMLDoc($$) requires two arguments.'; return undef; }
    my $tree        = shift || (carp 'filterXMLDoc($$) requires two arguments.' && return undef);
    my $path        = shift || (carp 'filterXMLDoc($$) requires two arguments.' && return undef);
    my %options     = @_; # Additional optional options:
                          # structure => TargetRaw | RootMAP | ParentMAP
    my $o_structure = $options{'structure'} ? $options{'structure'} : "TargetRaw";
    my ($tpp,$xtree,$xpath,$xml_text_id,$xml_attr_id);

    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Purity = 1;
    local $Data::Dumper::Terse = 1;

    if ((defined $self) && (defined $self->get('tpp'))) {
        $tpp         = $self ? $self->tpp() : tpp();
        $xml_text_id = $tpp->get( 'text_node_key' ) || '#text';
        $xml_attr_id = $tpp->get( 'attr_prefix' )   || '-';
    } else {
        $xml_text_id = '#text';
        $xml_attr_id = '-';
    }
    if (ref $tree) { $xtree = $tree;
                   }
    elsif (!defined $tree)
                   { $xtree = undef
                   }
              else { if (!defined $tpp) { $tpp = $self ? $self->tpp() : tpp(); }
                     $xtree = $tpp->parse($tree) if defined $tree;
                   }
    if (ref $path) { $xpath = eval (Dumper($path)); # make a copy of inputted parsed XMLPath
                   }
              else { $xpath = parseXMLPath($path);
                   }

    # This is used on the lowest level of an element, and is the
    # execution of our rules for matching or validating a value
    my $validateFilter = sub (@) {
        my %args            = @_;
        print ("="x8,"sub:filterXMLDoc|validateFilter->()\n") if $DEBUG >= $DEBUGMETHOD;
        print (" "x8,"= attempting to validate filter, with: ", Dumper(\%args) ,"\n") if $DEBUG >= $DEBUGDUMP;
        # we accept:
        # - required: node,param,comparevalue ; optional: operand(=) (= is default)
        # not accepted: - required: node,param,operand(exists)
        return 0 if !exists $args{'node'} || !exists $args{'comparevalue'};
        # Node possibilities this method is expecting to see:
        # VALUE: 'Henry'                        -asin-> { people => { person => 'Henry' } }
        # VALUE: [ 'Henry', 'Sally' ]           -asin-> { people => { person => [ 'Henry', 'Sally' ] } }
        # VALUE: { id => 45, #text => 'Henry' } -asin-> { people => { person => { id => 45, #text => 'Henry' } } }
        # Also, comparevalue could be '', an empty string
        # comparevalue of undef is attempted to be matched here, because operand defaults to "eq" or "="
        if (ref $args{'node'} eq "HASH") {
            if (exists $args{'node'}->{$xml_text_id}) {
                return 1 if defined $args{'node'}->{$xml_text_id} && defined $args{'comparevalue'} && $args{'node'}->{$xml_text_id} eq "" && $args{'comparevalue'} eq "";
                return 1 if !defined $args{'node'}->{$xml_text_id} && !defined $args{'comparevalue'};
                return 1 if $args{'node'}->{$xml_text_id} eq $args{'comparevalue'};
            }
        } elsif (ref $args{'node'} eq "ARRAY") {
            foreach my $value (@{$args{'node'}}) {
                if (ref $value eq "HASH") {
                    if (exists $value->{$xml_text_id}) {
                        return 1 if defined $value->{$xml_text_id} && defined $args{'comparevalue'} && $value->{$xml_text_id} eq "" && $args{'comparevalue'} eq "";
                        return 1 if !defined $value->{$xml_text_id} && !defined $args{'comparevalue'};
                        return 1 if $value->{$xml_text_id} eq $args{'comparevalue'};
                    }
                } else {
                    return 1 if defined $value && defined $args{'comparevalue'} && $value eq "" && $args{'comparevalue'} eq "";
                    return 1 if !defined $value && !defined $args{'comparevalue'};
                    return 1 if $value eq $args{'comparevalue'};
                }
            }
        } elsif (ref $args{'node'} eq "SCALAR") { # not likely -asin-> { people => { person => \$value } }
            return 1 if defined ${$args{'node'}} && defined $args{'comparevalue'} && ${$args{'node'}} eq "" && $args{'comparevalue'} eq "";
            return 1 if !defined ${$args{'node'}} && !defined $args{'comparevalue'};
            return 1 if ${$args{'node'}} eq $args{'comparevalue'};
        } else {  # $node =~ /\w/
            return 1 if defined $args{'node'} && defined $args{'comparevalue'} && $args{'node'} eq "" && $args{'comparevalue'} eq "";
            return 1 if !defined $args{'node'} && !defined $args{'comparevalue'};
            return 1 if $args{'node'} eq $args{'comparevalue'};
        }
        return 0;
    }; #end validateFilter->();

    my $extractFilterPosition = sub (@) {
        my $filters = shift;
        my $position = undef;
        # Process the first filter, if it exists, for positional testing
        # If a positional argument is given, shift to the item located at
        # that position
        # Yes, this does mean the positional argument must be the first filter.
        # But then again, this would not make clear sense: /books/book[author="smith"][5]
        # And this path makes more clear sense: /books/book[5][author="smith"]
        if ( (defined $filters)              &&
             (defined $filters->[0])         &&
             ($filters->[0]->[0] =~ /^\d*$/) &&
             (! defined $filters->[0]->[1])  &&
             ($filters->[0]->[0] >= 1) ) {
            print (" "x12,"= processing list position filter. Extracting first filter.\n") if $DEBUG >= $DEBUGFILTER;
            my $lpos         = shift @{$filters};  # This also deletes the positional filter from passed in filter REF
            $position        = $lpos->[0]; # if $lpos >= 1;
        }
        return $position if defined $position && $position >= 1;
        return undef;
    };

    # So what do we support as filters
    # /books/book[@id="value"]      # attribute eq value
    # /books/book[title="value"]    # element eq value
    # /books/book[@type]            # Attribute exists
    # /books/book[author]           # element exists
    # Not yet: /books/book[publisher/address/city="value"]   # sub/child element eq value
    # And what are some of the things we do not support
    # /books/book[publisher/address[country="US"]/city="value"]   # sub/child element eq value based on another filter
    # /books/book[5][./title=../book[4]/title]  # comparing the values of two elements
    my $processFilters = sub ($$) {
        print ("="x8,"sub:filterXMLDoc|processFilters->()\n") if $DEBUG >= $DEBUGMETHOD;
        my $xmltree_child           = shift;
        my $filters                 = shift;
        print ("++++ELEMENT:".Dumper($xmltree_child)."\n") if $DEBUG >= $DEBUGDUMP;
        print ("++++ FILTER:".Dumper($filters)."\n") if $DEBUG >= $DEBUGDUMP;
        my $filters_processed_count = 0; # Will catch a filters error of [[][][]] or something
        my $param_match_flag        = 0;
        if ((!defined $filters) || (@{$filters} == 0)) {
            # If !defined $filters or if $filters = []
            return $xmltree_child;
        }
        FILTER: foreach my $filter (@{$filters}) {
            next if !defined $filter; # if we get empty filters;
            $filters_processed_count++;

            my $param = $filter->[0];
            my $value = $filter->[1];
            print (" "x8,"= processing filter: " . $param) if $DEBUG >= $DEBUGFILTER;
            print (" , " . $value) if defined $value && $DEBUG >= $DEBUGFILTER;
            print ("\n") if $DEBUG >= $DEBUGFILTER;

            # attribute/element exists filter
            # deal with special #text/$xml_text_id element
            if (ref $xmltree_child eq "HASH") {
                if (($param ne ".") && (! exists $xmltree_child->{$param})) {
                    $param_match_flag = 0;
                    last FILTER;
                } elsif ((($param eq ".") || (exists $xmltree_child->{$param})) && (! defined $value)) {
                    # NOTE, maybe filter needs to be [['attr'],['attr','val']] for this one
                    $param_match_flag = 1;
                    next FILTER;
                }
            } elsif (   ($param eq $xml_text_id)
                     && (($xmltree_child =~ /\w+/) || ((ref $xmltree_child eq "SCALAR") && (${$xmltree_child} =~ /\w+/)))) {
                $param_match_flag = 1;
                next FILTER;
            } else {
                # else ref $xmltree_child eq "ARRAY" or "BLOB" or something
                $param_match_flag = 0;
                last FILTER;
            }

            print (" "x12,"= about to validate filter.\n") if $DEBUG >= $DEBUGFILTER;
            if (     ($param ne ".") &&
                     ($validateFilter->( node => $xmltree_child->{$param},
                                      operand => '=',
                                 comparevalue => $value))
                ) {
                print (" "x12,"= validated filter.\n") if $DEBUG >= $DEBUGFILTER;
                $param_match_flag = 1;
                next FILTER;
            } elsif (($param eq ".") &&
                     ($validateFilter->( node => $xmltree_child,
                                      operand => '=',
                                 comparevalue => $value))
                ) {
                print (" "x12,"= validated filter.\n") if $DEBUG >= $DEBUGFILTER;
                $param_match_flag = 1;
                next FILTER;
            } else {
                print (" "x12,"= unvalidated filter.\n") if $DEBUG >= $DEBUGFILTER;
                $param_match_flag = 0;
                last FILTER;
            }

            # Examples of what $xmltree_child->{$param} can be
            # (Perhaps this info should be bundled with $validateFilter->() method)
            # 1. A SCALAR ref will probably never occur
            # 2a. An ARRAY ref of strings
            #    PATH: /people[person='Henry']
            #    XML: <people><person>Henry</person><person>Sally</person></people>
            #    PARSED: { people => { person => [ 'Henry', 'Sally' ] } }
            # 2b. or ARRAY ref or HASH refs
            #    XML: <people><person id='1'>Henry</person><person id='2'>Sally</person></people>
            #    PARSED: { people => { person => [ { id => 1, #text => 'Henry' }, { id => 2, #text => 'Sally' } ] } }
            # 3. A HASH when in cases like this:
            #    PATH: /people/person[@id=45]
            #    XML: <people><person id="45">Henry</person></people>
            #    PARSED: { people => { person => { id => 45, #text => 'Henry' } } }
            # 4. The most likely encounter of plain old text/string values
            #    PATH: /people/person
            #    XML: <people><person>Henry</person></people>
            #    PARSED: { people => { person => 'Henry' } }

        } #end FILTER
        if ($filters_processed_count == 0) {
            # there was some unusual error which caused a lot of undef filters
            # And as such, $param_match_flag will be 0
            # we return the entire tree as valid
            return $xmltree_child;
        } elsif ($param_match_flag == 0) {
            # filters were processed, but there was no matches
            # we return undef because nothing validated
            return undef;
        } else {
            return $xmltree_child;
        }
    }; #end processFilters->()

    # mapAssemble(), mapChildExists() and mapTran() are utilized for the ParentMap and RootMap options
    my $mapAssemble = sub (@) {};
    $mapAssemble = sub (@) {
        my $mapObj = shift;
        my $rootpath = $_[0] || $mapObj->{'path'} || '/';
        $rootpath .= '/' if $rootpath !~ /\/$/;
        my @paths;
        foreach my $child (@{$mapObj->{'child'}}) {
            my $tmppath .= ($rootpath.$child->{'name'}."[".$child->{'position'}."]");
            if (exists $child->{'child'}) {
                my $rpaths = $mapAssemble->($child,$tmppath);
                if (ref($rpaths) eq "ARRAY") {
                    push(@paths,@{$rpaths});
                } else {
                    push(@paths,$rpaths);
                }
            } elsif (exists $child->{'target'}) {
                if (defined $child->{'target'}) {
                    $tmppath .= ("/".$child->{'target'});
                }
                push(@paths,$tmppath);                
            }
        }
        return \@paths;
    };
    # mapAssemble(), mapChildExists() and mapTran() are utilized for the ParentMap and RootMap options
    my $mapChildExists = sub (@) {
        my $mapObj  = shift;
        my $child   = shift;
        foreach my $cmap (@{$mapObj->{'child'}}) {
            if (   ($cmap->{'name'} eq $child->{'name'})
                && ($cmap->{'position'} eq $child->{'position'})) {
                return $cmap;
            }
        }
        return 0;
    };
    # mapAssemble(), mapChildExists() and mapTran() are utilized for the ParentMap and RootMap options
    my $mapTran = sub (@) {};
    $mapTran = sub (@) {
        my $mapObj  = shift;
        my %args    = @_;   # action => new | assemble | child => { name => S, position => #, target => S }
        if (! defined $mapObj) {
            if ((exists $args{'action'}) && ($args{'action'} eq "new")) {
                $mapObj = {};
                return ($mapObj);
            } else {
                return undef;
            }
        }
        if ((exists $args{'action'}) && ($args{'action'} eq "childcount")) {
            return (ref($mapObj->{'child'}) eq "ARRAY") ? @{$mapObj->{'child'}} : 0;
        }
        if (exists $args{'child'}) {  # && (exists $args{'child'}->{'name'}) && (exists $args{'child'}->{'position'})) {
            $mapObj->{'child'} = [] if ref($mapObj->{'child'}) ne "ARRAY";
            my $newchild = $args{'child'};
            if (my $cmap = $mapChildExists->($mapObj,$newchild)) {
                # If the child already exists, try to merge the two childs.
                # merging will attempt to add the child's child(s) to the mapObj's child if the child's child(s) do not already exist.
                if (ref($newchild->{'child'}) eq "ARRAY") {
                    foreach my $nc_child (@{$newchild->{'child'}}) {
                        if ($mapTran->($cmap, child => $nc_child)) {
                            return $newchild;
                        }
                    }
                } else {
                    return undef;
                }
            } else {
                # Add the child if it does not already exist
                push (@{$mapObj->{'child'}}, $newchild);
                return $newchild;
            }
        }
        if ((exists $args{'action'}) && ($args{'action'} eq "assemble")) {
            return $mapAssemble->("",$mapObj);
        }
    };

    # whatisnode() looks at the nodename to determine what it is
    my $whatisnode = sub ($) {
        my $nodename = shift;
        return undef        if ref($nodename);
        return "text"       if $nodename eq $xml_text_id;
        return "attribute"  if $nodename =~ /^$xml_attr_id\w+$/;
        return "parent"     if $nodename eq '..';
        return "current"    if $nodename eq '.';
        return "element";
    };

    # bctrail() is the breadcrumb trail, so we can find our way back to the root node
    my $bctrail = sub (@) {
        my $bcobj   = shift || return undef;
        my $action  = shift || return undef;
        if ($action eq "addnode") {
            push(@{$bcobj},@_);
            return 1;
        } elsif ($action eq "poplast") {
            my $j = pop(@{$bcobj});
            return $j;
        } elsif ($action eq "clone") {
            my @clone;
            foreach my $noderef (@{$bcobj}) {
                push(@clone,$noderef);
            }
            return \@clone;
        } elsif ($action eq "length") {
            my $num = @{$bcobj};
            return $num;
        }
        return undef;
    };

    # find() is the primary searching function
    my $find = sub (@) {};
    $find = sub (@) {
        my $xmltree         = shift;  # The parsed XML::TreePP tree
        my $xmlpath         = shift;  # The parsed XML::TreePP::XMLPath path
        my $thisnodemap     = shift || undef;
        my $breadcrumb      = shift || [];
        print ("="x8,"sub::filterXMLDoc|_find()\n") if $DEBUG >= $DEBUGMETHOD;
        print (" "x7,"=attempting to find path: ", Dumper($xmlpath) ,"\n") if $DEBUG >= $DEBUGDUMP;
        print (" "x7,"=attempting to search in: ", Dumper($xmltree) ,"\n") if $DEBUG >= $DEBUGDUMP;
        if (($DEBUG >= 1) && ($DEBUG <= 5)) {
            print ( "-"x11 . "# Descending in search with criteria: " . "\n");
            print ( Dumper({ nodemap => $thisnodemap }) . "\n");
            print ( Dumper({ xmlpath => $xmlpath }) . "\n");
            print ( Dumper({ xmlfragment => $xmltree }) . "\n");
        }

        my (@found,@maps);
        #print (" "x8, "searching begins on node with nodemap:", Dumper ($thisnodemap) if $DEBUG > 5;
        # If there are no more path to analyze, return
        if ((ref($xmlpath) ne "ARRAY") || (! @{$xmlpath} >= 1)) {
            print (" "x12,"= end of path reached\n") if $DEBUG >= $DEBUGPATH;
            # FOUND: XMLPath is satisfied, Return $xmltree as a found target
            $thisnodemap->{'target'} = undef;
            push(@found, $xmltree);
        }

        # Otherwise, we have more path to analyze - @{$xmlpath} is >= 1

        if (@found == 0) {
        if (! ref($xmltree)) {
            print ("-"x12,"= search tree is TEXT (non-REF)\n") if $DEBUG >= $DEBUGPATH;
            # This should almost always return undef
            # The only exception is if $element eq '.', as in "/path/to/element/."

            my $path_element    = shift @{$xmlpath};
            my $element         = shift @{$path_element};
            my $filters         = shift @{$path_element};

            my $elementposition = $extractFilterPosition->($filters);
            if ( (($element =~ /\w+/) && ($element ne '.')) || ((defined $elementposition) && (! $elementposition >= 2)) ) {
                return undef;
            }
            if (@{$xmlpath} >= 1) {
                return undef;
            }

            if (    ((!defined $filters) || (@{$filters} < 1))
                 || ( defined $processFilters->($xmltree,$filters) )   ) {
                push(@found,$xmltree);
            }
        } elsif (ref $xmltree eq "ARRAY") {
            print ("-"x12,"= search tree is ARRAY\n") if $DEBUG >= $DEBUGPATH;
            # If $xmltree is an array, and not a HASH, then we are not searching
            # an XML::TreePP parsed XML Document, so we just keep descending
            # Instead, this tree might look something like:
            # { parent=>[ {child1=> CDATA},{child2=>[["v1","v2","v3"],["vA","vB","vC"]]} ] }
            # A normal expected XML::TreePP tree will not have arrays of arrays
            foreach my $singlexmltree (@{$xmltree}) {
                my $bc_clone = $bctrail->($breadcrumb,"clone"); # do not addnode $xmltree, because ref $xmltree eq ARRAY
                my $result = $find->($singlexmltree,$xmlpath,$thisnodemap,$bc_clone);
                next unless defined $result;
                push(@found,@{$result}) if ref($result) eq "ARRAY";
                push(@found,$result) if ref($result) ne "ARRAY";
            }
        } elsif (ref $xmltree eq "HASH") {
            print ("-"x12,"= search tree is HASH\n") if $DEBUG >= $DEBUGPATH;
            # Pretty much all the searching is done here

            my $path_element    = shift @{$xmlpath};
            my $element         = shift @{$path_element};
            my $filters         = shift @{$path_element};

            my $elementposition = $extractFilterPosition->($filters);

            my $result;
            my $nodetype = $whatisnode->($element);
            if ($nodetype eq "text") {
                print ("-"x12,"= search tree node (".$element.") is text\n") if $DEBUG >= $DEBUGNODE;
                # Filters are not allowed in text elements directly
                # Alt is to give: '/path/to/sub[#text="my value"]/#text
                # However, perhaps we should allow: '/path/to/sub/#text[.="my value"]
                return undef if (@{$xmlpath} >= 1); # Cannot descend as path dictates, so no match
                return undef if defined $elementposition && $elementposition >= 2; # There is only one child node
                print (" "x8,"= end of path reached with text CDATA\n") if $DEBUG > 1;
                if ( defined $processFilters->($xmltree->{$element},$filters) ) {
                    $thisnodemap->{'target'} = $element;  # $element eq '#text'
                    $result = $xmltree->{$element};
                } else {
                    print ("-"x12,"= node (text) did not pass filters.\n") if $DEBUG >= $DEBUGNODE;
                    return undef;
                }
            } elsif ($nodetype eq "attribute") {
                print ("-"x12,"= search tree node (".$element.") is sttribute\n") if $DEBUG >= $DEBUGNODE;
                # Filters are not allowed on attribute elements directly
                # Alt is to give: '/path/to/sub[@attrname="my value"]/@attrname
                # However, perhaps we should allow: '/path/to/sub/@attrname[.="my value"]
                return undef if (@{$xmlpath} >= 1); # Cannot descend as path dictates, so no match
                return undef if defined $elementposition && $elementposition >= 2; # There is only one child node
                print (" "x8,"= end of path reached with attribute\n") if $DEBUG >= $DEBUGPATH;
                if ( defined $processFilters->($xmltree->{$element},$filters) ) {
                    $thisnodemap->{'target'} = $element;
                    $result = $xmltree->{$element};
                } else {
                    print ("-"x12,"= node (attribute) did not pass filters.\n") if $DEBUG >= $DEBUGNODE;
                    return undef;
                }
            } elsif (($nodetype eq "element") && (! ref($xmltree->{$element})) ) {
                print ("-"x12,"= search tree node (".$element.") is element with text CDATA\n") if $DEBUG >= $DEBUGNODE;
                # Here must take care of matching the abscence of #text
                # eg: /path/to/element == /path/to/element/#text if element =~ /\w+/
                unless (   (defined $xmltree->{$element}) && ($xmltree->{$element} =~ /\w+/)
                        && (   ((ref($xmlpath) eq "ARRAY") && (@{$xmlpath} == 1))
                            && ($whatisnode->($xmlpath->[0]->[0]) eq "text") 
                            && (defined $processFilters->($xmltree->{$element},$xmlpath->[0]->[1])) ) ) {
                    return undef if (@{$xmlpath} >= 1); # Cannot descend as path dictates, so no match
                    return undef if defined $elementposition && $elementposition >= 2; # There is only one child node
                }
                print ("-"x16,"60= nodetype is element with text on final path\n") if $DEBUG >= $DEBUGNODE;
                if ( defined $processFilters->($xmltree->{$element},$filters) ) {
                    my $childmap = { name => $element, position => 1, target => undef };
                    $mapTran->($thisnodemap, child => $childmap );
                    $result = $xmltree->{$element};
                } else {
                    print ("-"x16,"= node (element) did not pass filters.\n") if $DEBUG >= $DEBUGNODE;
                    return undef;
                }
            } elsif ($nodetype eq "parent") {
                print ("-"x12,"= search tree node (".$element.") is parent node\n") if $DEBUG >= $DEBUGNODE;
                return undef if defined $elementposition && $elementposition >= 2; # This is not supported, as parent (..) is the parent hash, not array
                my $crumb      = $bctrail->($breadcrumb,"poplast"); # get the parent from the end of the breadcrumb trail
                my $parentnode = $crumb->[0];
                my $parentmap  = $crumb->[1];
                return undef unless defined $parentnode;
                if ( defined $processFilters->($parentnode,$filters) ) {
                    # If there were no filters, path was something like '/path/to/../element'
                    # If there were filters, path was something like '/path/to/..[filter]/element'
                    $result = $find->($parentnode,$xmlpath,$parentmap,$breadcrumb);
                } else {
                    print ("-"x16,"= node (parent) did not pass filters.\n") if $DEBUG >= $DEBUGNODE;
                    return undef;
                }
            } elsif ($nodetype eq "current") {
                print ("-"x12,"= search tree node (".$element.") is current node\n") if $DEBUG >= $DEBUGNODE;
                return undef if defined $elementposition && $elementposition >= 2; # The current node is always a hash
                if ( defined $processFilters->($xmltree,$filters) ) {
                    # If there were no filters, path was something like '/path/to/./element'
                    # If there were filters, path was something like '/path/to/.[filter]/element'
                    $result = $find->($xmltree,$xmlpath,$thisnodemap,$breadcrumb);
                } else {
                    print ("-"x16,"= node (current) did not pass filters.\n") if $DEBUG >= $DEBUGNODE;
                    return undef;
                }
            } elsif ($nodetype eq "element") {
                print ("-"x12,"= search tree node (".$element.") is element with REF\n") if $DEBUG >= $DEBUGNODE;
                if ( ref($xmltree->{$element}) eq "HASH" ) {
                    print ("-"x16,"= search tree node (".$element.") is element with REF HASH\n") if $DEBUG >= $DEBUGNODE;
                    return undef if defined $elementposition && $elementposition >= 2; # There is only one child node, as a hash
                    if ( defined $processFilters->($xmltree->{$element},$filters) ) {
                        my $childmap = { name => $element, position => 1 };
                        $bctrail->($breadcrumb,"addnode",[$xmltree,$thisnodemap]);
                        $result = $find->($xmltree->{$element},$xmlpath,$childmap,$breadcrumb);
                        $bctrail->($breadcrumb,"poplast");
                        if (defined $result) {
                            $mapTran->($thisnodemap, child => $childmap );
                        }
                    } else {
                        print ("-"x16,"= node (element[hash]) did not pass filters.\n") if $DEBUG >= $DEBUGNODE;
                        return undef;
                    }
                } elsif (( ref($xmltree->{$element}) eq "ARRAY" ) && (defined $elementposition) && ($elementposition >= 1)) {
                    print ("-"x16,"= search tree node (".$element.") is element with REF ARRAY position $elementposition\n") if $DEBUG >= $DEBUGNODE;
                    if ( defined $processFilters->($xmltree->{$element},$filters) ) {
                        my $childmap = { name => $element, position => $elementposition };
                        $bctrail->($breadcrumb,"addnode",[$xmltree,$thisnodemap]);
                        $result = $find->($xmltree->{$element}->[($elementposition - 1)],$xmlpath,$childmap,$breadcrumb);
                        $bctrail->($breadcrumb,"poplast");
                        if (defined $result) {
                            $mapTran->($thisnodemap, child => $childmap );
                        }
                    } else {
                        print ("-"x16,"= node (element[array]) did not pass filters.\n") if $DEBUG >= $DEBUGNODE;
                        return undef;
                    }
                } elsif ( ref($xmltree->{$element}) eq "ARRAY" ) {
                    print ("-"x16,"= search tree node (".$element.") is element with REF ARRAY\n") if $DEBUG >= $DEBUGNODE;
                    my $xmlpos = 0;
                    $bctrail->($breadcrumb,"addnode",[$xmltree,$thisnodemap]);
                    foreach my $sub (@{$xmltree->{$element}}) {
                        # print (" "x20, "filtering child node:", Dumper({ sub => $sub, target => $xmlpath->[0]->[0] }) if $DEBUG > 5;
                        $xmlpos++;
                        my ($mresult,$childmap);
                        my $tmpfilters = eval( Dumper($filters) );
                        my $tmpxmlpath = eval( Dumper($xmlpath) );
                        my ($bc_clone);
                        if (   ((!ref($sub)) && ($sub =~ /\w+/))
                            && (   ((ref($xmlpath) eq "ARRAY") && (@{$xmlpath} == 1))
                                && ($whatisnode->($xmlpath->[0]->[0]) eq "text") 
                                && (defined $processFilters->($sub,$tmpxmlpath->[0]->[1])) ) ) {
                            $childmap = { name => $element, position => $xmlpos, target => undef };
                            $mresult = $xmltree->{$element}->[($xmlpos - 1)];
                        } elsif ( defined $processFilters->($sub,$tmpfilters) ) {
                            print ("-"x16,"= node at position ".$xmlpos." passed filters.\n") if $DEBUG >= $DEBUGNODE;
                            $childmap = { name => $element, position => $xmlpos };
                            $bc_clone = $bctrail->($breadcrumb,"clone");
                            $mresult = $find->($sub,$tmpxmlpath,$childmap,$bc_clone);
                        } else {
                            print ("-"x16,"= node (element) at position ".$xmlpos." did not pass filters.\n") if $DEBUG >= $DEBUGNODE;
                            next;
                        }
                        if (defined $mresult) {
                            push(@{$result},@{$mresult}) if ref($mresult) eq "ARRAY";
                            push(@{$result},$mresult) if ref($mresult) ne "ARRAY";
                            $mapTran->($thisnodemap, child => $childmap );
                        }
                    }
                    $bctrail->($breadcrumb,"poplast");
                } else {
                    print ("-"x12,"= search tree node (".$element.") is element with REF but is not REF ARRAY or HASH\n") if $DEBUG >= $DEBUGNODE;
                }
            }

            if (ref($result) eq "ARRAY") {
                push(@found,@{$result}) unless @{$result} == 0;
            } else {
                push(@found,$result) unless !defined $result;
            }
        }
        }
        #print (" "x8, "searching ended on node with nodemap:", Dumper ($thisnodemap) if $DEBUG > 5;
        return undef if @found == 0;
        return \@found;
    }; # end find->()

    # pathsplit() takes a parsed XML::TreePP::XMLPath, and splits it into two
    # XML::TreePP::XMLPath paths. The path to the parent node and the path to
    # the child node. The child XML::TreePP::XMLPath is the path to the child
    # node plus the target, and including any filters.
    # ( $parent, ($child ."/". $target) ) = $pathsplit->(parsed XML::TreePP::XMLPath)
    my $pathsplit = sub ($) {
        my $parent_path = shift;
        $parent_path = eval(Dumper($parent_path));
        my ($child_path,$string_element); # string_element is #text or @attribute if exists in path
        if (   ($whatisnode->($parent_path->[ (@{$parent_path}-1) ]->[0]) eq "text")
            || ($whatisnode->($parent_path->[ (@{$parent_path}-1) ]->[0]) eq "attribute") ) {
            unshift( @{$child_path}, pop @{$parent_path} ); # $parent_path becomes just the <node> without #text/@attr
            unshift( @{$child_path}, pop @{$parent_path} ); # $parent_path becomes the parent <node>
        } else {
            # whatis eq element
            unshift( @{$child_path}, pop @{$parent_path} ); # $parent_path becomes the parent <node>
        }
        return ($parent_path,$child_path);
    };

    # structure => TargetRaw | RootMAP | ParentMAP
    my ($found,$thismap);
    if ($o_structure =~ /^RootMap$/i) {
        $thismap = { root => $xtree, path => '/' };         # the root map
        if (($DEBUG >= 1) && ($DEBUG <= 5)) {
            print ("-"x11,"# Searching for the path within the root node." . "\n");
        }
        $found = $find->($xtree,$xpath,$thismap);           # results from searching root
        $thismap->{'target'} = $mapAssemble->($thismap);    # assemble the absolute XMLPaths to all targets
        return undef if ! defined $thismap;
    } elsif ($o_structure =~ /^ParentMap$/i) {
        my ($p_xpath,$c_xpath) = $pathsplit->($xpath);      # split XMLPath into parent node and child node paths
        my $rootmap = { root => $xtree, path => '/' };      # the root map
        if (($DEBUG >= 1) && ($DEBUG <= 5)) {
            print ("-"x11,"# Searching for the parent path within the root node." . "\n");
        }
        my $p_found = $find->($xtree,$p_xpath,$rootmap);    # results from searching root
        my $p_path = $mapAssemble->($rootmap);              # assemble the absolute XMLPaths to all targets to parent nodes
        foreach my $p_xtree (@{$p_found}) {                 # search each parent xml document fragment for its child nodes
            my $parentmap = { root => $p_xtree, path => (shift(@{$p_path})) };  # create the map for the parent node
            my $tmpc_xpath = eval(Dumper($c_xpath));                            # make a copy of the child XMLPath
            if (($DEBUG >= 1) && ($DEBUG <= 5)) {
                print ("-"x11,"# Searching for the child path within the parent node." . "\n");
            }
            my $c_found = $find->($p_xtree,$tmpc_xpath,$parentmap);             # results from searching parent
            next if !defined $c_found;
            push(@{$found},@{$c_found}) if ref($c_found) eq "ARRAY";
            push(@{$found},$c_found) if ref($c_found) ne "ARRAY";
            push(@{$thismap},$parentmap);
        }
    } else {
        $thismap = undef;
        $found = $find->($xtree,$xpath);
    }

    if (($DEBUG >= 1) && ($DEBUG <= 5)) {
        print ("-"x11,"# Search yielded results." . "\n") if defined $thismap || defined $found;
    }
    if (($DEBUG) && (defined $thismap)) {
        print Dumper({ structure => $o_structure, thismap => $thismap });
    } elsif (($DEBUG) && (defined $found)) {
        print Dumper({ structure => $o_structure, results => $found });
    }

    if (($o_structure =~ /^RootMap$/i) || ($o_structure =~ /^ParentMap$/i)) {
        $thismap = [$thismap] if ref $thismap ne "ARRAY";
        return undef if (! defined $thismap || @{$thismap} == 0) && !defined wantarray;
        return (@{$thismap}) if !defined wantarray;
        return wantarray ? @{$thismap} : $thismap;
    }
    return undef if ! defined $found;
    $found = [$found] if ref $found ne "ARRAY";
    return undef if (! defined $found || @{$found} == 0) && !defined wantarray;
    return (@{$found}) if !defined wantarray;
    return wantarray ? @{$found} : $found;
}


=pod

=head2 getValues

=over

Retrieve the values found in the given XML Document at the given XMLPath.

This method was added in version 0.53 as getValue, and changed to getValues in 0.54

=over 4

=item * B<XMLDocument>

The XML Document to search and return values from.

=item * B<XMLPath>

The XMLPath to retrieve the values from.

=item * B<valstring> => C<1> | C<0>

Return values that are strings. (default is 1)

=item * B<valxml> => C<1> | C<0>

Return values that are xml, as raw xml. (default is 0)

=item * B<valxmlparsed> => C<1> | C<0>

Return values that are xml, as parsed xml. (default is 0)

=item * B<valtrim> => C<1> | C<0>

Trim off the white space at the beginning and end of each value in the result
set before returning the result set. (default is 0)

=item * I<returns>

Returns the values from the XML Document found at the XMLPath.

=back

    # return the value of @author from all book elements
    $vals = $tppx->getValues( $xmldoc, '/books/book/@author' );
    # return the values of the current node, or XML Subtree
    $vals = $tppx->getValues( $xmldoc_node, "." );
    # return only XML data from the 5th book node
    $vals = $tppx->getValues( $xmldoc, '/books/book[5]', valstring => 0, valxml => 1 );
    # return only XML::TreePP parsed XML from the all book nodes having an id attribute
    $vals = $tppx->getValues( $xmldoc, '/books/book[@id]', valstring => 0, valxmlparsed => 1 );
    # return both unparsed XML data and text content from the 3rd book excerpt,
    # and trim off the white space at the beginning and end of each value
    $vals = $tppx->getValues( $xmldoc, '/books/book[3]/excerpt', valstring => 1, valxml => 1, valtrim => 1 );

=back

=cut

sub getValues (@) {
    my $self        = shift if ref($_[0]) eq $REF_NAME || undef;
    unless (@_ >= 2) { carp 'method getValues(@) requires at least two arguments.'; return undef; }
    my $tree        = shift;
    my $path        = shift;

    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Purity = 1;
    local $Data::Dumper::Terse = 1;

    # Supported arguments:
    # valstring = 1|0    ; default = 1; 1 = return values that are strings
    # valxml = 1|0       ; default = 0; 1 = return values that are xml, as raw xml
    # valxmlparsed = 1|0 ; default = 0; 1 = return values that are xml, as parsed xml
    my %args        = @_;
    my $v_string    = exists $args{'valstring'}    ? $args{'valstring'}    : 1;
    my $v_xml       = exists $args{'valxml'}       ? $args{'valxml'}       : 0;
    my $v_xmlparsed = exists $args{'valxmlparsed'} ? $args{'valxmlparsed'} : 0;
    my $v_trim      = exists $args{'valtrim'}      ? $args{'valtrim'}      : 0;
    # Make up this code to dictate allowed combinations of return types
    my $v_ret_type  = "sp"  if $v_string && $v_xmlparsed;
       $v_ret_type  = "sx"  if $v_string && $v_xml;
       $v_ret_type  = "s"   if $v_string && ! $v_xml && ! $v_xmlparsed;
       $v_ret_type  = "p"   if ! $v_string && $v_xmlparsed;
       $v_ret_type  = "x"   if ! $v_string && $v_xml;

    my ($tpp,$xtree,$xpath,$xml_text_id,$xml_attr_id,$old_prop_xml_decl);

    if ((defined $self) && (defined $self->get('tpp'))) {
        $tpp         = $self ? $self->tpp() : tpp();
        $xml_text_id = $tpp->get( 'text_node_key' ) || '#text';
        $xml_attr_id = $tpp->get( 'attr_prefix' )   || '-';
    } else {
        $xml_text_id = '#text';
        $xml_attr_id = '-';
    }
    if (ref $tree) { $xtree = $tree;
                   }
    elsif (!defined $tree)
                   { $xtree = undef
                   }
              else { if (!defined $tpp) { $tpp = $self ? $self->tpp() : tpp(); }
                     $xtree = $tpp->parse($tree) if defined $tree;
                   }
    if (ref $path) { $xpath = eval (Dumper($path)); # make a copy of inputted parsed XMLPath
                   }
              else { $xpath = parseXMLPath($path);
                   }

    if ($v_ret_type =~ /x/) {
        if (ref($tpp) ne "XML::TreePP") {
            $tpp = $self ? $self->tpp() : tpp();
        }
        # $tpp->set( indent => 2 );
        $old_prop_xml_decl = $tpp->get( "xml_decl" );
        $tpp->set( xml_decl => '' );
    }

    print ("="x8,"sub::getValues()\n") if $DEBUG >= $DEBUGMETHOD;
    print (" "x8, "=called with return type: ",$v_ret_type,"\n") if $DEBUG >= $DEBUGMETHOD;
    print (" "x8, "=called with path: ",Dumper($xpath),"\n") if $DEBUG >= $DEBUGPATH;

    # Retrieve the sub tree of the XML document at path
    my $results = filterXMLDoc($xtree, $xpath);

    # for debugging purposes
    print (" "x8, "=Found at var's path: ", Dumper( $results ),"\n") if $DEBUG >= $DEBUGDUMP;

    my $getVal = sub ($$) {};
    $getVal = sub ($$) {
        print ("="x8,"sub::getValues|getVal->()\n") if $DEBUG >= $DEBUGMETHOD;
        my $v_ret_type = shift;
        my $treeNodes = shift;
        print (" "x8,"getVal->():from> ",Dumper($treeNodes)) if $DEBUG >= $DEBUGDUMP;
        print (" - '",ref($treeNodes)||'string',"'\n") if $DEBUG >= $DEBUGDUMP;
        my @results;
        if (ref($treeNodes) eq "HASH") {
            my $utreeNodes = eval ( Dumper($treeNodes) ); # make a copy for the result set
            push (@results, $utreeNodes->{$xml_text_id}) if exists $utreeNodes->{$xml_text_id} && $v_ret_type =~ /s/;
            delete $utreeNodes->{$xml_text_id} if exists $utreeNodes->{$xml_text_id} && $v_ret_type =~ /[x,p]/;
            push (@results, $utreeNodes) if $v_ret_type =~ /p/;
            push (@results, $tpp->write($utreeNodes)) if $v_ret_type =~ /x/;
        } elsif (ref($treeNodes) eq "ARRAY") {
            foreach my $item (@{$treeNodes}) {
                my $r1 = $getVal->($v_ret_type,$item);
                foreach my $r2 (@{$r1}) {
                    push(@results,$r2) if defined $r2;
                }
            }
        } elsif (! ref($treeNodes)) {
            push(@results,$treeNodes) if $v_ret_type =~ /s/;
        }
        return \@results;
    };

    if ($v_ret_type =~ /x/) {
        $tpp->set( xml_decl => $old_prop_xml_decl );
    }

    my $found = $getVal->($v_ret_type,$results);
    $found = [$found] if ref $found ne "ARRAY";

    if ($v_trim) {
        my $i=0;
        while($i < @{$found}) {
            print ("        =trimmimg result (".$i."): '",$found->[$i],"'") if $DEBUG >= $DEBUGDUMP;
            $found->[$i] =~ s/\s*$//g;
            $found->[$i] =~ s/^\s*//g;
            print (" to '",$found->[$i],"'\n") if $DEBUG >= $DEBUGDUMP;
            $i++;
        }
    }

    return undef if (! defined $found || @{$found} == 0) && !defined wantarray;
    return (@{$found}) if !defined wantarray;
    return wantarray ? @{$found} : $found;
}

# validateAttrValue
# Wrapper around filterXMLDoc for backwards compatibility only.
sub validateAttrValue ($$) {
    carp 'Method validateAttrValue($$) is deprecated, use filterXMLDoc() instead.';
    my $self        = shift if ref($_[0]) eq $REF_NAME || undef;
    unless (@_ == 2) { carp 'method validateAttrValue($$) requires two arguments.'; return undef; }
    my $subtree     = shift;
    my $params      = shift;

    if ($self) {
        return $self->filterXMLDoc( $subtree , [ "." , $params ]);
    }
    else {
        return filterXMLDoc( $subtree , [ "." , $params ]);
    }
}

# getSubtree
# Wrapper around filterXMLDoc for backwards compatibility only.
sub getSubtree ($$) {
    carp 'Method getSubtree($$) is deprecated, use filterXMLDoc() instead.';
    my $self        = shift if ref($_[0]) eq $REF_NAME || undef;
    unless (@_ == 2) { carp 'method getSubtree($$) requires two arguments.'; return undef; }
    my $tree        = shift;
    my $path        = shift;
    my $result;

    if ($self) {
        $result = $self->filterXMLDoc($tree,$path);
    }
    else {
        $result = filterXMLDoc($tree,$path);
    }
    return undef unless defined $result;
    return wantarray ? @{$result} : $result->[0];
}

=pod

=head2 getAttributes

=over

Retrieve the attributes found in the given XML Document at the given XMLPath.

=over 4

=item * B<XMLTree>

An XML::TreePP parsed XML document.

=item * B<XMLPath>

The path within the XML Tree to retrieve. See parseXMLPath()

=item * I<returns>

An array reference of [{attribute=>value}], or undef if none found

In the case where the XML Path points at a multi-same-name element, the return
value is a ref array of ref hashes, one hash ref for each element.

Example Returned Data:

    XML Path points at a single named element
    [ {attr1=>val,attr2=>val} ]

    XML Path points at a multi-same-name element
    [ {attr1A=>val,attr1B=>val}, {attr2A=>val,attr2B=>val} ]

=back

    $attributes = getAttributes ( $XMLTree , $XMLPath );

=back

=cut

# getAttributes
# @param    xmltree     the XML::TreePP parsed xml document
# @param    xmlpath     the XML path (See parseXMLPath)
# @return   an array ref of [{attr=>val, attr=>val}], or undef if none found
#
# In the case where the XML Path points at a multi-same-name element, the
# return value is a ref array of ref arrays, one for each element.
# Example:
#  XML Path points at a single named element
#  [{attr1=>val, attr2=>val}]
#  XML Path points at a multi-same-name element
#  [ {attr1A=>val,attr1B=>val}, {attr2A=>val,attr2B=val} ]
#
sub getAttributes (@);
sub getAttributes (@) {
    my $self        = shift if ref($_[0]) eq $REF_NAME || undef;
    unless (@_ >= 1) { carp 'method getAttributes($$) requires one argument, and optionally a second argument.'; return undef; }
    my $tree        = shift;
    my $path        = shift || undef;

    my ($tpp,$xml_text_id,$xml_attr_id);
    if ((defined $self) && (defined $self->get('tpp'))) {
        my $tpp      = $self ? $self->tpp() : tpp();
        $xml_text_id = $tpp->get( 'text_node_key' ) || '#text';
        $xml_attr_id = $tpp->get( 'attr_prefix' )   || '-';
    } else {
        $xml_text_id = '#text';
        $xml_attr_id = '-';
    }

    my $subtree;
    if (defined $path) {
        $subtree = filterXMLDoc($tree,$path);
    } else {
        $subtree = $tree;
    }
    my @attributes;
    if (ref $subtree eq "ARRAY") {
        foreach my $element (@{$subtree}) {
            my $e_attr = getAttributes($element);
            foreach my $a (@{$e_attr}) {
                push(@attributes,$a);
            }
        }
    } elsif (ref $subtree eq "HASH") {
        my $e_elem;
        while (my ($k,$v) = each(%{$subtree})) {
            if ($k =~ /^$xml_attr_id/) {
                $k =~ s/^$xml_attr_id//;
                $e_elem->{$k} = $v;
            }
        }
        push(@attributes,$e_elem);
    } else {
        return undef;
    }
    return \@attributes;
}

=pod

=head2 getElements

=over

Gets the child elements found at a specified XMLPath

=over 4

=item * B<XMLTree>

An XML::TreePP parsed XML document.

=item * B<XMLPath>

The path within the XML Tree to retrieve. See parseXMLPath()

=item * I<returns>

An array reference of [{element=>value}], or undef if none found

An array reference of a hash reference of elements (not attributes) and each
elements XMLSubTree, or undef if none found. If the XMLPath points at a
multi-valued element, then the subelements of each element at the XMLPath are
returned as separate hash references in the returning array reference.

The format of the returning data is the same as the getAttributes() method.

The XMLSubTree is fetched based on the provided XMLPath. Then all elements
found under that XMLPath are placed into a referenced hash table to be
returned. If an element found has additional XML data under it, it is all
returned just as it was provided.

Simply, this strips all XML attributes found at the XMLPath, returning the
remaining elements found at that path.

If the XMLPath has no elements under it, then undef is returned instead.

=back

    $elements = getElements ( $XMLTree , $XMLPath );

=back

=cut

# getElements
# @param    xmltree     the XML::TreePP parsed xml document
# @param    xmlpath     the XML path (See parseXMLPath)
# @return   an array ref of [[element,{val}]] where val can be a scalar or a subtree, or undef if none found
#
# See also getAttributes function for further details of the return type
#
sub getElements (@);
sub getElements (@) {
    my $self        = shift if ref($_[0]) eq $REF_NAME || undef;
    unless (@_ >= 1) { carp 'method getElements($$) requires one argument, and optionally a second argument.'; return undef; }
    my $tree        = shift;
    my $path        = shift || undef;

    my ($tpp,$xml_text_id,$xml_attr_id);
    if ((defined $self) && (defined $self->get('tpp'))) {
        my $tpp      = $self ? $self->tpp() : tpp();
        $xml_text_id = $tpp->get( 'text_node_key' ) || '#text';
        $xml_attr_id = $tpp->get( 'attr_prefix' )   || '-';
    } else {
        $xml_text_id = '#text';
        $xml_attr_id = '-';
    }

    my $subtree;
    if (defined $path) {
        $subtree = filterXMLDoc($tree,$path);
    } else {
        $subtree = $tree;
    }
    my @elements;
    if (ref $subtree eq "ARRAY") {
        foreach my $element (@{$subtree}) {
            my $e_elem = getElements($element);
            foreach my $a (@{$e_elem}) {
                push(@elements,$a);
            }
        }
    } elsif (ref $subtree eq "HASH") {
        my $e_elem;
        while (my ($k,$v) = each(%{$subtree})) {
            if ($k !~ /^$xml_attr_id/) {
                $e_elem->{$k} = $v;
            }
        }
        push(@elements,$e_elem);
    } else {
        return undef;
    }
    return \@elements;
}


1;
__END__

=pod

=head1 EXAMPLES

=head2 Method: new

It is not necessary to create an object of this module.
However, if you choose to do so any way, here is how you do it.

    my $obj = new XML::TreePP::XMLPath;

This module supports being called by two methods.

=over 4

=item 1.  By importing the functions you wish to use, as in:

    use XML::TreePP::XMLPath qw( function1 function2 );
    function1( args )

See IMPORTABLE METHODS section for methods available for import

=item 2.  Or by calling the functions in an object oriented manor, as in:

    my $tppx = new XML::TreePP::XMLPath;
    $tppx->function1( args )

=back

Using either method works the same and returns the same output.

=head2 Method: charlexsplit

Here are three steps that can be used to parse values out of a string:

Step 1:

First, parse the entire string delimited by the / character.

    my $el = charlexsplit   (
        string        => q{abcdefg/xyz/path[@key='val'][@key2='val2']/last},
        boundry_start => '/',
        boundry_stop  => '/',
        tokens        => [qw( [ ] ' ' " " )],
        boundry_begin => 1,
        boundry_end   => 1
        );
    print Dumper( $el );

Output:

    ["abcdefg", "xyz", "path[\@key='val'][\@key2='val2']", "last"],

Step 2:

Second, parse the elements from step 1 that have key/val pairs, such that
each single key/val is contained by the [ and ] characters

    my $el = charlexsplit (
        string        => q( path[@key='val'][@key2='val2'] ),
        boundry_start => '[',
        boundry_stop  => ']',
        tokens        => [qw( ' ' " " )],
        boundry_begin => 0,
        boundry_end   => 0
        );
    print Dumper( $el );

Output:

    ["\@key='val'", "\@key2='val2'"]

Step 3:

Third, parse the elements from step 2 that is a single key/val, the single
key/val is delimited by the = character

    my $el = charlexsplit (
        string        => q{ @key='val' },
        boundry_start => '=',
        boundry_stop  => '=',
        tokens        => [qw( ' ' " " )],
        boundry_begin => 1,
        boundry_end   => 1
        );
    print Dumper( $el );

Output:

    ["\@key", "'val'"]

Note that in each example the C<tokens> represent a group of escaped characters
which, when analyzed, will be collected as part of an element, but will not be
allowed to match any starting or stopping boundry.

So if you have a start token without a stop token, you will get undesired
results. This example demonstrate this data error.

    my $el = charlexsplit   (
        string        => q{ path[@key='val'][@key2=val2'] },
        boundry_start => '[',
        boundry_stop  => ']',
        tokens        => [qw( ' ' " " )],
        boundry_begin => 0,
        boundry_end   => 0
        );
    print Dumper( $el );

Undesired output:

    ["\@key='val'"]

In this example of bad data being parsed, the C<boundry_stop> character C<]> was
never matched for the C<key2=val2> element.

And there is no error message. The charlexsplit method throws away the second
element silently due to the token start and stop mismatch.

=head2 Method: parseXMLPath

    use XML::TreePP::XMLPath qw(parseXMLPath);
    use Data::Dumper;
    
    my $parsedPath = parseXMLPath(
                                  q{abcdefg/xyz/path[@key1='val1'][key2='val2']/last}
                                  );
    print Dumper ( $parsedPath );

Output:

    [
      ["abcdefg", undef],
      ["xyz", undef],
      ["path", [["-key1", "val1"], ["key2", "val2"]]],
      ["last", undef],
    ]

=head2 Method: filterXMLDoc

Filtering an XML Document, using an XMLPath, to find a node within the
document.

    #!/usr/bin/perl
    use XML::TreePP;
    use XML::TreePP::XMLPath qw(filterXMLDoc);
    use Data::Dumper;
    #
    # The XML document data
    my $xmldata=<<XMLEND;
        <level1>
            <level2>
                <level3 attr1="val1" attr2="val2">
                    <attr3>val3</attr3>
                    <attr4/>
                    <attrX>one</attrX>
                    <attrX>two</attrX>
                    <attrX>three</attrX>
                </level3>
                <level3 attr1="valOne"/>
            </level2>
        </level1>
    XMLEND
    #
    # Parse the XML document.
    my $tpp = new XML::TreePP;
    my $xmldoc = $tpp->parse($xmldata);
    print "Output Test #1\n";
    print Dumper( $xmldoc );
    #
    # Retrieve the sub tree of the XML document at path "level1/level2"
    my $xmlSubTree = filterXMLDoc($xmldoc, 'level1/level2');
    print "Output Test #2\n";
    print Dumper( $xmlSubTree );
    #
    # Retrieve the sub tree of the XML document at path "level1/level2/level3[@attr1='val1']"
    my $xmlSubTree = filterXMLDoc($xmldoc, 'level1/level2/level3[@attr1="val1"]');
    print "Output Test #3\n";
    print Dumper( $xmlSubTree );

Output:

    Output Test #1
    {
      level1 => {
            level2 => {
                  level3 => [
                        {
                          "-attr1" => "val1",
                          "-attr2" => "val2",
                          attr3    => "val3",
                          attr4    => undef,
                          attrX    => ["one", "two", "three"],
                        },
                        { "-attr1" => "valOne" },
                      ],
                },
          },
    }
    Output Test #2
    {
      level3 => [
            {
              "-attr1" => "val1",
              "-attr2" => "val2",
              attr3    => "val3",
              attr4    => undef,
              attrX    => ["one", "two", "three"],
            },
            { "-attr1" => "valOne" },
          ],
    }
    Output Test #3
    {
      "-attr1" => "val1",
      "-attr2" => "val2",
      attr3    => "val3",
      attr4    => undef,
      attrX    => ["one", "two", "three"],
    }

Validating attribute and value pairs of a given node.

    #!/usr/bin/perl
    use XML::TreePP;
    use XML::TreePP::XMLPath qw(filterXMLDoc);
    use Data::Dumper;
    #
    # The XML document data
    my $xmldata=<<XMLEND;
        <paragraph>
            <sentence language="english">
                <words>Do red cats eat yellow food</words>
                <punctuation>?</punctuation>
            </sentence>
            <sentence language="english">
                <words>Brown cows eat green grass</words>
                <punctuation>.</punctuation>
            </sentence>
        </paragraph>
    XMLEND
    #
    # Parse the XML document.
    my $tpp = new XML::TreePP;
    my $xmldoc = $tpp->parse($xmldata);
    print "Output Test #1\n";
    print Dumper( $xmldoc );
    #
    # Retrieve the sub tree of the XML document at path "paragraph/sentence"
    my $xmlSubTree = filterXMLDoc($xmldoc, "paragraph/sentence");
    print "Output Test #2\n";
    print Dumper( $xmlSubTree );
    #
    my (@params, $validatedSubTree);
    #
    # Test the XML Sub Tree to have an attribute "-language" with value "german"
    @params = (['-language', 'german']);
    $validatedSubTree = filterXMLDoc($xmlSubTree, [ ".", \@params ]);
    print "Output Test #3\n";
    print Dumper( $validatedSubTree );
    #
    # Test the XML Sub Tree to have an attribute "-language" with value "english"
    @params = (['-language', 'english']);
    $validatedSubTree = filterXMLDoc($xmlSubTree, [ ".", \@params ]);
    print "Output Test #4\n";
    print Dumper( $validatedSubTree );

Output:

    Output Test #1
    {
      paragraph => {
            sentence => [
                  {
                    "-language" => "english",
                    punctuation => "?",
                    words => "Do red cats eat yellow food",
                  },
                  {
                    "-language" => "english",
                    punctuation => ".",
                    words => "Brown cows eat green grass",
                  },
                ],
          },
    }
    Output Test #2
    [
      {
        "-language" => "english",
        punctuation => "?",
        words => "Do red cats eat yellow food",
      },
      {
        "-language" => "english",
        punctuation => ".",
        words => "Brown cows eat green grass",
      },
    ]
    Output Test #3
    undef
    Output Test #4
    {
      "-language" => "english",
      punctuation => "?",
      words => "Do red cats eat yellow food",
    }

=head2 Method: getAttributes

    #!/usr/bin/perl
    #
    use XML::TreePP;
    use XML::TreePP::XMLPath qw(getAttributes);
    use Data::Dumper;
    #
    # The XML document data
    my $xmldata=<<XMLEND;
        <level1>
            <level2>
                <level3 attr1="val1" attr2="val2">
                    <attr3>val3</attr3>
                    <attr4/>
                    <attrX>one</attrX>
                    <attrX>two</attrX>
                    <attrX>three</attrX>
                </level3>
                <level3 attr1="valOne"/>
            </level2>
        </level1>
    XMLEND
    #
    # Parse the XML document.
    my $tpp = new XML::TreePP;
    my $xmldoc = $tpp->parse($xmldata);
    print "Output Test #1\n";
    print Dumper( $xmldoc );
    #
    # Retrieve the sub tree of the XML document at path "level1/level2/level3"
    my $attributes = getAttributes($xmldoc, 'level1/level2/level3');
    print "Output Test #2\n";
    print Dumper( $attributes );
    #
    # Retrieve the sub tree of the XML document at path "level1/level2/level3[attr3=""]"
    my $attributes = getAttributes($xmldoc, 'level1/level2/level3[attr3="val3"]');
    print "Output Test #3\n";
    print Dumper( $attributes );

Output:

    Output Test #1
    {
      level1 => {
            level2 => {
                  level3 => [
                        {
                          "-attr1" => "val1",
                          "-attr2" => "val2",
                          attr3    => "val3",
                          attr4    => undef,
                          attrX    => ["one", "two", "three"],
                        },
                        { "-attr1" => "valOne" },
                      ],
                },
          },
    }
    Output Test #2
    [{ attr1 => "val1", attr2 => "val2" }, { attr1 => "valOne" }]
    Output Test #3
    [{ attr1 => "val1", attr2 => "val2" }]

=head2 Method: getElements

    #!/usr/bin/perl
    #
    use XML::TreePP;
    use XML::TreePP::XMLPath qw(getElements);
    use Data::Dumper;
    #
    # The XML document data
    my $xmldata=<<XMLEND;
        <level1>
            <level2>
                <level3 attr1="val1" attr2="val2">
                    <attr3>val3</attr3>
                    <attr4/>
                    <attrX>one</attrX>
                    <attrX>two</attrX>
                    <attrX>three</attrX>
                </level3>
                <level3 attr1="valOne"/>
            </level2>
        </level1>
    XMLEND
    #
    # Parse the XML document.
    my $tpp = new XML::TreePP;
    my $xmldoc = $tpp->parse($xmldata);
    print "Output Test #1\n";
    print Dumper( $xmldoc );
    #
    # Retrieve the multiple same-name elements of the XML document at path "level1/level2/level3"
    my $elements = getElements($xmldoc, 'level1/level2/level3');
    print "Output Test #2\n";
    print Dumper( $elements );
    #
    # Retrieve the elements of the XML document at path "level1/level2/level3[attr3="val3"]
    my $elements = getElements($xmldoc, 'level1/level2/level3[attr3="val3"]');
    print "Output Test #3\n";
    print Dumper( $elements );

Output:

    Output Test #1
    {
      level1 => {
            level2 => {
                  level3 => [
                        {
                          "-attr1" => "val1",
                          "-attr2" => "val2",
                          attr3    => "val3",
                          attr4    => undef,
                          attrX    => ["one", "two", "three"],
                        },
                        { "-attr1" => "valOne" },
                      ],
                },
          },
    }
    Output Test #2
    [
      { attr3 => "val3", attr4 => undef, attrX => ["one", "two", "three"] },
      undef,
    ]
    Output Test #3
    [
      { attr3 => "val3", attr4 => undef, attrX => ["one", "two", "three"] },
    ]

=head1 AUTHOR

Russell E Glaue, http://russ.glaue.org

=head1 SEE ALSO

C<XML::TreePP>

XML::TreePP::XMLPath on Codepin: http://www.codepin.org/project/perlmod/XML-TreePP-XMLPath

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008-2013 Russell E Glaue,
Center for the Application of Information Technologies,
Western Illinois University.
All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

