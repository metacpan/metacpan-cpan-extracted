package XML::FromPerl;

our $VERSION = '0.01';

use 5.010;
use strict;
use warnings;

use XML::LibXML;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(xml_from_perl xml_node_from_perl);

sub xml_node_from_perl {
    my $doc = shift;
    my $data = shift;

    if (ref $data eq 'ARRAY') {
        my $e = $doc->createElement($data->[0]);
        my $one = $data->[1];
        my $has_attrs = ref $one eq 'HASH';
        if ($has_attrs) {
            my @keys = keys %$one;
            @keys = sort @keys unless tied %$one;
            for (@keys) {
                if (defined (my $v = $one->{$_})) {
                    $e->setAttribute($_, $v);
                }
            }
        }
        $e->appendChild(xml_node_from_perl($doc, $data->[$_]))
            for (($has_attrs ? 2 : 1) .. $#$data);

        return $e;
    }
    $doc->createTextNode("$data");
}

sub xml_from_perl {
    my $data = shift;
    my $doc = XML::LibXML::Document->new(@_);
    my $root = xml_node_from_perl($doc, $data);
    $doc->setDocumentElement($root);
    $doc
}

1;
__END__

=head1 NAME

XML::FromPerl - Generate XML from simple Perl data structures

=head1 SYNOPSIS

  use XML::FromPerl qw(xml_from_perl);

  my $doc = xml_from_perl
    [ Foo => { attr1 => val1, attr2 => val2},
      [ Bar => { attr3 => val3, ... },
      [ Bar => { ... },
      "Some Text here",
      [Doz => { ... },
        [ Bar => { ... }, [ ... ] ] ];

  $doc->toFile("foo.xml");

=head1 DESCRIPTION

This module is able to generate XML described using simple Perl data
structures.

XML nodes are declared as arrays where the first slot is the tag name,
the second is a HASH containing tag attributes and the rest are its
children. Perl scalars are used for text sections.

=head2 EXPORTABLE FUNCTIONS

=over 4

=item xml_from_perl $data

Converts the given perl data structure into a L<XML::LibXML::Document>
object.

=item xml_node_from_perl $doc, $data

Converts the given perl data structure into a L<XML::LibXML::Node>
object linked to the document passed.

=back

=head2 NOTES

=head3 Namespaces

I have not made my mind yet about how to handle XML namespaces other
than stating them explicitly in the names or setting the C<xmlns>
attribute.

=head3 Attribute order

If attribute order is important to you, declare then using
L<Tie::IxHash>:

For instance:

  use Tie::IxHash;
  sub attrs {
    my @attrs = @_;
    tie my(%attrs), 'Tie::Hash', @attrs;
    \%attrs
  }

  my $doc = xml_from_perl [ Foo => attrs(attr1 => val1, attrs2 => val2), ...];

Otherwise attributes are sorted in lexicographical order.

=head3 Memory usage

This module is not very memory efficient. At some point it is going to
keep in memory both the original perl data structure and the
XML::LibXML one.

Anyway, nowadays that shouldn't be a problem unless your data is
really huge.

=head1 SEE ALSO

L<XML::LibXML>, L<XML::LibXML::Document>, L<XML::LibXML::Node>.

Other modules for generating XML are L<XML::Writer> and
L<XML::Generator>. Check also L<XML::Compile>.

A related PerlMonks discussion:
L<http://www.perlmonks.org/?node_id=1195009>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Salvador FandiE<ntilde>o E<lt>sfandino@yahoo.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
