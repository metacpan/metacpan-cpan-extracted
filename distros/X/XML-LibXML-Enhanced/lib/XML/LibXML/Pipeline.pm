use strict;
use warnings;

package XML::LibXML::Pipeline;

=head1 NAME

XML::LibXML::Pipeline - a pipe of XML::LibXSLT objects
  
=head1 SYNOPSIS

  my $p = XML::LibXML::Pipeline->new(
    parse_xslt_file("$XSLDIR/detail.xsl"),
    Paris::Transformer::Photo->new("$CACHEDIR"),
    parse_xslt_file("$XSLDIR/page.xsl"),
  );
  
  $res = $p->transform(parse_xml_file("input.xml"));
  
  $p->output_file($res, "output.xml");

=head1 DESCRIPTION

This enables easy chaining of multiple XML transformer objects.  The
objects in the pipeline do not have to be XML::LibXSLT objects; they
just need to implement the transform() method.  (This method must
take, and return, and XML::LibXML::Document.) In addition, the I<last>
transformer in the pipeline must support the methods
C<output_string($doc)> and C<output_file($doc, $filename)> if you wish
to use these methods.
  
=head1 METHODS

=over 4

=item my $p = XML::LibXML::Pipeline->new($obj1 [, $obj2]...)

Constructor.
  
=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = {
	PIPELINE => [ @_ ]
    };

    bless $self, $class;
}

=item $res = $p->transform($doc [, %args ])

Transforms C<$doc>; that is, each of the objects in the pipeline are
called with parameters (C<$doc>, C<%args>).

All objects are called with the same arguments; there is no way to
selectively pass arguments to the transformers.  (If you need to do
this, assemble the pipeline by hand.)

=cut

sub transform {
    my ($self, $doc, %args) = @_;

    my $tmp = $doc;

    foreach (@{$self->{PIPELINE}}) {
	$tmp = $_->transform($tmp, %args);
    }

    return $tmp;
}

=item $s = $p->output_string($doc)

This runs the C<output_string()> method of the I<last> object in the
pipeline on C<$doc>, returning a string.

Note that C<$doc> itself has C<toString()> and C<toFile()> methods; as
L<XML::LibXSLT> explains, however, "I<always> output the document in
XML format, and in UTF8, which may not be what you asked for in the
xsl:output tag."

=cut

sub output_string {
    my ($self, @args) = @_;
    
    return $self->{PIPELINE}[-1]->output_string(@args);
}

=item $p->output_file($doc, $filename)

This runs the C<output_file()> method of the I<last> object in the
pipeline on C<$doc>.

See also L<output_string()>.

=cut

sub output_file {
    my ($self, @args) = @_;
    
    return $self->{PIPELINE}[-1]->output_file(@args);
}

=back

=head1 AUTHOR

Michael Stillwell <mjs@beebo.org>

=cut

1;
