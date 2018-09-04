package WWW::Google::PageSpeedOnline::Result;

$WWW::Google::PageSpeedOnline::Result::VERSION   = '0.26';
$WWW::Google::PageSpeedOnline::Result::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

WWW::Google::PageSpeedOnline::Result - Placeholder for the result of L<WWW::Google::PageSpeedOnline>.

=head1 VERSION

Version 0.26

=cut

use 5.006;
use Moo;
use namespace::autoclean;

has [ qw(id title score rules) ] => (is => 'ro');

=head1 METHODS

=head2 id()

Returns the result rule id.

=head2 title()

Returns the result rule title.

=head2 score()

Returns the result rule score.

=head2 rules()

Returns the reference to the list of L<WWW::Google::PageSpeedOnline::Result::Rule>.

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/WWW-Google-PageSpeedOnline>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-google-pagespeedonline at
rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Google-PageSpeedOnline>.
I will be notified, and then you'll automatically be notified of progress on your
 bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Google::PageSpeedOnline::Result

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Google-PageSpeedOnline>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Google-PageSpeedOnline>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Google-PageSpeedOnline>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Google-PageSpeedOnline/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 - 2015 Mohammad S Anwar.

This  program  is  free software; you can redistribute it and/or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of WWW::Google::PageSpeedOnline::Result
