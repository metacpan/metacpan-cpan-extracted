package XML::Parser::Nodes ;

use 5.008009 ;
use strict ;
use warnings ;
use Carp ;

use XML::Parser ;
use XML::Dumper ;
use XML::Parser::Style::Tree ;

require Exporter ;

our @ISA = qw( Exporter XML::Parser::Style::Tree ) ;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use XML::Parser::Nodes ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our %EXPORT_TAGS = ( 'all' => [ qw( ) ] ) ;

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;

our @EXPORT = qw( ) ;

our $VERSION = '0.08' ;

$XML::Parser::Built_In_Styles{Nodes} = 1;

sub Init {
	return XML::Parser::Style::Tree::Init( @_ ) ;
	} ;

sub Start {
	return XML::Parser::Style::Tree::Start( @_ ) ;
	} ;

sub End {
	return XML::Parser::Style::Tree::End( @_ ) ;
	} ;

sub Char {
	return XML::Parser::Style::Tree::Char( @_ ) ;
	} ;

sub Final {
	my $tree = XML::Parser::Style::Tree::Final( @_ ) ;
	return XML::Parser::Nodes->conform( $tree ) ;
	} ;

# Preloaded methods go here.

sub new {
	my $self = shift ;
	my $xmlarg = shift ;
	return length $xmlarg < 255 && $xmlarg !~ /^</ && -f $xmlarg ?
			$self->parsefile( $xmlarg ):
			$self->parse( $xmlarg ) ;
	}

################################################################################
##
##  In XML::Parser's output, a node is an Array whose first element is a
##  Hash of NVP's that represent that tag's attributes.  Subsequent
##  elements alternate between text and child nodes.
##
##  conform() prepends an empty hash to the output structure to ensure it
##  conforms to this node definition.
##
################################################################################

sub conform {
	my $package = shift ;
	my $parsed = shift ;
	$package = ref $package if ref $package ;
	unshift @$parsed, {} ;
	return bless $parsed, $package ;
	}

sub parse {
	my $self = shift ;
	my $xmlbuff = shift ;

	my $package = ref $self? ref $self: $self ;
	my $parser = ref $self? $self: 
			XML::Parser->new( Style => 'Tree' ) ;
	return $package->conform( XML::Parser::parse( 
			$parser, $xmlbuff ) ) ;
	}

sub parsefile {
	my $self = shift ;
	my $xmlfn = shift ;

	my $package = ref $self? ref $self: $self ;
	return ref $self? XML::Parser::parsefile( $self, $xmlfn ): 
			$package->conform( 
			XML::Parser->new( Style => 'Tree' )->parsefile( $xmlfn )
			) ;
	}

sub byfile {
	return parsefile( @_ ) ;
	}

sub readfile {
	return parsefile( @_ ) ;
	}

sub childlist {
	my $self = shift ;
	my $i = 0 ;
	my @a = () ;
	push @a, [ $self->[ $i ], $self->[ ++$i ] ] while $i++ < $#$self ;
	return map { $_->[0] } grep ref $_->[1], @a ;
	}

sub taglist {
	return childlist( @_ ) ;
	}

sub tree {
	my $self = shift ;
	my $tag = '' ;
	my @rv = () ;

	if ( @_ ) {
		push @rv, shift @_ ;
		$tag = $rv[0] .'/' ;
		}

	my $i = 0 ;
	my @a = () ;
	push @a, [ $self->[ $i ], $self->[ ++$i ] ] while $i++ < $#$self ;
	push @rv, map { tree( $_->[1], $tag .$_->[0] ) } grep ref $_->[1], @a ;
	return @rv ;
	}

sub childnodes {
	my $self = shift ;

	my $i = 0 ;
	my @a = () ;
	push @a, [ $self->[ $i ], $self->[ ++$i ] ] while $i++ < $#$self ;
	my @aa = grep ref $_->[1], @a ;
	map { bless $_->[1], ref $self } @aa ;
	return @aa ;
	}

sub getkids {
	return childnodes( @_ ) ;
	}

sub childnode {
	my $self = shift ;
	return $self->childnodes unless @_ ;

	my $key = shift ;

	my $i = 0 ;
	my @a = () ;
	push @a, [ $self->[ $i ], $self->[ ++$i ] ] while $i++ < $#$self ;

	my @aa = map { bless $_->[1], ref $self } grep $_->[0] eq $key, @a ;
	return $aa[0] || bless( [], ref $self ) unless wantarray ;
	return @aa ;
	}

sub getdata {
	return childnode( @_ ) ;
	}

sub nodebykey {
	my $self = shift ;
	my $key = shift ;
	my @key = split( m|/|, $key, 2 ) ;
	my $next = $self->childnode( $key[0] ) ; 

	return $next if @key == 1 ;
	return $next->nodebykey( $key[1] ) ;
	}

sub recordbykey {
	return nodebykey( @_ ) ;
	}

sub getattributes {
	my $self = shift ;
	return $self->[0] ;
	}

sub gettext {
	my $self = shift ;

	my $i = 0 ;
	my @a = () ;
	push @a, [ $self->[ $i ], $self->[ ++$i ] ] while $i++ < $#$self ;

	my @results = grep defined $_,
			map { $_->[1] } grep $_->[0] eq '0', @a ;
	return @results if wantarray && @results != 0 ;
	return join '', @results ;
	}

sub cells {
	my $self = shift ;
	my @rv = map { $self->childnode( $_ )->gettext || '' } @_ ;
	return \@rv ;
	}

sub wrapper {
	my $self = shift ;
	my $name = shift ;
	return bless [ {}, $name, $self ], ref $self ;
	}

sub name {
	return wrapper( @_ ) ;
	}

sub dump {
	my $self = shift ;
	return xmlout( @$self[ 1, 2 ] ) ."\n" ;
	}

sub xmlout {
	my $name = shift ;
	my $properties = shift ;
	my $singletag = undef ;		# optionally set true

	return retext( $properties ) if $name eq '0' ;

	my @properties = () ;
	push @properties, @$properties ;
	my $attribs = shift @properties ;
	$attribs ||= {} ;
	my $atstring .= join ' ', '', map { sprintf '%s="%s"', 
			$_, charfix( $attribs->{$_} ) } keys %$attribs ;

	return "<$name$atstring />" unless scalar @properties ;

	my $out = "<$name$atstring>" ;
	$out .= xmlout( splice @properties, 0, 2 ) while @properties ;
	return "$out</$name>" ;
	}

sub retext {
	my $s = shift ;
	return '' unless defined $s ;
	$s =~ s/&/&amp;/g ;
	$s =~ s/>/&gt;/g ;
	$s =~ s/</&lt;/g ;
	return $s ;
	}

sub charfix {
	my $value = shift ;
	return '' unless defined $value ;
	$value =~ s/&/&amp;/g ;
	$value =~ s/"/&quot;/g ;
	$value =~ s/'/&apos;/g ;
	return $value ;
	}

no warnings ;

sub pl2xml {
	my $o = pop ;
	my $self = shift if @_ && ( ref $_[0] || $_[0] eq __PACKAGE__ ) ;
	$self = ! $self? __PACKAGE__: ref $self? ref $self: $self ;
	my $toplabel = shift ;
	$toplabel ||= 'perldata' ;

	my $top = $self->newelement() ;
	$top->addelement( "\n " ) ;
	$top->addelement( nextpl2xml( bless( {}, $self ), $o, 2 ) ) ;
	$top->addelement( "\n" ) ;

	my $out = $self->newelement() ;
	$out->addelement( $toplabel => $top ) ;
	return $out ;
	}

use warnings ;

sub nextpl2xml {
	my $self = shift;
	my $ref = shift;
	my $indent = shift;

	my $out = $self->newelement() ;

	if ( ref $ref ) {
		local $_ = ref $ref ;
		my $class = '' ;
		my $address = '' ;
	
		if ( /^(?:SCALAR|HASH|ARRAY)$/ ) {
			( $_, $address) = overload::StrVal( $ref ) 
					=~ /([^(]+)\(([x0-9A-Fa-f]+)\)/ ;
			}
		else {
			$class = XML::Dumper::xml_escape( ref $ref );
			( $_, $address ) = overload::StrVal( $ref ) 
					=~ /$class=([^(]+)\(([x0-9A-Fa-f]+)\)/ ;
			}

		my $reused = $address && $self->{xml}{ $address }++ ;
		my $indentstr = "\n" . " " x$indent ;

		$out->[0]->{blessed_package} = $class if $class ;
		$out->[0]->{memory_address} = $address if $address ;

		if ( /^SCALAR$/ && ! $reused ) {
			$out->[0]->{defined} = 'false' unless defined $$ref ;
			$out->addelement( 0 => $$ref ) ;
			}
		elsif ( /^HASH$/ && ! $reused ) {
			foreach my $k ( keys %$ref ) {
				$out->addelement( $indentstr ) ;
				$out->addelement( newitem( $self,
						{ key => $k }, 
						$ref->{ $k }, 
						$indent +1 ) ) ;
				}

			$out->addelement( "\n" . " " x( $indent -1 ) ) ;
			}
		elsif ( /^ARRAY$/ && ! $reused ) {
			for ( my $ct = 0 ; $ct < @$ref ; $ct++ ) {
				$out->addelement( $indentstr ) ;
				$out->addelement( newitem( $self,
						{ key => $ct }, 
						$ref->[ $ct ], 
						$indent +1 ) ) ;
				}

			$out->addelement( "\n" . " " x( $indent -1 ) ) ;
			}

		my $key = /^SCALAR$/? 'scalarref':
				/^HASH$/? 'hashref':
				/^ARRAY$/? 'arrayref': '' ;

		return $key => $out ;
		}
	else {
		$out->[0]->{defined} = 'false' unless defined $ref ;
		$out->addelement( 0 => $ref ) ;
		return ( scalar => $out ) ;
		}
	}


sub newitem {
	my $self = shift ;
	my $attribs = shift ;
	my $value = shift ;
	my $indent = shift ;

	$attribs->{defined} = 'false' unless defined $value ;
	my $out = $self->newelement( %$attribs ) ;

	if ( ref $value ) {
		$out->addelement( "\n" . " " x$indent ) ;
		$out->addelement( nextpl2xml( $self, $value, $indent +1 ) ) ;
		$out->addelement( "\n" . " " x( $indent -1 ) ) ;
		}
	else {
		$out->addelement( $value ) ;
		}

	return ( item => $out ) ;
	}

sub newelement {
	my $self = shift if @_ && ( ref $_[0] || $_[0] eq __PACKAGE__ ) ;
	$self = ! $self? __PACKAGE__: ref $self? ref $self: $self ;
	
	return bless [ { @_ } ], $self ;
	}

sub addelement {
	my $self = shift ;
	my $scalar = pop ;
	my $key = @_? shift @_: 0 ;

	push @$self, $key, $scalar ;
	}

sub nvpdump {
	my $key = @_ > 3? pop( @_ ): '' ;
	my $space = @_ > 2? pop( @_ ): -1 ;
	my $self = pop @_ ;
	my @kids = $self->childnodes ;

	if ( @_ == 0 ) {
		@kids = $self->childnode('perldata')->childnodes ;
		carp( "Data source not from pl2xml" ) && return ""
				unless @kids == 1 ;
		return nvpdump( @{ $kids[0] } ) ;
		}

	my $name = shift ;
	my $pad = ' 'x$space ;

	return join "\n", map { nvpdump( @$_, $space +1 ) } @kids 
			if $name eq 'hashref' ;
	return join "\n", map { nvpdump( @$_, $space, $key ) } @kids 
			if $name eq 'arrayref' ;

	$key = $key && @kids? $key: $self->getattributes->{key} ;

	my $value = join "\n$pad", 
			map { nvpdump( @$_, $space, $key ) } @kids ;
	return $value if @kids && $kids[0][0] eq 'arrayref' ;

	$value = join "\n", '', $value, $pad if $value ;
	$value ||= $self->gettext() ;
	return sprintf "$pad<$key>%s</$key>", $value ;
	}

1 ;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

XML::Parser::Nodes - Extends XML::Parser

=head1 SYNOPSIS

  use XML::Parser::Nodes ;

=head2 Constructors

  $node = XML::Parser->new( Style => 'Nodes' )->parsefile( $xmlFileName ) ;
  $node = XML::Parser::Nodes->parsefile( $xmlFileName ) ;
  $node = new XML::Parser::Nodes $xmlFileName ;

  or

  $node = XML::Parser->new( Style => 'Nodes' )->parse( $xmlBufferedScalar ) ;
  $node = XML::Parser::Nodes->parse( $xmlBufferedScalar ) ;
  $node = new XML::Parser::Nodes $xmlBufferedScalar ;

  or

  $node = XML::Parser::Nodes->pl2xml( $ComplexPerlObject ) ;

=head2 Access Node Components

  @nodenames = $node->childlist() ;
  @elements = $node->childnodes() ;
  $nodevalue = $node->gettext() ;
  %nodeproperties = %{ $node->getattributes() } ;
  @values = @{ $node->cells( @keylist ) } ;

=head2 Survey the Document

  @nodekeys = $node->tree() ;

=head2 Retrieve a Node

  $childnode = $parentnode->childnode('nodename') ;
  @childnodes = $parentnode->childnode('nodename') ;
  $descendantnode = $parentnode->nodebykey( $nodekey ) ;

=head2 XML Output

  $xmldoc = $node->dump() ;
  $xmldoc = $node->nvpdump() ;

=head2 Create a Node Wrapper

  $parentnode = $node->wrapper( $parentname ) ;


=head1 DESCRIPTION

When XML::Parser::parse is used without callback functions, the returned object 
can get pretty hairy for complex objects.  XML::Parser::Nodes provides methods
to access that object's internals as a sequence of nodes.

XML::Parser::Nodes also has a constructor to create an object directly from a 
complex Perl object, similar to XML::Dumper->pl2xml().  The following two 
statements are equivalent:

  $xmlnode = XML::Parser::Nodes->pl2xml( $ComplexPerlObject ) ;

  $xmlnode = XML::Parser::Nodes->parse( 
		XML::Dumper->pl2xml( $ComplexPerlObject )
		) ;

As a basic background, an XML document can be thought of as nested name-value-
pairs.  Basically, a node value is either a string or a set of child nodes.  
It's easy to imagine an XML object as a complex Perl object with a hierarchy
of HASH references, whose bottom element is a scalar:

  print $company->{$division}->{$location}->{$department}->{Director}->{FirstName} ;

Might refer to a string "Jim". 

In an XML document represented by an XML::Parser::Nodes object, that value
would be accessed as:

  print $xmlnode->childnode( $company
		)->childnode( $division
		)->childnode( $location
		)->childnode( $department
		)->childnode('Director'
		)->childnode('FirstName')->gettext() ;

Alternatively,

  $nodekey = join '/', $division, $location, $department, 'Director', 'FirstName' ;
  print $xmlnode->nodebykey( $nodekey )->gettext ;

Some XML documents are more complex and contain sets of values.  

  print $company->{$division}->{$location}->{$department}->{Staff}->[0]->{FirstName} ;

Represents a complex object where department staff consists of a set of individuals, one of whom has the first name, "Jim".

One of the features of XML::Parser::Nodes is the ability to survey the contents 
of a node.  The most basic is C<childlist()> which returns an ordered list of 
element names.  If the node consists of 5 children with the same name, that 
name will be returned 5 times.

The C<tree()> function is similar, except it recurses into each child.  The 
returned values are similar to file pathnames where a slash represents
a parent->child relationship.

There are analogous methods to retrieve a node:  C<childnode()> takes an 
element name as an argument; C<nodebykey()> takes the path representation
as its argument.  When the key refers to a direct child, these two methods 
are interchangeable.  These methods each return an array, but can be called 
in a scalar context, which returns the first matching node.  In order to use 
the recursive methods and techniques, the caller should be confident that the 
target is a unique location.

C<cells()> could be applied to each child of the division staff node in the
example above and the results used in a spreadsheet application or database 
table.

This module is primarily designed to retrieve data from a complex XML 
document.  The C<dump()> method restores the XML document.  This method is 
useful for converting a branch of an large XML object into a smaller document.  
The C<wrapper()> method creates a wrapper node for this purpose.

C<childnodes()> returns the child nodes as elements.  An element is an array 
pair consisting of the element name and node value.  Custom functions will
most likely accept these elements as arguments.  C<dump()> is a wrapper for
the method C<xmlout()>, which takes this element pair as its arguments.  With
no arguments, C<childnode()> functions identically.

XML::Parser::Nodes can be used to create custom XML output.  

=head2 Example

C<dump()> can be used as a template to override, or otherwise, alter the 
document output.  The C<nvpdump()> method is a useful example that generates
output that may be specified as follows:

    <QBMSXML>
     <Signon>
      <Desktop>
       <DateTime>2012-02-29T12:40:09</DateTime>
       <Ticket>gas8p9ee-re2s9old-ref2i6t</Ticket>
       <Login>tqis.com</Login>
      </Desktop>
     </Signon>
     <MsgsRq>
      <CreditCard>
       <RequestID>546696356386</RequestID>
       <Number>4111111111111111</Number>
       <Year>2012</Year>
       <Amount>10.00</Amount>
       <Month>12</Month>
       <CardPresent>false</CardPresent>
      </CreditCard>
     </MsgsRq>
     <MsgsRq>
      <CreditCard>
       <RequestID>546696356387</RequestID>
       <Number>4123111111111111</Number>
       <Year>2014</Year>
       <Amount>20.00</Amount>
       <Month>8</Month>
       <CardPresent>false</CardPresent>
      </CreditCard>
     </MsgsRq>
    </QBMSXML>

Start by defining the data as a complex Perl object:

    $request = {
        'QBMSXML' => {
            'MsgsRq' => [ 
                {
                    'CreditCard' => {
                        'Amount' => '10.00',
                        'Year' => '2012',
                        'Number' => '4111111111111111',
                        'RequestID' => '546696356386',
                        'Month' => '12',
                        'CardPresent' => 'false'
                        }
                    },
                {
                    'CreditCard' => {
                        'Amount' => '20.00',
                        'Year' => '2014',
                        'Number' => '4123111111111111',
                        'RequestID' => '546696356387',
                        'Month' => '8',
                        'CardPresent' => 'false'
                        }
                    }
                ],
            'Signon' => {
                'Desktop' => {
                    'DateTime' => '2012-02-29T12:40:09',
                    'Ticket' => 'gas8p9ee-re2s9old-ref2i6t',
                    'Login' => 'tqis.com'
                    }
                }
            }
        } ;

The XML::Parser::Nodes module includes the C<nvpdump()> method to perform this 
transformation:

  print XML::Parser::Nodes->pl2xml( $request )->nvpdump() ;

C<nvpdump()> is called recursively on each node. The disposition of each
node is determined by its name and constituent elements.  If the node has
no elements, display the string data (the NVP value).  Otherwise, the
method handles the key (the NVP name) based on the node name:

  Set the key if node name == "item"
  Reset the key if node name == "hashref"
  Preserve the key if node name == "arrayref"

=head2 EXPORT

None by default.


=head1 DEPENDENCIES

Requires XML::Parser.  

The pl2xml function requires XML::Dumper.

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

=head1 AUTHOR

Jim Schueler, E<lt>jim@tqis.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Jim Schueler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut
