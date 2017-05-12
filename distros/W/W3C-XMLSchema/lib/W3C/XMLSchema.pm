use strict;
use warnings;

package W3C::XMLSchema;
{
  $W3C::XMLSchema::VERSION = '0.0.4';
}
use XML::Rabbit::Root 0.1.0;

# ABSTRACT: Parser for W3C XML Schema Definition (XSD)

use 5.008;

add_xpath_namespace 'xsd' => 'http://www.w3.org/2001/XMLSchema';


has_xpath_value 'target_namespace' => './@targetNamespace';


has_xpath_object_list 'attribute_groups' => './xsd:attributeGroup' => 'W3C::XMLSchema::AttributeGroup';


has_xpath_object_list 'groups' => './xsd:group' => 'W3C::XMLSchema::Group';


has_xpath_object_list 'complex_types' => './xsd:complexType' => 'W3C::XMLSchema::ComplexType';


has_xpath_object_list 'elements' => './xsd:element' => 'W3C::XMLSchema::Element';

finalize_class();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

W3C::XMLSchema - Parser for W3C XML Schema Definition (XSD)

=head1 VERSION

version 0.0.4

=head1 SYNOPSIS

    use W3C::XMLSchema;

    my $xsd = W3C::XMLSchema->new( file => shift );
    print "Target namespace: " . $xsd->target_namespace . "\n";

    print "Attribute groups:\n";
    foreach my $attr_group ( @{ $xsd->attribute_groups } ) {
        print $attr_group->name . "\n";
        foreach my $attr ( @{ $attr_group->attributes } ) {
            print "\t"
                 . $attr->name
                 . " (" . $attr->type . ") "
                 . ( $attr->use eq 'required' ? '*' : '-' )
                 . "\n";
        }
    }

=head1 DESCRIPTION

This is a module that makes it easy to iterate over and extract information
from an XML Schema definition (aka XSD), as defined by the W3C.

=head1 ATTRIBUTES

=head2 target_namespace

The namespace the schema definition targets.

=head2 attribute_groups

A list of all the attribute groups defined. Instances of L<W3C::XMLSchema::AttributeGroup>.

=head2 groups

A list of all the groups defined. Instances of L<W3C::XMLSchema::Group>.

=head2 complex_types

A list of all the complex types defined. Instances of L<W3C::XMLSchema::ComplexType>.

=head2 elements

A list of all the elements defined. Instances of L<W3C::XMLSchema::Element>.

=head1 INCOMPLETE IMPLEMENTATION / WORK-IN-PROGRESS

This implementation is incomplete and should be considered a
work-in-progress. Please file bug reports (or provide patches) if something
you need is not extractable with the current API.

=head1 SEMANTIC VERSIONING

This module uses semantic versioning concepts from L<http://semver.org/>.

=head1 ACKNOWLEDGEMENTS

The following people have helped to review or otherwise encourage
me to work on this module.

Chris Prather (perigrin)

=head1 SEE ALSO

=over 4

=item *

L<XML::Rabbit>

=item *

L<XML::Toolkit>

=item *

L<Moose>

=item *

L<XML::LibXML>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc W3C::XMLSchema

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/W3C-XMLSchema>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/W3C-XMLSchema>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=W3C-XMLSchema>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/W3C-XMLSchema>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/W3C-XMLSchema>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/W3C-XMLSchema>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/W3C-XMLSchema>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/W/W3C-XMLSchema>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=W3C-XMLSchema>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=W3C::XMLSchema>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-w3c-xmlschema at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=W3C-XMLSchema>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://github.com/robinsmidsrod/W3C-XMLSchema>

  git clone git://github.com/robinsmidsrod/W3C-XMLSchema.git

=head1 AUTHOR

Robin Smidsrød <robin@smidsrod.no>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Robin Smidsrød.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
