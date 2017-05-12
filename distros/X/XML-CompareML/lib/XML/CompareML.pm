package XML::CompareML;

use strict;
use warnings;

use 5.008;

use vars qw($VERSION);

$VERSION = '0.2.10';

1; # End of XML::CompareML

__END__

=head1 NAME

XML::CompareML - A processor for the CompareML markup language

=head1 VERSION

Version 0.2.9

=head1 SYNOPSIS

    use XML::CompareML::HTML;

    my $converter =
        XML::CompareML::HTML->new(
            'input_filename' => "my-comparison.xml",
            'output_handle' => \*STDOUT,
        );

    $converter->process();

Or alternatively:

    use XML::CompareML::DocBook;

    my $converter =
        XML::CompareML::DocBook->new(
            'input_filename' => "my-comparison.xml",
            'output_handle' => \*STDOUT,
        );

    $converter->process();

=head1 USAGE

The CompareML language is currently undocumented, but one can see
an example for a document written it in the
C<t/files/scm-comparison.xml> example in the distribution.

To convert a CompareML document to HTML instantiate an XML::CompareML::HTML
object, and pass it the filename as the C<input_filename> named parameter,
and a reference to the IO handle to output the result as the C<output_handle>
named parameter.

To convert a CompareML document to DocBook do the same procedure only using
an XML:CompareML::DocBook object.

=cut

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 BUGS

Please report any bugs or feature requests to
C<bug-xml-compareml@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML::CompareML>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Shlomi Fish, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as the MIT X11 license.

=cut

