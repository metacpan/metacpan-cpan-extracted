package WebService::Wikimapia::Photo;

$WebService::Wikimapia::Photo::VERSION   = '0.13';
$WebService::Wikimapia::Photo::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

WebService::Wikimapia::Photo - Placeholder for 'photo' of L<WebService::Wikimapia>.

=head1 VERSION

Version 0.13

=cut

use 5.006;
use Data::Dumper;

use Moo;
use namespace::clean;

has 'id'                  => (is => 'ro');
has 'user_id'             => (is => 'ro');
has 'user_name'           => (is => 'ro');
has 'object_id'           => (is => 'ro');
has 'last_user_id'        => (is => 'ro');
has 'last_user_name'      => (is => 'ro');
has 'size'                => (is => 'ro');
has 'time'                => (is => 'ro');
has 'time_str'            => (is => 'ro');
has 'status'              => (is => 'ro');
has 'full_url'            => (is => 'ro');
has 'big_url'             => (is => 'ro');
has 'url_960'             => (is => 'ro');
has 'url_1280'            => (is => 'ro');
has 'thumbnail_url'       => (is => 'ro');
has 'thumbnaliRetina_url' => (is => 'ro');

=head1 METHODS

=head2 id()

=head2 user_id()

=head2 user_name()

=head2 object_id()

=head2 last_user_id()

=head2 last_user_name()

=head2 size()

=head2 time()

=head2 time_str()

=head2 status()

=head2 full_url()

=head2 big_url()

=head2 url_960 ()

=head2 url_1280()

=head2 thumnail_url()

=head2 thumbnailRetina_url()

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/Manwar/WebService-Wikimapia>

=head1 BUGS

Please  report  any  bugs  or feature  requests to C<bug-webservice-wikimapia  at
rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Wikimapia>.
I will be notified and then you'll automatically be notified of  progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Wikimapia::Photo

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Wikimapia>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Wikimapia>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Wikimapia>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-Wikimapia/>

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

1; # End of WebService::Wikimapia::Photo
