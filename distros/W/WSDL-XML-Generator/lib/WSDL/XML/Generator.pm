package WSDL::XML::Generator;

use 5.006;
use strict;
use warnings;

=head1 NAME

WSDL::XML::Generator - The way WSDL::XML::Generator is creating a lots of xml with WSDL file by wsdl name and type name.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

1. Just find out Type in WSDL file, write test xml sample, it may be modified to your enviroment, because the generated xml file not related message/portType/service, in here, i supposed the portType type and message are having the same name.

2. Secondly, the WSDL file always has xsd schema file that defined all data types, you need fill the xml content by the those types.  

    use WSDL::XML::Generator qw( write list_data_node );
    write('t/test.wsdl'); 
    list_data_node('t/test.wsdl');

=head1 EXPORT

 write list_data_node

=head1 SUBROUTINES/METHODS

=head2 
 
 write()

 list_data_node()

=cut

use Carp;
use Exporter;
use File::Slurp qw(read_file write_file);
use XML::Simple qw(XMLin);
our @ISA    = qw( Exporter );
our @EXPORT = qw( write list_data_node );

sub write {
    my $wsdl_file = shift;
    my $element_name;
    my ($file_name_prex) = $wsdl_file =~ /(\w+)\.wsdl/;
    my @lines = read_file($wsdl_file);
    foreach (@lines) {
        if ( /<types>/ .. /<\/types>/ ) {
            if ( /<xsd:element name="(\w+)">/ .. /<\/xsd:element>/ ) {
                $element_name =
                  /<xsd:element name="(\w+)">/ ? $1 : $element_name;
                my $output_xml = $file_name_prex . '_' . $element_name . '.xml';
                if ( /<xsd:sequence>/ .. /<\/xsd:sequence>/ ) {
                    if (/<xsd:element name="(\w+)" type="(.*)" \/>/) {
                        my $name = $1;
                        write_file( $output_xml, { append => 1 },
                            "<$name>$name<\/$name>" );
                    }
                }
            }
        }
    }
    return 1;
}

sub list_data_node {
    my $wsdl_file = shift;
    my $hash = XMLin($wsdl_file,ForceArray=>1,KeyAttr=>['xsd:element']);
    use Data::Dumper qw(Dumper);
    $Data::Dumper::Indent =3;
    $Data::Dumper::Pair = " : ";
    warn Dumper($hash);

}

=head1 AUTHOR

Linus, C<< <yuan_shijiang at 163.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-wsdl-xml-generator at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WSDL-XML-Generator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WSDL::XML::Generator


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WSDL-XML-Generator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WSDL-XML-Generator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WSDL-XML-Generator>

=item * Search CPAN

L<http://search.cpan.org/dist/WSDL-XML-Generator/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Linus.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of WSDL::XML::Generator
