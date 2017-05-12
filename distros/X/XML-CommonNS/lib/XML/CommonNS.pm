package XML::CommonNS;
use strict;
use warnings;
use XML::NamespaceFactory qw();
use Exporter;
use vars qw($VERSION %NS @ISA @EXPORT_OK);
$VERSION = '0.06';
@ISA = qw(Exporter);

sub BEGIN {
	%NS = (
			XML 		=> 'http://www.w3.org/XML/1998/namespace',
			XMLNS 		=> 'http://www.w3.org/2000/xmlns/',
			XLINK 		=> 'http://www.w3.org/1999/xlink',
			SVG 		=> 'http://www.w3.org/2000/svg',
			XHTML 		=> 'http://www.w3.org/1999/xhtml',
			XHTML2		=> 'http://www.w3.org/2002/06/xhtml2',
			XFORMS 		=> 'http://www.w3.org/2002/xforms/cr',
			XMLEVENTS	=> 'http://www.w3.org/2001/xml-events',
			DC 			=> 'http://purl.org/dc/elements/1.1/',
			DC_TERMS	=> 'http://purl.org/dc/terms/',
			RDF 		=> 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
			RDFS 		=> 'http://www.w3.org/2000/01/rdf-schema#',
			OWL			=> 'http://www.w3.org/2002/07/owl#',
			FOAF        => 'http://xmlns.com/foaf/0.1/',
			REL	        => 'http://purl.org/vocab/relationship/',
			RSS1	    => 'http://purl.org/rss/1.0/',	
			COMMENTS	=> 'http://purl.org/net/rssmodules/blogcomments/',
			SYN		    => 'http://purl.org/rss/1.0/modules/syndication/',		
			RNG 		=> 'http://relaxng.org/ns/structure/1.0',
			XSD 		=> 'http://www.w3.org/2001/XMLSchema',
			XSI 		=> 'http://www.w3.org/2001/XMLSchema-instance',
			MATHML 		=> 'http://www.w3.org/1998/Math/MathML',
			XSLT		=> 'http://www.w3.org/1999/XSL/Transform',
			XSLFO		=> 'http://www.w3.org/1999/XSL/Format',
			SOAPENC11	=> 'http://schemas.xmlsoap.org/soap/encoding/',
			SOAPENV11	=> 'http://schemas.xmlsoap.org/soap/envelope/',
			SOAPENC12	=> 'http://www.w3.org/2003/05/soap-encoding',
			SOAPENV12	=> 'http://www.w3.org/2003/05/soap-envelope',
			WSDL11		=> 'http://schemas.xmlsoap.org/wsdl/',
			WSDL12		=> 'http://www.w3.org/2003/06/wsdl',
	);

	while (my ($k, $v) = each %NS) {		
        push @EXPORT_OK, '$' . $k;
    }
}

sub import {
	my $class = shift;
	my $pkg = caller;
	my @opt = @_;

	no strict 'refs';
	@opt = keys %NS if $opt[0] eq ':all';
	for my $exp (@opt) {
		die "No namespace available for key $exp" unless exists $NS{$exp};
		__PACKAGE__->uri($exp);
		__PACKAGE__->export_to_level( 1, $class, '$' . $exp );
    }

	return 1;
}

sub uri {
	my ($self, $exp) = @_;
	no strict 'refs';
	unless (defined ${__PACKAGE__ . "::$exp"} ) {
		${__PACKAGE__ . "::$exp"} = XML::NamespaceFactory->new($NS{$exp});
	}
	return ${__PACKAGE__ . "::$exp"};
}

1;

=pod

=head1 NAME

XML::CommonNS - A list of commonly used namespaces

=head1 SYNOPSIS

	# import $RDF, $RDFS, $OWL, $DC
	use XML::CommonNS qw(RDF RDFS OWL DC);
	
	my %CONFIG = (
	    Namespaces    => {		    
	        rdf  => "$RDF",
	        rdfs => "$RDFS",
	        owl  => "$OWL",
	        foaf => "$FOAF",
	    },
	    ExpandQNames => 1,
	);
	
	# or the uri() method
	
	my $foaf = XML::CommonNS->uri('FOAF');
	
=head1 DESCRIPTION
All you need do to use this module is import the namespaces you

want from the list below. All of those will then become available
to you. They are XML::NamespaceFactory object and can thus be used
both as simple strings and as XML::NamespaceFactory objects. See
XML::NamespaceFactory for how that may help you.

I hesitated for a while before releasing this module. As a directory
of namespaces that can't (and almost certainly shouldn't) be 
exhaustive, it implies editorial decisions and I wasn't certain it
was CPAN worthy. However, after getting really tired of tracking 
down namespaces in every single small XML muning script I made,
I wrote it for myself. After a while using it, I don't see why others
wouldn't find it useful as well.

=head1 NAMESPACES

The currently available namespaces are listed below. Should you
consider one worthy of addition (it needs to be common enough)
please simply notify me. Those marked with a start are subject to
change. I WILL change them when the corresponding specification
changes.

	XML 		http://www.w3.org/XML/1998/namespace
	XMLNS 		http://www.w3.org/2000/xmlns/
	XLINK 		http://www.w3.org/1999/xlink
	SVG 		http://www.w3.org/2000/svg
	XHTML 		http://www.w3.org/1999/xhtml
	XHTML2		http://www.w3.org/2002/06/xhtml2
	XFORMS 		http://www.w3.org/2002/xforms/cr
	XMLEVENTS	http://www.w3.org/2001/xml-events
	DC 			http://purl.org/dc/elements/1.1/
	DC_TERMS	http://purl.org/dc/terms/
	RDF 		http://www.w3.org/1999/02/22-rdf-syntax-ns#
	RDFS 		http://www.w3.org/2000/01/rdf-schema#
	OWL			http://www.w3.org/2002/07/owl#
	FOAF        http://xmlns.com/foaf/0.1/
	REL	        http://purl.org/vocab/relationship/
	RSS1	    http://purl.org/rss/1.0/	
	COMMENTS	http://purl.org/net/rssmodules/blogcomments/
	SYN		    http://purl.org/rss/1.0/modules/syndication/		
	RNG 		http://relaxng.org/ns/structure/1.0
	XSD 		http://www.w3.org/2001/XMLSchema
	XSI 		http://www.w3.org/2001/XMLSchema-instance
	MATHML 		http://www.w3.org/1998/Math/MathML
	XSLT		http://www.w3.org/1999/XSL/Transform
	XSLFO		http://www.w3.org/1999/XSL/Format
	SOAPENC11	http://schemas.xmlsoap.org/soap/encoding/
	SOAPENV11	http://schemas.xmlsoap.org/soap/envelope/
	SOAPENC12	http://www.w3.org/2003/05/soap-encoding
	SOAPENV12	http://www.w3.org/2003/05/soap-envelope
	WSDL11		http://schemas.xmlsoap.org/wsdl/
	WSDL12		http://www.w3.org/2003/06/wsdl

=head1 METHODS

=over

=item uri
	
	Allows you to directly retrieve one of the URI objects without doing the import() dance.
	
=back

=head1 AUTHOR

Chris Prather, E<lt>chris@prather.orgE<gt>
Robin Berjon, E<lt>robin.berjon@expway.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Robin Berjon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
