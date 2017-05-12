package XAS::Lib::XML;

our $VERSION = '0.01';

use Try::Tiny;
use XML::LibXML;
use XML::LibXML::XPathContext;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  import    => 'class',
  accessors => 'parser schema doc xpc',
  utils     => ':validation dotid compress',
  constants => 'TRUE FALSE',
  vars => {
    PARAMS => {
      -xsd => { optional => 1, default => undef },
      -default_namespace => { optional => 1, default => 'def' },
    },
    XMLERR => '',
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub get_items {
    my $self = shift;
    my ($xpath) = validate_params(\@_, [1]);

    my @nodes;
    my $xpc  = $self->xpc;
    my $node = $self->doc->documentElement();

    if (my ($key) = $xpc->findnodes($xpath, $node)) {

        if ($key->hasChildNodes()) {

            @nodes = $key->childNodes();

        }

    }

    return wantarray ? @nodes : \@nodes;

}

sub get_item {
    my $self = shift;
    my ($xpath) = validate_params(\@_, [1]);

    my $value = '';
    my $xpc   = $self->xpc;
    my $node  = $self->doc->documentElement();

    if (my ($key) = $xpc->findnodes($xpath, $node)) {
    
        $value = $key->textContent();

    }

    return $value;

}

sub get_node {
    my $self = shift;
    my ($xpath) = validate_params(\@_, [1]);
    
    my $xpc   = $self->xpc;
    my $node  = $self->doc->documentElement();
    
    return $xpc->findnodes($xpath, $node);
    
}

sub is_valid {
    my $self = shift;

    my $doc = $self->doc;

    return TRUE unless (defined($self->{'schema'}));

    try {

        $self->schema->validate($doc);    # validate the document

    } catch {

        my $ex = $_;

        $self->class->var('XMLERR', $ex);

        $self->throw_msg(
            dotid($self->class) . '.is_valid',
            'xml_validate',
        );

    };

    return TRUE;

}

sub load {
    my $self = shift;
    my ($xml) = validate_params(\@_, [1]);

    try {

        # load and parse the document

        $self->{'doc'} = $self->parser->load_xml(string => $xml, {no_blanks => 1});

        # find and register all namespaces

        $self->_load_namespace();

    } catch {

        my $ex = $_;

        $self->throw_msg(
            dotid($self->class). '.parser',
            'xml_parser',
            $ex
        );

    };

}

sub xmlerr {
    my $class = shift;
    my ($value) = validate_params(\@_, [ 
        { optional => 1, default => undef }
    ]);

    if (defined($value)) {

        class->var('XMLERR', $value);

    }
    
    return class->var('XMLERR');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{'parser'} = XML::LibXML->new();
    $self->{'xpc'}    = XML::LibXML::XPathContext->new();

    if (defined($self->{'xsd'})) {

       $self->{'schema'} = XML::LibXML::Schema->new(location => $self->xsd);

    }

    return $self;

}

sub _load_namespace {
    my $self = shift;

    my $hash;
    my $doc = $self->doc;
    my $def = $self->default_namespace;

    foreach my $node ($doc->findnodes('//*/namespace::*')) {

        my $ns  = $node->getLocalName() || $def;
        my $uri = $node->getValue();

        $hash->{$ns} = $uri;   # filter multiple namespaces

    }

    while (my ($key, $value) = each(%$hash)) {

        $self->xpc->registerNs($key, $value);

    }

}

1;

__END__

=head1 NAME

XAS::Lib::XML - A class to manipulate XML documents

=head1 SYNOPSIS

 use XAS::Lib::XML;
 
 my $xpath;
 my $buffer = <STDIN>;
 my $filename = 'schemna.xsd',

 my $xml = XAS::Lib::XML->new(
     -xsd => $filename,
 );

 $xml->load($buffer);
 if ($xml->is_valid) {

    $xpath = '//sif:SIF_Header/sif:SIF_SourceId';
    printf("value: %s\n", $xml->get_item($xpath));

 }

=head1 DESCRIPTION

This module is able to load, parse and validate a xml document.

=head1 METHODS

=head2 new

This method initialize the module and takes these parameters:

=over 4

=item B<-xsd>

The XML Schema to validate against.

=item B<-default_namespace>

The default namespace to use, defaults to 'def'.

=back

=head2 load($xml)

This method loads and parses a XML document.

=over 4

=item B<$xml>

The XML to load.

=back

=head2 is_valid

This method validates the document to the XSD. If valid returns TRUE,
otherwise throws an exception.

=head2 get_item($xpath)

This method will return the string valuse of the Xpath.

=over 4

=item B<$xpath>

The Xpath string.

=back

=head2 get_items($xpath)

This method will return an array of nodes for the given Xpath.

=over 4

=item B<$xpath>

The Xpath string.

=back

=head2 get_node($xpath)

This method will return the node associated with the xpath.

=over 4

=item B<$xpath>

The Xpath string.

=back

=head2 xmlerr

A class method to return the full XML error string.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=item L<XML::LibXML|XML::LibXML>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
