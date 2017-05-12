package Test::XML::Deep;

use warnings;
use strict;

use base 'Test::Builder::Module';

use XML::Parser;
use XML::Simple;
use Test::Deep qw/deep_diag cmp_details/;

my $Builder = __PACKAGE__->builder;

our @EXPORT = qw/ cmp_xml_deeply /;

=head1 NAME

Test::XML::Deep = XML::Simple + Test::Deep

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';


=head1 SYNOPSIS

This module can be used to easily test that some XML has the structure and values you desire.

It is particularly useful when some values in your XML document may differ from one test run
to another (for example, a timestamp).

An Example:

    use Test::XML::Deep;

    my $xml = <<EOXML;
    <?xml version="1.0" encoding="UTF-8"?>
    <example>
        <sometag attribute="value">some data</sometag>
        <sometag attribute="other">more data</sometag>
    </example>
    EOXML

    my $expected = { sometag => [ { attribute => 'value',
                                    content   => 'some data'
                                 },
                               ]
                   };

    cmp_xml_deeply($xml, $expected);


The real power comes from using Test::Deep and making use of the functions it exports (I.E. array_each(), re()):

    use Test::Deep;

    my $expected = { sometag => array_each( { attribute => re('^\w+$'),
                                              content   => re('data$'),
                                             }
                                )
                   };

    cmp_xml_deeply($xml, $expected);

You can also pass in a filename:

    cmp_xml_deeply('somefile.xml', { my_expected => 'data_structure' });


=head1 EXPORT

cmp_xml_deeply 

=head1 FUNCTIONS

=head2 cmp_xml_deeply( $xml, $hashref_expected, [ 'test name' ] );

$xml is a filename or string of XML that you'd like to test.

$hashref_expected should be the expected value of the XML as it would be parsed by XML::Simple.

An optional test name is accepted as the third parameter.

=cut

sub cmp_xml_deeply {
    my ( $xml, $expected, $name ) = @_;

    my $parse_method = 'parse';

    # allow filenames to work
    if( ( ref $xml && ref $xml ne 'SCALAR' )
      || $xml !~ m{<.*?>}s ) {
        $parse_method = 'parsefile';
    }

    my $parser = new XML::Parser(Style => 'Tree');
    eval { $parser->$parse_method($xml); };

 
    my $not_ok = $@;

	if( $not_ok ){
        ( my $message = $not_ok ) =~ s/ at (?!line).*//g;   # ick!
        $message =~ s/^\n//g;
        #chomp $message;
        $Builder->ok(0, $name);
		$Builder->diag("Failed to parse \n$xml\nXML::Parser error was: $message\n");
	}else{
        my $test  = XMLin( $xml ); 
        my ($ok, $stack) = cmp_details($test, $expected);
        if( not $Builder->ok($ok, $name) ){
            my $diag = deep_diag($stack);
            $Builder->diag($diag);
        }
    }
}

=head1 ACKNOWLEDGEMENTS

Fergal Daly, for exporting cmp_details from Test::Deep lickety-split!

Michael G Schwern, for L<Test::Builder>, which makes modules like this possible.

=head1 SOURCE

see: L<http://github.com/jlavallee/test-xml-deep>

=head1 AUTHOR

Jeff Lavallee, C<< <jeff at zeroclue.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-xml-deep at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-XML-Deep>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::XML::Deep


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-XML-Deep>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-XML-Deep>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-XML-Deep>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-XML-Deep>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2009 Jeff Lavallee, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::XML::Simple>, L<Test::Deep>


=cut

1; # End of Test::XML::Deep

