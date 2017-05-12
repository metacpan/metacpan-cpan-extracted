package WebService::Wikimapia::Location;

$WebService::Wikimapia::Location::VERSION   = '0.12';
$WebService::Wikimapia::Location::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

WebService::Wikimapia::Location - Placeholder for 'location' of L<WebService::Wikimapia::Response>.

=head1 VERSION

Version 0.12

=cut

use 5.006;
use Data::Dumper;
use WebService::Wikimapia::GlobalAdmin;

use Moo;
use namespace::clean;

has 'east'           => (is => 'ro');
has 'west'           => (is => 'ro');
has 'north'          => (is => 'ro');
has 'south'          => (is => 'ro');
has 'place'          => (is => 'ro');
has 'city'           => (is => 'ro');
has 'city_id'        => (is => 'ro');
has 'state'          => (is => 'ro');
has 'country'        => (is => 'ro');
has 'country_adm_id' => (is => 'ro');
has 'lat'            => (is => 'ro');
has 'lon'            => (is => 'ro');
has 'zoom'           => (is => 'ro');
has 'gadm'           => (is => 'ro');

sub BUILDARGS {
    my ($class, $args) = @_;

    if (exists $args->{'gadm'}) {
        my $gadms = [];
        foreach my $gadm (@{$args->{'gadm'}}) {
            push @$gadms, WebService::Wikimapia::GlobalAdmin->new($gadm);
        }
        $args->{'gadm'} = $gadms;
    }

    return $args;
}

=head1 METHODS

=head2 east()

=head2 west()

=head2 north()

=head2 south()

=head2 place()

=head2 city()

=head2 city_id()

=head2 state()

=head2 country()

=head2 country_adm_id()

=head2 lat()

=head2 lon()

=head2 zoom()

=head2 gadm()

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

    perldoc WebService::Wikimapia::Location

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

1; # End of WebService::Wikimapia::Location
