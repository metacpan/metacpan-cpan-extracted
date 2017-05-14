#
# To do:
# - later: ErrorHandler, Locale?

package XML::Filter::SAXT;
use strict;

use vars qw( %SAX_HANDLERS );

%SAX_HANDLERS = ( DocumentHandler => 
		  [ "start_document",
		    "end_document",
		    "start_element",
		    "end_element",
		    "characters",
		    "processing_instruction",
		    "comment",
		    "start_cdata",
		    "end_cdata",
		    "entity_reference",
		    "set_document_locator"	# !! passes {Locator=>$perlsax}
		    ],

		  DTDHandler => 
		  [ "notation_decl",
		    "unparsed_entity_decl",
		    "entity_decl",
		    "element_decl",
		    "attlist_decl",
		    "doctype_decl",
		    "xml_decl"
		    ],

		  EntityResolver =>
		  [ "resolve_entity" ]);

#
# Usage:
#
#	$saxt = new XML::Filter::SAXT ( { Handler => $out0 },
#					{ DocumentHandler => $out1 },
#					{ DTDHandler => $out3,
#					  Handler => $out4 
#					}
#				      );
#
#	$perlsax = new XML::Parser::PerlSAX ( Handler => $saxt );
#	$perlsax->parse ( [OPTIONS] );
#
sub new
{
    my ($class, @out) = @_;

    my $self = bless { Out => \@out }, $class;

    for (my $i = 0; $i < @out; $i++)
    {
	for my $handler (keys %SAX_HANDLERS)
	{
	    my $callbacks = $SAX_HANDLERS{$handler};
	    my $h = ($self->{Out}->[$i]->{$handler} ||= $self->{Out}->[$i]->{Handler});
	    next unless defined $h;

	    for my $cb (@$callbacks)
	    {
		if (UNIVERSAL::can ($h, $cb))
		{
		    $self->{$cb} .= "\$out->[$i]->{$handler}->$cb (\@_);\n";
		}
	    }
	}
    }

    for my $handler (keys %SAX_HANDLERS)
    {
	my $callbacks = $SAX_HANDLERS{$handler};
	for my $cb (@$callbacks)
	{
	    my $code = $self->{$cb};
	    if (defined $code)
	    {
		$self->{$cb} = 
		    eval "sub { my \$out = shift->{Out}; $code }";
	    }
	    else
	    {
		$self->{$cb} = \&noop;
	    }
	}
    }
    return $self;
}
				       
sub noop
{
    # does nothing
}

for my $cb (map { @{ $_ } } values %SAX_HANDLERS)
{
    eval "sub $cb { shift->{$cb}->(\@_); }";
}

1; # package return code

__END__

=head1 NAME

XML::Filter::SAXT - Replicates SAX events to several SAX event handlers

=head1 SYNOPSIS

 $saxt = new XML::Filter::SAXT ( { Handler => $out1 },
				 { DocumentHandler => $out2 },
				 { DTDHandler => $out3,
				   Handler => $out4 
				 }
			       );

 $perlsax = new XML::Parser::PerlSAX ( Handler => $saxt );
 $perlsax->parse ( [OPTIONS] );

=head1 DESCRIPTION

SAXT is like the Unix 'tee' command in that it multiplexes the input stream
to several output streams. In this case, the input stream is a PerlSAX event
producer (like XML::Parser::PerlSAX) and the output streams are PerlSAX 
handlers or filters.

The SAXT constructor takes a list of hash references. Each hash specifies
an output handler. The hash keys can be: DocumentHandler, DTDHandler, 
EntityResolver or Handler, where Handler is a combination of the previous three
and acts as the default handler.
E.g. if DocumentHandler is not specified, it will try to use Handler.

=head2 EXAMPLE

In this example we use L<XML::Parser::PerlSAX> to parse an XML file and
to invoke the PerlSAX callbacks of our SAXT object. The SAXT object then
forwards the callbacks to L<XML::Checker>, which will 'die' if it encounters
an error, and to L<XML::Hqandler::BuildDOM>, which will store the XML in an
L<XML::DOM::Document>.

 use XML::Parser::PerlSAX;
 use XML::Filter::SAXT;
 use XML::Handler::BuildDOM;
 use XML::Checker;

 my $checker = new XML::Checker;
 my $builder = new XML::Handler::BuildDOM (KeepCDATA => 1);
 my $tee = new XML::Filter::SAXT ( { Handler => $checker },
				   { Handler => $builder } );

 my $parser = new XML::Parser::PerlSAX (Handler => $tee);
 eval
 {
    # This is how you set the error handler for XML::Checker
    local $XML::Checker::FAIL = \&my_fail;

    my $dom_document = $parser->parsefile ("file.xml");
    ... your code here ...
 };
 if ($@)
 {
    # Either XML::Parser::PerlSAX threw an exception (bad XML)
    # or XML::Checker found an error and my_fail died.
    ... your error handling code here ...
 }

 # XML::Checker error handler
 sub my_fail
 {
   my $code = shift;
   die XML::Checker::error_string ($code, @_)
	if $code < 200;	  # warnings and info messages are >= 200
 }

=head1 CAVEATS

This is still alpha software. 
Package names and interfaces are subject to change.

=head1 AUTHOR

Send bug reports, hints, tips, suggestions to Enno Derksen at
<F<enno@att.com>>. 

