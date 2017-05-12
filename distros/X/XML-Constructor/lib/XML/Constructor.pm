package XML::Constructor;

use warnings;
use strict;
use XML::LibXML;
use Scalar::Util qw/blessed/;
use Carp qw/cluck croak carp/;

=head1 NAME

XML::Constructor - Generate XML from a markup syntax allowing for the abstraction of markup from code

=cut

our $VERSION = '0.01';


sub generate {
  my ( $class, %args ) = @_;
  my ( $parent_node, $data ) =
    @args{ qw( parent_node data ) };

  my $parent  = $class->_get_parent_node($parent_node);

  return $parent unless (ref $data eq 'ARRAY');

  return $class->_generate(parent => $parent, data => $data);
}

sub toString { shift->generate( @_ )->toString }

sub _get_parent_node {
  my ( $class, $parent_node )  = @_;

  if(blessed $parent_node) {
    return $parent_node 
      if $class->_validate_parent_object($parent_node);
  }

  return ( ref $parent_node eq 'ARRAY' )
      ? $class->_create_parent_from_arrayref( element => $parent_node )
      : $class->_create_parent_node( $parent_node );
}

sub _generate {
  my ( $class, %args )  = @_;
  my ($parent, $data )  = @args{ qw( parent data ) };

  for my $element ( @$data ) {
    my $method  = $class->_get_dispatch_method($element);

    next unless $method;

    $class->$method( parent => $parent, element => $element );
  }
  return $parent;
}

sub _validate_parent_object {
  my ( $class, $parent_element ) = @_;
  croak "parent element not an object"
    unless blessed $parent_element;

  croak "parent element not decendant of XML::LibXML::(Element|Document)"
    unless ($parent_element->isa("XML::LibXML::Node") ||
            $parent_element->isa("XML::LibXML::Document"));
            
  
  return 1;
}

sub _create_parent_node {
  my ( $class, $parent_node_name ) = @_;
  cluck "creating an empty parent node"
    unless(defined $parent_node_name && $parent_node_name =~/\w/);

  return $class->_create_element($parent_node_name);
}

sub _get_dispatch_method {
  my ( $class, $element)   = @_;
  my $method;

  for( ref $element ) {
    $_ eq 'HASH'          && do{$method = '_from_hash'; last};
    $_ eq 'ARRAY'         && do{$method = '_from_array'; last};
    $_ eq 'SCALAR'        && do{$method = '_from_scalar'; last};
  }

  # is element a XML::LibXML::Element object?
  if(!$method && (blessed $element)) {
    $method = '_from_libxml'
      if $element->isa("XML::LibXML::Element");
  }

  carp "cannot process an element in markup [$element]"
    if(!$method);

  return $method;
}

sub _create_parent_from_arrayref {
  my $class   = shift;
  my %args    = @_;
  my( $element )
    = @args{qw/element/};

  my $root  = XML::LibXML::Element->new("");
  # save attribute_title
  my $attribute_title  = $element->[0];

  $class->_from_array( parent => $root, element => $element );

  my $parent  = $root->getChildrenByTagName( $attribute_title );

  die "could not create parent node from ARRAYREF named ".$element->[0]
    unless ( (ref $parent ) && $parent->[0] );

  # return 1st node found
  return $parent->[0];
}

sub _create_element{
  my $class   =shift;
  return XML::LibXML::Element->new( shift || "" )
}

sub _from_hash {
  my ( $class, %args ) = @_;
  my ( $parent, $element ) =
    @args{ qw( parent element ) };

  foreach my $attribute ( keys %$element ) {
    my $value = $element->{$attribute};  
    my $obj   = $class->_create_element($attribute);

    if( $value ) {
      if( ref $value ) {
        # kick back to generate
        $class->_generate( parent => $obj, data => [ $value ] );
      }
      else {
        $obj->appendText( $value );
      }
    }
    $parent->addChild( $obj );
  }
}

sub _from_array {
  my ( $class, %args ) = @_;
  my ( $parent, $array ) =
    @args{ qw( parent element ) };

  my $node  = $class->_create_element( shift @$array );

  while( my $attribute = shift @$array ) {
    if( ref $attribute ) {
      $class->_generate( parent => $node, data => [ $attribute ] );
    }
    else {
      # next element in array becomes attribute value
      $node->setAttribute( $attribute, shift @$array );
    }
  }
  $parent->addChild( $node );
}

sub _from_libxml {
  my ( $class, %args ) = @_;
  my ( $parent, $element ) =
    @args{ qw( parent element ) };
  $parent->addChild( $element );
}

sub _from_scalar {
  my ( $class, %args ) = @_;
  my ( $parent, $element ) =
    @args{ qw( parent element ) };

  if ( $$element ) {
    my $string = $$element;
    # removed doubly encoded entites
    # et al XML::DoubleEncodedEntities et al XML::Tiny
    if($string =~ /&(amp|lt|gt|quot|apos);/) {
      $string =~ s/&(lt;|gt;|quot;|apos;|amp;)/
                    $1 eq 'lt;'   ? '<' :
                    $1 eq 'gt;'   ? '>' :
                    $1 eq 'apos;' ? "'" :
                    $1 eq 'quot;' ? '"' :
                                    '&'
                   /ge;
      $element  = \$string;
    }
    $parent->appendText( $$element );
  }
}
1;

__END__

=head1 SYNOPSIS

A simple example of creating an XML document

  use XML::Constructor;

  my $node  = XML::Constructor->generate( 
    parent_node => 'Team',
    data        => [
      {name   => 'Liverpool FC'},
      {league => 'English Premiership'}
    ]
  );

  $node->toString;

The 'toString' method would produce the following XML

  <team>
    <name>Liverpool FC</name>
    <league>English Premiership</league>
  </team>


A more advanced example would be: 

  use XML::LibXML;     
  use XML::Constructor;

  sub postcode { return { Postcode => 'W11 6TG'} }

  my $surname  = XML::LibXML::Element->new('Surname');
  $surname->appendText('Smith');

  my $element = XML::Constructor->generate(
   parent_node  => XML::LibXML::Element->new('Details'),
   data    => [
     { Forename => 'Joe' },
     $surname,
     [ 'Phone',  mobile  => '0440' ],
     [ 'Phone',  home    => '0441' ],
     [ 'Address',
       [ 'Location',
         type      => 'Home',
         { 'House'   => undef },
         { 'Street'  => '23 Road Street' },
         { 'City'    => 'London' },
         postcode(),
       ],
       [ 'Location',
         type      => 'Work',
         { 'House'   => 'GG&H House' },
         { 'Street'  => '23 Road Street' },
         { 'City'    => 'London' },
         postcode(),
       ],
       { Known_Locations => postcode() }
     ]
   ]
  );

  print $element->toString;

Produces

  <Details>
    <Forename>Joe</Forename>
    <Surname>Smith</Surname>
    <Phone mobile="0440"/>
    <Phone home="0441"/>
    <Address>
      <Location type="Home">
        <House/>
        <Street>23 Road Street</Street>
        <City>London</City>
        <Postcode>W11 6TG</Postcode>
      </Location>
      <Location type="Work">
        <House>GG&amp;H House</House>
        <Street>23 Road Street</Street>
        <City>London</City>
        <Postcode>W11 6TG</Postcode>
      </Location>
      <Known_Locations>
        <Postcode>W11 6TG</Postcode>
      </Known_Locations>
    </Address>
  </Details>

=head1 RECOMMEND USER

This package is a wrapper class for XML::LibXML which it uses to generate the XML. 
It provides an abstraction between presentation and business logic so development of the two can be separated.

This package attempts to satisfy only the most commonly used features of XML. If you require full DOM specification
support (without the markup separation) there are better packages to use like L<XML::Generator> of even L<XML::LibXML>
directly itself.

That said this package builds and manipulates L<XML::LibXML> instances which you can always decorate after if you so wished.


=head1 CLASS METHODS

=head2 generate

  XML::Constructor->generate( parent_node => .. , data => [..] )

=over 

=item parameters: parent_node, data


=item Required:   none


=item Returns:    An instance of XML::LibXML::Element [default] | XML::LibXML::Document [if parent_node is an instances of]

=back

'parent_node' can be one of the following

=over

=over

=item parent_node ( undef )
    
    if not defined a XML::LibXML::Element instance is created with an element name of ""


=item parent_node ( XML::LibXML::(Element|Document) ) 

    parent_node => XML::LibXML::Element->new('Disco')

    accepts XML::LibXML::Element or XML::LibXML::Document instances or any object that inherits from either class


=item parent_node ( string )

    parent_node => 'Disco'

    the string represents the element's name. A XML::LibXML::Element instance is created


=item parent_node ( Array ref )
  
  parent_node => [ Disco => 'date_start', '1974' ]

  Will create a new L<XML::LibXML::Element> node as the parent node. The same markup logic used in L<data> is used to build 
  the parent node. This is useful where you have a situation where the parent node also has attributes.

   The example above will produce a parent node

    <Disco date_start="1974"/>

    or

    <Disco date_start="1974">..</Disco>

    Depending on whether child nodes are attached. Naturally care must be taken as you can easily be tempted to define 
    complex parent nodes but you should try not to do this! Use L<data> instead.

=back

=back

'data' can be one of the following

=over

=over

=item data ( undef )

  rather pointless but accepted. No markup results in just the parent_node being returned.

=item data ( Array ref )
  
  containing markup syntax

=back

=back


=head2 toString

  XML::Constructor->toString( parent_node => .. , data => [..] )


=over 

=item parameters: parent_node, data


=item Required:   none


=item Returns:    XML output

=back

  convenience method. Wraps generate and calls 'toString' on XML::LibXML::Element|Document instance


=head1 MARKUP SYNTAX

XML::Constructor understands 3 basic types of elements

=head2 hash:

  { foo => 'bar' }

produces

  <foo>bar</foo>

XML::Constructor takes the key of a hash pairing to be the elements name. If the value of the pairing is a scalar it
is append as text to the element. The value may also be a non-scalar but this must reference an array, hash,
scalar or a B<XML::LibXML::Element> object

Examples:

  { foo => XML::LibXML::Element->new('bar') }

produces

  <foo><bar/></foo>

non-scalar references

  { foo => { bar => 'baz' }}

produces
  
  <foo>
    <bar>baz</bar>
  </foo>

Also

  { square => \"hat" }

produces

  <square>hat</square>

which is the same as if you passed a normal string. However beware as

  { \"square" => \"hat" }

will produce something similar to

  <SCALAR(0x9a951b8)>hat</SCALAR(0x9a951b8)>

As XML::Constructor will not deference the key.

XML::Constructor supports multi value hashes but note

  { foo => 'bar' , baz => 'taz' }

is NOT equal to

  { foo => 'bar' },{ baz => 'taz' } 

As the former does not guarantee order


=head2 array:

  [ 'foo', bar => 1 ]

produces
  
  <foo bar='1'/>

When an array is encountered a new instances of L<XML::LibXML::Element> is created and the 1st value of the array
becomes the elements name. The remaining scalar values of the array become attribute / value pairs within the element. 
References to array, hash, or B<XML::LibXML::Element> instances are added as child nodes of this element. 
References to a scalar appends the value to the text field of the element.


Examples:

  [ 'foo', { bar => baz } ]

produces
  
  <foo>
    <bar>baz</bar>
  </foo>

While

  [ 'link', 'rel', 'canonical', 'href', 'http://foo.com', \"lovely foo" ]

urrgh let's add some syntax sugar... While

  [ 'link', rel => 'canonical', href => 'http://foo.com', \"lovely foo" ]

produces

  <link rel="canonical" href="http://foo.com">lovely foo</link>


Naturally care must be taken but you can mix and match the forms quite safely
  
  
  [ 'Phone',  
    mobile    => '0440',
    XML::LibXML::Element->new('something'),
    {foo      => 'bar' }, 
    this      => 'just works', 
    \"both text and element :("
  ]

produces

  <Phone mobile="0440" this="just works">
    <something/>
    <foo>bar</foo>
    both text and element :(
  </Phone>

=head2 XML::LibXML::Element instances

No processing is done. They are simply added to the parent node

=head2 Code refs

Because of the precedence terms and operators have in Perl it is possible to embed Perl code into 
the markup. As long as the term / function returns valid markup XML::Constructor will not croak.

Here's a simple example: 

  sub _count { return map{ {'count'.$_ => " $_"} } (0..shift) }

  XML::Constructor->toString(
    parent_node => 'sequence',
    data        => [ _count(3) ]);

produces

  <sequence>
    <count0> 0</count0>
    <count1> 1</count1>
    <count2> 2</count2>
    <count3> 3</count3>
  </sequence>

This is a powerful feature but much care must be taken. See B<CAVEATS>.

=head2 scalars ( strings )

strings are appended to the current elements as text. There is an attempt
to remove doubly encoded entities before doing so.

=head1 EXAMPLES

ORDER MATTERS!

=over

=item Adding a string to the top most node

  XML::Constructor->toString(
    parent_node => 'comments',
    data        => [
      \"1st comment",
      { 'account', username => 'fuzzbuzz' },
      \"2nd comment",
      { 'account', username => 'orth' },
    ]
  );

produces

  <comments>
    1st comment
    <account username="fuzzbuzz"/>
    2nd comment
    <account username="orth"/>
  </comments>

=item Fibonacci numbers

Non optimal presentation of the sequence

  {
    my %cache = (qw(0 0 1 1));

    sub _fib {
        my $n = shift;
        return $n if $n < 2;
        $cache{$n} = _fib($n -1) + _fib($n - 2);
    }

    sub fibMarkup {
      my $seed = shift;
      _fib($seed);
      return  map{ {'seq'.$_ => " $cache{$_}"} }sort{$a <=> $b} keys %cache;
    }
  }

  my $number = 8;

  print XML::Constructor->toString(
    parent_node   => ['fibonacci', 'sequence' => $number, f0 =>' 0', f1 => ' 1'],
    data    => [ fibMarkup($number) ]);

produces

  <fibonacci sequence="8" f0=" 0" f1=" 1">
    <seq0> 0</seq0>
    <seq1> 1</seq1>
    <seq2> 1</seq2>
    <seq3> 2</seq3>
    <seq4> 3</seq4>
    <seq5> 5</seq5>
    <seq6> 8</seq6>
    <seq7> 13</seq7>
    <seq8> 21</seq8>
  </fibonacci>

=back

=head1 KNOWN ISSUES

Well not really a bug. Rather a gotcha. One thing you can't do is this

  my $ping  = XML::LibXML::Element->new('Ping');
  $ping->appendText('pong');
  
  print XML::Constructor->toString(
    parent_node => 'missing',
    data        => [
      $ping, 
      $ping,
      $ping
    ]
  );

As this will produce

  <missing>
    <Ping>pong</Ping>
  </missing>

and not the expected 3 'Ping' elements. This is an artifact for L<XML::LibXML> and not this package

=head1 CAVEATS

There are a number of issues this module does not attempt to satisfy.

Using code references within the markup is a powerful feature BUT there is NO ref counting 
within the module thus it is possible to fall into a recursive loop.


There is no native support for namespaces. A half way solution is to literally code the namespace.

  [ 'rdf:RDF', 'xmlns:rdf' => "http://...", 'rdf:Genre' => 'http://..' ]

produces

  <rdf:RDF xmlns:rdf=".." rdf:Genre=".."/>

but it's not ideal.

There is limited encoding support. The module attempts to identify double encoding characters
but that's it. 

If any of these features are deal breakers I advise finding another package.

=head1 SEE ALSO    

L<XML::LibXML>


=head1 AUTHOR

Judioo, C<< <judioo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<judioo at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Constructor>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 DEPENDENCIES

  Heavily depends on L<XML::LibXML>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Judioo.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut



