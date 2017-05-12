package XML::Bare::SAX::Parser;

$VERSION = "0.01";

use base qw(DynaLoader);

bootstrap XML::Bare::SAX::Parser $VERSION;

use vars qw ($VERSION);
use strict;

sub new {
    my $class = shift;
    unshift @_, 'Handler' unless @_ != 1;
    my %p = @_;
    return bless \%p, $class;
}

#sub DESTROY {
#   my $self = shift;
#   XML::Bare::SAX::Parser::free_tree();
#}

sub supported_features {
    my $self = shift;
    # Only namespaces are required by all parsers
    return (
        'http://xml.org/sax/features/namespaces',
    );
}

sub parse_string {
    my $self = shift;
    my $string = shift;
    my $handler = $self->{Handler};
    my $document = { Parent => undef };
    
    $handler->start_document($document);
    #my $node = { Name => 'xml' };
    #$handler->start_element($node);
    XML::Bare::SAX::Parser::parse( $handler, $string );
    #$handler->end_element($node);
    $handler->end_document($document);
}

sub parse_file {
  my $self = shift;
  my $file = shift;
  open( FILE, $file );
  $self->parse_uri( $file );
  close( FILE );
}

sub parse_uri {
    my $self = shift;
    my $file = shift;
    
    open( FILE, $file );
    my $string; { local $/ = undef; $string = <$file>; }
    close( FILE );
    my $handler = $self->{Handler};
    my $document = { Parent => undef };
    
    $handler->start_document($document);
    #my $node = { Name => 'xml' };
    #$handler->start_element($node);
    
    XML::Bare::SAX::Parser::parse( $handler, $string );
    #$handler->end_element($node);
    $handler->end_document($document);
}

1;

__END__

=head1 NAME

XML::Bare::SAX::Parser

=head1 SYNOPSIS

  use XML::Simple;
  use Data::Dumper;
  
  $XML::Simple::PREFERRED_PARSER = 'XML::Bare::SAX::Parser';
  
  my $ref = XMLin("<xml><namea blah=1>bob</namea><nameb>testsfs</nameb></xml>");
  
  print Dumper( $ref );

=head1 DESCRIPTION

This module uses the 'Bare XML' parser from XML::Bare to generate Perl SAX calls.
The parser itself is minimalistic and is a simle state engine written in ~500 lines
of C.

=head2 Supported XML

The XML parser used in the module can parse standard XML cleanly. Note that is very
accepting in its parsing and will continue parsing regardless of whether the XML you
feed it is valid or not.

=head2 Parsing Limitations / Features

=over 2

=item * XML Parser demands a properly structured XML document

XML Parsing will generate rubbish if you feed it XML that does not have
ending tags for each of the opening tags contained in the document. The structure
of the passed XML text must be clean in order for the parser to work properly.

=item * Mixed XML is not supported

Mixed XML -will- parse, but it will not generate SAX calls for the mixed content.
The mixed content will be ignored.

=item * Extended xml node types are discarded

Doctype is ignored, comments are ignored, PI sections are ignored.

=item * CDATA sections are parsed properly

=back

=head2 Module Functions

=over 2

=item * C<< $ob = new XML::Bare::SAX::Parser( ... ) >>

Basic constructor; used behind the scenes by the calling SAX Listener.

=back

=head2 Functions Used Internally

=over 2

=item * C<< $ob->parse() >>

=item * C<< $ob->free_tree() >>

=back

=head2 Performance

In comparison to other SAX parsers, XML::Bare::SAX::Parser is extremely fast.
It runs nearly 10 times faser than the other Perl SAX Parsers available. It
does so by only generating calls for a basic set of XML features.

See XML::Bare POD for some example benchmarks of XML::Simple run with this
parser in comparison to other tree parsers including XML::Bare.

=head2 Apologetics

The feature set of the parser make it optimal for use with XML::Simple.

If you like the parser in XML::Bare but prefer using XML::Simple and the
structure it generates then this module is for you.

Note that the author of XML::Simple has expressed fairly strong dissaproval
of the lax parsing of XML::Bare and probably would not reccomend using his
module in combination with XML::Bare::SAX::Parser. That said, it is a free
country, and all mentioned modules are open source. Hurray for the freedom
to choose and the ability to get more speed out of the the modules you like.

If you like this module, please reccomend it to others. If you have problems
with it, please let me know what issues you have and I will attempt to resolve
them.

If you have gripes about the module not parsing according to the official
XML specifications, you should switch to using a different SAX parser.

=head1 LICENSE

  Copyright (C) 2007 David Helkowski
  
  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License as
  published by the Free Software Foundation; either version 2 of the
  License, or (at your option) any later version.  You may also can
  redistribute it and/or modify it under the terms of the Perl
  Artistic License.
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

=cut
