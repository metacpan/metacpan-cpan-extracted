package XML::Schematron::LibXSLT;
use Moose::Role;
use namespace::autoclean;

use XML::LibXSLT;
use XML::LibXML;


has xml_parser => (
    is          =>  'ro',
    isa         =>  'XML::LibXML',
    required    =>  1,
    default     =>  sub { XML::LibXML->new(); },
);

has xslt_processor => (
    is          =>  'ro',
    isa         =>  'XML::LibXSLT',
    required    =>  1,
    default     =>  sub {  XML::LibXSLT->new(); },
);

sub verify {
    my $self = shift;    
    my $xml = shift;

    $self->parse_schema if $self->has_schema;

    my $template = $self->dump_xsl;
    my $xml_doc;

    if ( $xml =~ /^\s*<\?\s*(xml|XML)\b/ ) {
        $xml_doc = $self->xml_parser->parse_string($xml);
    }
    else {
        $xml_doc = $self->xml_parser->parse_file($xml);
    }

    my $style_doc = $self->xml_parser->parse_string($template);
    
    my $stylesheet = $self->xslt_processor->parse_stylesheet($style_doc);
    my $result = $stylesheet->transform($xml_doc);
    my $ret_string = $stylesheet->output_as_bytes($result);

    if (wantarray) {
        my @ret_array = split "\n", $ret_string;
        return @ret_array;
    }

    return $ret_string;
}

with 'XML::Schematron::XSLTProcessor';

1;

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

XML::Schematron::LibXSLT - Perl extension for validating XML with XPath/XSLT expressions.

=head1 SYNOPSIS


  use XML::Schematron;
  my $pseudotron = XML::Schematron->>new_with_traits( traits => ['LibXSLT'], schema => 'my_schema.xml');
  my $messages = $pseudotron->verify('my_doc.xml');

  if ($messages) {
      # we got warnings or errors during validation...
      ...
  }

  OR, in an array context:

  my $pseudotron = XML::Schematron::LibXSLT->new(schema => 'my_schema.xml');
  my @messages = $pseudotron->verify('my_doc.xml');


  OR, just get the generated xsl:

  my $pseudotron = XML::Schematron::LibXSLT->new(schema => 'my_schema.xml');
  my $xsl = $pseudotron->dump_xsl; # returns the internal XSLT stylesheet.


=head1 DESCRIPTION

XML::Schematron::LibXSLT serves as a simple validator for XML based on Rick JELLIFFE's Schematron XSLT script. A Schematron
schema defines a set of rules in the XPath language that are used to examine the contents of an XML document tree.

A simplified example: 
 <?xml version="1.0" ?>
 <schema>
  <pattern>
   <rule context="page">
    <assert test="count(*)=count(title|body)">The page element may only contain title or body elements.</assert> 
    <assert test="@name">A page element must contain a name attribute.</assert> 
    <report test="string-length(@name) &lt; 5">A page element name attribute must be at least 5 characters long.</report> 
   </rule>
  </pattern>
 </schema>

Note that an 'assert' rule will return if the result of the test expression is I<not> true, while a 'report' rule will return
only if the test expression evalutes to true.

=head1 METHODS

=over 4

=item * schema

The filename of the schema to use for generating tests.

=item * tests

The tests argument is an B<alternative> to the use of a schema as a means for defining the test stack. It should be a 
reference to a list of lists where the format of the sub-lists must conform to the following order:

  [$xpath_exp, $context, $message, $test_type, $pattern]
      
=back

=item schema()

When called with a single scalar as its argument, this method sets/updates the schema file to be used for generatng
tests. Otherwise, it simply returns the name of the schema file (if any).

The add_test() method allows you push additional a additional test on to the stack before validation. This method's argument must be an XML::Schematron::Test object or a hash reference with the following structure:

Arguments for this method:

=over 4

=item * expression (required)

The XPath expression to evaluate.

=item * context (required)

An element name or XPath location to use as the context of the test expression.

=item * test_type (required)

The B<test_type> argument must be set to either 'assert' or 'report'. Assert tests will return the associated message
only if the the corresponding test expression is B<not> true, while 'report' tests will return only if their associated test
expression B<are> true.  

=item * message (required)

The text message to display when the test condition is met.

=item * pattern (optional)

Optional descriptive text for the returned message that allows a logical grouping of tests.  


Example:


  $obj->add_test({expr => 'count(@*) > 0',
                 context => '/pattern',       
                 message => 'Pattern should have at least one attribute',
                 type => 'assert',
                 pattern => 'Basic tests'});

Note that add_test() pushes a new test on to the existing test list, while tests() redefines the entire list.

=back

=item add_tests( @tests );

The add_tests() method allows you push an additional list of tests on to the stack before validation. Each element must be an XML::Schematron::Test object or a hash reference. See above for the list of key/value pairs expected if hashrefs are used.

=back

=item verify('my_xml_file.xml' or $some_xml_string)

The verify() method takes the path to the XML document that you wish to validate, or a scalar containing the entire document  
as a string, as its sole argument. It returns the messages  that are returned during validation. When called in an array
context, this method returns an array of the messages generated during validation. When called in a scalar context, this
method returns a concatenated string of all output.

=item dump_xsl;

The dump_xsl method will return the internal XSLT script created from your schema.

=back

=head1 CONFORMANCE

Internally, XML::Schematron::LibXSLT uses the Gnome Project's XSLT proccessor via XML::LibXSLT, the best XSLT libraray available to the Perl World at
the moment.

For those platforms on which libxslt is not available, please see the documentation for L<XML::Schematron::XPath> (also in this distribution) for alternatives. 

=head1 AUTHOR

Kip Hampton, khampton@totalcinema.com

=head1 COPYRIGHT

Copyright (c) 2000-2010 Kip Hampton. All rights reserved. This program is free software; you can redistribute it and/or modify it  
under the same terms as Perl itself.

=head1 SEE ALSO

For information about Schematron, sample schemas, and tutorials to help you write your own schmemas, please visit the
Schematron homepage at: http://www.ascc.net/xml/resource/schematron/

For information about how to install libxslt and the necessary XML::LibXSLT Perl module, please see http://xmlsoft.org/XSLT/
and CPAN, repectively. 

For detailed information about the XPath syntax, please see the W3C XPath Specification at: http://www.w3.org/TR/xpath.html 

=cut
