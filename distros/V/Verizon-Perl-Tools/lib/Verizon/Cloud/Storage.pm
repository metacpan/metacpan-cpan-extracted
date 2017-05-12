package Verizon::Cloud::Storage;

use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(get_buckets); 
our @EXPORT = qw();

=head1 NAME

Verizon::Cloud::Storage - Perl Interface to the Verizon Cloud Storage Platform.

=head1 VERSION

Version 0.01.04

=cut

our $VERSION = '0.01.04';


=head1 SYNOPSIS

Perl Inteface to the Verizon Cloud Storage Platform.  Sample usage:

    use Verizon::Cloud::Storage;
    ...

=head1 SUBROUTINES/METHODS

=head2 get_buckets

Placeholder function for now

=cut

sub get_buckets {
    return 1;
}


=head1 AUTHOR

Jason Goth, C<< <jason at gothtx.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-verizon-perl-tools at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Verizon-Perl-Tools>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Verizon::Cloud::Storage


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Verizon-Perl-Tools>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Verizon-Perl-Tools>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Verizon-Perl-Tools>

=item * Search CPAN

L<http://search.cpan.org/dist/Verizon-Perl-Tools/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Jason Goth.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.


=cut

1; # End of Verizon::Cloud::Storage
