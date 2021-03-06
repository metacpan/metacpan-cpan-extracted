#!/usr/local/bin/perl -w
##
##  XML/YYLex.pm
##
##  Daniel B��wetter, Thu Nov 14 21:06:34 CET 2002
##  boesswetter@peppermind.de
##
##  $Log: YYLex.pm,v $
##  Revision 1.4  2003/01/11 00:50:18  daniel
##  Oops, forgor versions numbers for CPAN compatibility and added homepage url
##  in several places (all PODs and README)
##
##  Revision 1.3  2003/01/10 22:30:50  daniel
##  version 0.3 (perl 5.6 and sablot 0.90)
##
##  Revision 1.2  2002/11/24 17:33:06  daniel
##  KNOWN BUGS added
##
##  Revision 1.1.1.1  2002/11/24 17:18:15  daniel
##  initial checkin
##
##

package XML::YYLex;
our $VERSION = '0.04';
use strict qw(subs vars);
use vars qw(
	$STATE_NEW_NODE
	$STATE_DESCEND_NODE
	$STATE_NODE_DONE
	$PREFIX_OPENING
	$PREFIX_CLOSING
	$TOKEN_OTHER_TAG
	$TOKEN_TEXT
);

use Carp;

$STATE_NEW_NODE		= 0;
$STATE_DESCEND_NODE	= 1;
$STATE_NODE_DONE	= 2;

$PREFIX_CLOSING		= "_";
$PREFIX_OPENING		= "";
$TOKEN_OTHER_TAG	= "OTHER";
$TOKEN_TEXT		= "TEXT";

=pod

=head1 NAME

XML::YYLex - Perl module for using perl-byacc with XML-data

=head1 SYNOPSIS

  use XML::YYLex;

  ## create an object of a sublass of XML::YYLex suitable for your
  ## DOM-parser:

  my $parser = XML::YYLex::create_object(
	document => $xmldom_or_sablotron_dom_object
	debug => 0,              # or 1
	ignore_empty_text => 1,  # probably what you would expect
	yydebug => \&some_func,  # defaults to a croak
	yyerror => \&other_func  # defaults to a carp
  );

  ## return the result of yyparse
  my $result = $parser->run( "ByaccPackage" );

=head1 ABSTRACT

C<XML::YYLex> is a perl module that helps you build XML-parsers with
perl-byacc (a version of Berkeley Yacc that can produce perl-code).
It uses a regular DOM-parser (currently C<XML::DOM> or C<XML::Sablotron::DOM>)
as what would normally be called a scanner (hence the name 'yylex' which
is what scanner-functions are traditionally called). You can then specify
grammars in byacc in which XML-tags or text-blocks appear as tokens and
thus simplifies interpretation of XML-data (sometimes :).

=head1 DESCRIPTION

XML::YYLex implements an abstract base-class that can be subclassed for
specific DOM-parsers. As of this writing, C<XML::DOM> and C<XML::Sablotron::DOM>
are supported, but others might be easily added. If you want to add
support for another DOM-parser, copy one of the modules C<XML::DOM::YYLex>
or C<XML::Sablotron::DOM::YYLex> to an appropriate name and modify it
to work with your DOM-parser.

C<XML::YYLex> contains two public functions:

=over 4

=item C<create_object( %args )>

serves as a static factory method that creates an instance of the approptiate
subclass. The possible keye for %args are

=over 4

=item C<document>

a reference to your DOM-document (whichever class that may be). This
is used for determining which parser-specific subclass to create. This
argument must be given. If you pass a single scalar to C<create_object>
instead of a hash, it is assumed to be the C<document>.

=item C<debug>

when set to a true value, produces lots of debug information, as well
from the yacc-parser as from C<XML::YYLex> itself. Defaults to false.

=item C<yydebug> and C<yyerror>

code-refs with the same purpose as in byacc itself: called with a single
argument which is a warning or an error. Defaults are the functions
C<XML::YYLex::yydebug> and C<XML::YYLex::yyerror> (see below).

=item C<ignore_empty_text>

when set to a true value, emtpy text-nodes are not considered to be tokens
(which reduces your grammars complexity a lot). True by default.

=back

=cut

sub create_object {

    my %args;
    if ( $#_ == 0 ) {
	$args{document} = shift;
    } else {
	%args = @_;
    }

    if ( !$args{debug} ) {
        # omit those ugly warnings
        $SIG{__WARN__} = sub{ warn @_ if $_[0] !~ /^yy/ };
    }

    die "no DOM-document given" if ref !$args{document};

    if ( ref( $args{document} ) =~ /^XML::Sablotron/ ) {
	eval "use XML::Sablotron::DOM::YYLex;";
	return new XML::Sablotron::DOM::YYLex( \%args );
    } else {
	eval "use XML::DOM::YYLex;";
	return new XML::DOM::YYLex( \%args );
    }
}

=pod

=item C<run( $namespace_of_parser )>

which calls the byacc-generated C<yyparse>() function with the appropriate
parameters and returns it's value. C<$namespace_of_parser> is (you
won't believe it) the namespace of the parser generated by perl-byacc
(actually the same string that you specified with C<-P> on the byacc
command line).

=back

=cut

sub run {
    my ( $self, $class ) = @_;

    eval "use $class";
    die( $@ ) if $@;
    $self->{parser_package} = $class;
    my $ref = &{$class."::new"}( $class, \&_yylex, $self->{yyerror}, $self->{yydebug} );

    return $ref->yyparse( [ $self, $self->{document} ] );
}

=pod

Furthermore the following functions are implemented in this package,
but you will most likely never call them directly. However, knowledge
of these might be necassary when subclassing C<XML::YYLex>.

=over 4

=item C<_yylex( $self, $doc )>

This function implements the traversal of the DOM-tree in an order that
would be the order of nodes in the XML-file (why don't we use a SAX-parser
right-away? Because SAX-parsers don't implement nice objects for 
Nodes of the tree and their attributes like DOM-parsers do, that's why).
This one's where the magic happens.

=cut

sub _yylex {
	my $ref = shift;
	my ( $self, $doc ) = @$ref;

	print STDERR "entering _yylex with state $self->{state}\n"
		if $self->{debug};

	##
	## initialization
	##
	if ( !defined( $self->{current_node} ) ) {
	    $self->{current_node} = $self->_xml_getDocumentElement( $doc );
	    $self->{state} = $STATE_NEW_NODE;
	}

	my @res;
	##
	## new node
	##
	if ( $self->{state} == $STATE_NEW_NODE ) {

	    $self->{state} = !$self->_xml_isTextNode( $self->{current_node} )
		? $STATE_DESCEND_NODE : $STATE_NODE_DONE;

	    @res = ( $self->_node_to_token( $self->{current_node},
		    $PREFIX_OPENING ), $self->{current_node} );

	##
	## node's children
	##
	} elsif ( $self->{state} == $STATE_DESCEND_NODE ) {

	    ## has children ?
	    if ( my @c = @{$self->{current_node}->getChildNodes} ) {

		## yes

		#$self->{state} = $STATE_DESCEND_NODE;
		$self->{current_node} = $c[0];
	        $self->{state} = !$self->_xml_isTextNode( $self->{current_node} )
		    ? $STATE_DESCEND_NODE : $STATE_NODE_DONE;

		#while ( $self->_xml_isElementNode( $c[0] ) ) { shift @c }
		@res = ( $self->_node_to_token( $c[0], $PREFIX_OPENING ), $c[0] );

	    } else {

		## no children
		
		$self->{state} = $STATE_NODE_DONE;
		@res =( $self->_node_to_token( $self->{current_node}, $PREFIX_CLOSING ) );
	    }
	##
	## node done 
	##
	} elsif ( $self->{state} == $STATE_NODE_DONE ) {

	    if ( defined( my $c = $self->{current_node}->getNextSibling ) ) {
		## same as STATE_NEW_NODE above:
		$self->{current_node} = $c;
	        $self->{state} = $STATE_DESCEND_NODE;
	        @res = ( $self->_node_to_token( $self->{current_node}, $PREFIX_OPENING ),
		    $self->{current_node} );
	    } elsif ( !$self->_xml_isDocumentNode( $self->{current_node}->getParentNode ) )
	    {
		$self->{current_node} = $self->{current_node}->getParentNode;
		$self->{state} = $STATE_NODE_DONE;
		@res =( $self->_node_to_token( $self->{current_node}, $PREFIX_CLOSING ) );
	    } else {
		## end of document
		@res = ( 0 );
	    }
	}

	#print STDERR "res=".$res[0]." ".( defined( $res[1] ) ? $res[1]->getNodeName : "" )."\n";
	print STDERR "leaving _yylex with state $self->{state}\n"
		if $self->{debug};

	if ( $self->{ignore_empty_text} and defined( $res[1] )
		and $self->_xml_isTextNode( $res[1] )
		and $res[1]->getNodeValue =~ /^\s*$/ )
	{
	    ## ignore empty text-nodes
	    $self->{state} = $STATE_NODE_DONE;
	    return &_yylex( [ $self, $doc ] ); ## recursion
	} else {
	    print "res=".join( ", ", @res )."\n" if ( $self->{debug} );
	    return @res;
	}
}

=pod

=item C<_node_to_token( $self, $node, $prefix )>

This function determines the token-number for a given node. C<$prefix>
equals C<$XML::YYLex::PREFIX_OPENING> (usually empty) for opening
tags and C<$XML::YYLex::PREFIX_CLOSING> (the underscore "_" by
default). The default behaviour is to look for a symbol with the name
of the node (for elements) in the namespace of your byacc-generated
parser. C<$XML::YYLex::TOKEN_TEXT> is used for text-nodes and
C<$XML::YYLex::TOKEN_OTHER> (I<OTHER> by default) is used for unknwon
tags (when no token with that name exists). For closing elements, the
prefix is prepended to the tagname (i.e. C<_html> for C<</html>>).

=cut

sub _node_to_token {
    my $self = shift;
    my $node = shift;
    my $prefix = shift;

    #print STDERR "_node_to_token: ".$node->getNodeName." ".$prefix."\n";
    my $res;
    if ( $self->_xml_isTextNode( $node ) ) {
	#print STDERR ">>>>>T�xt ".$node->getNodeValue."\n";
	$res = ${$self->{parser_package}."::".$TOKEN_TEXT};
    } elsif ( !defined( $res =
	${$self->{parser_package}."::".$prefix.$node->getNodeName} ) )
    {
	$res = ${$self->{parser_package}."::".$prefix.$TOKEN_OTHER_TAG};
    }

    print STDERR "_node_to_token: res=$res\n" if ( $self->{debug} );
    return $res;
}

=pod

=item C<yyerror( $err )> and C<yydebug( $err )>

These are the default debug- and error-handlers respectively if no
other functions are given to create_object. C<yyerror> croaks and 
C<yydebug> carps it's arguments.

=cut

sub yyerror {
    croak( "yyerror: @_" );
}

sub yydebug {
    carp( "yyerror: @_" );
}

=pod

=item C<new( $unblessed_hashref )>

Don't call it. It serves as constructor for child-classes and must be
given an almost initialized object (an C<$unblessed_hashref>). See the code
for details.

=cut

sub new {
    #print "new: ".join( ",", @_ )."\n";
    my ( $class, $args_ref ) = @_;
    #print $args_ref."\n";
    my $self = bless $args_ref, $class;
    $self->{yyerror} = $self->{yyerror} || \&yyerror;
    $self->{yydebug} = $self->{yydebug} || \&yydebug;
    $self->{ignore_empty_text} = $self->{ignore_empty_text} || 1;
    return $self;
}

1;
__END__

=pod

=head1 SUBCLASSING

A subclass for a specific DOM-parser needs to implement the following
methods:

=over 4

=item C<_xml_getDocumentElement( $dom_document )>

returns the root node of C<$dom_document>.

=item C<_xml_isTextNode( $dom_node )>

returns a true value if the given node is a text-node.

=item C<_xml_isElementNode( $dom_node )>

returns a true value if the given node is an element.

=item C<_xml_isDocumentNode( $dom_node )>

returns a true value if the given node is the root node of it's document.

=back

=head1 EXAMPLE

Here's a simple example. Imagine the following XML-document:

	<html>
	<head>
	<title>this is my document's title</title>
	</head>
	<body>
	<haystack needle="XML::YYLex is such a great module."/>
	</body>
	</html>

Our byacc-input might look like this:

	%token html _html head _head title _title body _body haystack \
		_haystack TEXT OTHER _OTHER


	%start HTMLDOCUMENT

	%%

	HTMLDOCUMENT:	html HEAD BODY _html;

	HEAD:		head _head
		|	head TITLE _head
			;

	TITLE:		title _title
		|	title TEXT title
			{ print $2->getNodeValue."\n"; }
			;

	BODY:		body _body
		|	body haystack _haystack _body
			{ print $2->getAttribute( "needle" )."\n"; }

	%%

The parser-definition must be turned to a perl-module C<Demo.pm>
with the command

	byacc -P Demo demo.y

(assuming that the definition resides in the file C<demo.y>).

The glue between XML-file and parser-definition is the followin perl-program

	use strict;
	use XML::YYLex;

	my $dom_document;
	if ( &you_want_to_use_XML_DOM ) {

	    ## XML::DOM initialization
	    my $dom_parser = new XML::DOM::Parser
	    $dom_document = $dom_parser->parsefile( "foo.xml" );
	} elsif( &you_want_to_use_sablotron )  {

	    ## XML::Sablotron::DOM initialization
	    my $sit = new XML::Sablotron::Situation;
	    $dom_document = XML::Sablotron::DOM::parse( $sit, "foo.xml" );
	}

	my $p = &XML::YYLex::create_object( document => $dom_document );
	$p->run( "Demo" );

This hopefully produces the two lines of output

	this is my document's title
	XML::YYLex is such a great module.

In this case you were probably better off parsing the document by hand,
but in more complex cases, C<XML::YYLex> might significantly help you.

=head1 KNOWN BUGS

Comments an processing instructions cause errors.

=head1 SEE ALSO

L<XML::DOM>, L<XML::DOM::YYLex>, L<XML::Sablotron::DOM>, L<XML::Sablotron::DOM::YYLex> 

The XML-YYLex homepage: http://home.debitel.net/user/boesswetter/xml_yylex/

=head1 AUTHOR

Daniel Boesswetter, E<lt>boesswetter@peppermind.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Daniel Boesswetter

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
