
package Verizon::Cloud::Ecloud;

use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(get_organizations); 
our @EXPORT = qw();

=head1 NAME

Verizon::Cloud::Ecloud - Perl interface to the Verizon Enterprise Cloud platform

=head1 VERSION

Version 0.01.04

=cut

our $VERSION = '0.01.04';

=head1 SYNOPSIS

Provides a simple perl interface to the Verizon Enterprise Cloud.  For details on the Verizon 
Enterprise Cloud, see http://support.theenterprisecloud.com.

=head1 SUBROUTINES/METHODS

=head2 get_organizations

Provides a list of organzations the user has access to. Returns a hash of environment ids and names.

    use Verizon::Cloud::Ecloud qw(get_organizations);

    my %orgs = get_organizations();

    # %org = ( '1234567' => 'Sample Organization' )

=cut

sub get_organizations {
    return ('1234567' => 'Sample Organization',);
}


=head1 AUTHOR

Jason Goth, C<< <jason at gothtx.com> >>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Verizon::Cloud::Ecloud

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Verizon-Cloud-Ecloud>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Verizon-Cloud-Ecloud>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Verizon-Cloud-Ecloud>

=item * Search CPAN

L<http://search.cpan.org/dist/Verizon-Cloud-Ecloud/>

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

1; # End of Verizon::Cloud::Ecloud
