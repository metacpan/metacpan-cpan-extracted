#!/usr/bin/env perl

# Load all WSDL and XSD files you specify (e.g., from save_wsdl_schemas.pl or
# XML::CompileX::Schema::Loader directly), compile them, and then report on the
# available SOAP operations and schema elements.
#
# example usage:
#
#     $ perl load_wsdl_schema.pl <list of saved WSDL and XSD files...>
#
# example usage for a directory tree of files:
#
#     $ find . -type f -print0 | xargs -0 perl load_wsdl_schema.pl

use Modern::Perl '2010';
use List::Util 1.33 'any';
use XML::Compile::SOAP11;
use XML::Compile::WSDL11;
use XML::Compile::Transport::SOAPHTTP;
use XML::Compile::SOAP::Util 'WSDL11';
use XML::Compile::Util ':constants';
use XML::LibXML 1.70;

# use XML::Compile::WSDL11 to import WSDL and XSD files specified on the
# command line
my $wsdl = XML::Compile::WSDL11->new;
for my $document ( map { XML::LibXML->load_xml( location => $_ ) } @ARGV ) {
    my $namespace = $document->documentElement->namespaceURI;
    if ( $namespace eq WSDL11 ) { $wsdl->addWSDL($document) }
    elsif ( any { $namespace eq $_ } ( SCHEMA1999, SCHEMA2000, SCHEMA2001 ) )
    {
        $wsdl->importDefinitions($document);
    }
}

# make sure they compile
$wsdl->compileCalls;

# demonstrate that operations and elements are loaded from all schemas
say for OPERATIONS => sort map { $_->name } $wsdl->operations;
say for ELEMENTS => $wsdl->elements;
