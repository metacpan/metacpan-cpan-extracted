package XML::STX;

require 5.005_02;
BEGIN { require warnings if $] >= 5.006; }
use strict;
use vars qw($VERSION);
use XML::STX::TrAX;
use XML::STX::Runtime;
use XML::STX::Parser;

@XML::STX::ISA = qw(XML::STX::TrAX);
$VERSION = '0.43';

# --------------------------------------------------

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $options = ($#_ == 0) ? shift : { @_ };

    my $self = bless $options, $class;

    # TrAX init stuff
    $self->{URIResolver} = XML::STX::TrAX::URIResolver->new();
    $self->{ErrorListener} = XML::STX::TrAX::ErrorListener->new();

    return $self;
}

# deprecated API; use TrAX instead! ------------------------------

sub get_stylesheet {
    my ($self, $parser, $uri) = @_;

    my $p = XML::STX::Parser->new();
    $p->{DBG} = $self->{DBG};

    $parser->{Handler} = $p;
    return $parser->parse_uri($uri);
}

sub transform {
    my ($self, $sheet, $parser, $uri, $handler) = @_;

    my $runtime = XML::STX::Runtime->new();

    $parser->{Handler} = $runtime;
    $runtime->{Handler} = $handler;
    $runtime->{Sheet} = $sheet;

    return $parser->parse_uri($uri);
}

1;
__END__

=head1 NAME

XML::STX - a pure Perl STX processor

=head1 SYNOPSIS

 use XML::STX;

 $stx = XML::STX->new();

 $transformer = $stx->new_transformer($stylesheet_uri);
 $transformer->transform($source_uri);

=head1 DESCRIPTION

XML::STX is a pure Perl implementation of STX processor. Streaming 
Transformations for XML (STX) is a one-pass transformation language for 
XML documents that builds on the Simple API for XML (SAX). See 
http://stx.sourceforge.net/ for more details.

Dependencies: XML::SAX, XML::NamespaceSupport and Clone.

The current version is unstable.

=head1 USAGE

=head2 Shortcut TrAX-like API

Thanks to various shortcuts of the TrAX-like API, this is the simplest way to 
run transformations. This can be what you want if you are happy with just one
transformation context per stylesheet, and your input data is in files. 
Otherwise, you may want to use some more features of this API 
(see L<Full TrAX-like API|full trax-like api>).

 use XML::STX;

 $stx = XML::STX->new();

 $transformer = $stx->new_transformer($stylesheet_uri);
 $transformer->transform($source_uri);

=head2 Full TrAX-like API

This is the regular interface to XML::STX allowing to run independent 
transformations for single template, bind external parameters,
and associate drivers/handlers with input/output channels.

=for html See <a href="TrAXref.html">TrAX-like API Reference</a> for more details.

 use XML::STX;

 $stx = XML::STX->new();

 $stylesheet = $stx->new_source($stylesheet_uri);
 $templates = $stx->new_templates($stylesheet);
 $transformer = $templates->new_transformer();

 $transformer->{Parameters} = {par1 => 5, par2 => 'foo'}';

 $source = $stx->new_source($source_uri);
 $result = $stx->new_result();

 $transformer->transform($source, $result);

=head2 SAX Filter

 use XML::STX;
 use SAX2Parser;
 use SAX2Handler;

 $stx = XML::STX->new();
 $stx_parser = XML::STX::Parser->new();
 $xml_parser1 = SAX2Parser->new(Handler => $stx_parser);
 $stylesheet =  $xml_parser1->parse_uri($templ_uri);

 $writer = XML::SAX::Writer->new();
 $stx = XML::STX->new(Handler => $writer, Sheet => $stylesheet );
 $xml_parser2 = SAX2Parser->new(Handler => $stx);
 $xml_parser2->parse_uri($data_uri);

=head2 Legacy API (deprecated)

 use XML::STX;

 $stx = XML::STX->new();
 $parser_t = SAX2Parser->new();
 $stylesheet = $stx->get_stylesheet($parser_t, $templ_uri);

 $parser = SAX2Parser->new();
 $handler = SAX2Handler->new();
 $stx->transform($stylesheet, $parser, $data_uri, $handler);

=head2 Command-line Interface

XML::STX is shipped with B<stxcmd.pl> script allowing to run STX transformations
from the command line.

Usage: 

 stxcmd.pl [OPTIONS] <stylesheet> <data> [PARAMS]

Run C<stxcmd.pl -h> for more details.

=head1 AUTHOR

Petr Cimprich (Ginger Alliance), petr@gingerall.cz

=head1 SEE ALSO

XML::SAX, XML::NamespaceSupport, perl(1).

=cut
