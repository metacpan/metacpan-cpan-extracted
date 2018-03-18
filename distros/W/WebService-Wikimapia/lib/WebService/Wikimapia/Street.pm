package WebService::Wikimapia::Street;

$WebService::Wikimapia::Street::VERSION   = '0.13';
$WebService::Wikimapia::Street::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

WebService::Wikimapia::Street - Placeholder for 'street' of L<WebService::Wikimapia>.

=head1 VERSION

Version 0.13

=cut

use 5.006;
use Data::Dumper;
use WebService::Wikimapia::City;
use WebService::Wikimapia::Hotel;
use WebService::Wikimapia::Photo;
use WebService::Wikimapia::Place;
use WebService::Wikimapia::User;
use WebService::Wikimapia::Comment;
use WebService::Wikimapia::Location;
use WebService::Wikimapia::Language;

use Moo;
use namespace::clean;

has 'id'                 => (is => 'ro');
has 'title'              => (is => 'ro');
has 'photos'             => (is => 'ro');
has 'language_id'        => (is => 'ro');
has 'language_iso'       => (is => 'ro');
has 'urlhtml'            => (is => 'ro');
has 'object_type'        => (is => 'ro');
has 'location'           => (is => 'ro');
has 'comments'           => (is => 'ro');
has 'lastEditors'        => (is => 'ro');
has 'related'            => (is => 'ro');
has 'nearestPlaces'      => (is => 'ro');
has 'nearestComments'    => (is => 'ro');
has 'nearestHotels'      => (is => 'ro');
has 'nearestCities'      => (is => 'ro');
has 'nearestStreets'     => (is => 'ro');
has 'availableLanguages' => (is => 'ro');

sub BUILDARGS {
    my ($class, $args) = @_;

    if (exists $args->{'location'}) {
        $args->{'location'} = WebService::Wikimapia::Location->new($args->{'location'});
    }

    if (exists $args->{'comments'}) {
        my $comments = [];
        foreach my $comment (@{$args->{'comments'}}) {
            push @$comments, WebService::Wikimapia::Comment->new($comment);
        }
        $args->{'comments'} = $comments;
    }

    if (exists $args->{'lastEditors'}) {
        my $editors = [];
        foreach my $id (keys %{$args->{'lastEditors'}}) {
            push @$editors, WebService::Wikimapia::User->new($args->{'lastEditors'}->{$id});
        }
        $args->{'lastEditors'} = $editors;
    }

    if (exists $args->{'related'}) {
        my $places = [];
        foreach my $id (keys %{$args->{'related'}}) {
            push @$places, WebService::Wikimapia::Place->new($args->{'related'}->{$id});
        }
        $args->{'related'} = $places;
    }

    if (exists $args->{'nearestPlaces'}) {
        my $places = [];
        foreach my $id (keys %{$args->{'nearestPlaces'}}) {
            push @$places, WebService::Wikimapia::Place->new($args->{'nearestPlaces'}->{$id});
        }
        $args->{'nearestPlaces'} = $places;
    }

    if (exists $args->{'nearestComments'}) {
        my $comments = [];
        foreach my $comment (@{$args->{'nearestComments'}}) {
            push @$comments, WebService::Wikimapia::Comment->new($comment);
        }
        $args->{'nearestComments'} = $comments;
    }

    if (exists $args->{'nearestHotels'}) {
        my $hotels = [];
        foreach my $id (keys %{$args->{'nearestHotels'}}) {
            push @$hotels, WebService::Wikimapia::Hotel->new($args->{'nearestHotels'}->{$id});
        }
        $args->{'nearestHotels'} = $hotels;
    }

    if (exists $args->{'nearestCities'}) {
        my $cities = [];
        foreach my $id (keys %{$args->{'nearestCities'}}) {
            push @$cities, WebService::Wikimapia::City->new($args->{'nearestCities'}->{$id});
        }
        $args->{'nearestCities'} = $cities;
    }

    if (exists $args->{'nearestStreets'}) {
        my $cities = [];
        foreach my $id (keys %{$args->{'nearestStreets'}}) {
            push @$cities, WebService::Wikimapia::City->new($args->{'nearestStreets'}->{$id});
        }
        $args->{'nearestStreets'} = $cities;
    }

    if (exists $args->{'availableLanguages'}) {
        my $languages = [];
        foreach my $id (keys %{$args->{'availableLanguages'}}) {
            push @$languages, WebService::Wikimapia::Language->new($args->{'availableLanguages'}->{$id});
        }
        $args->{'availableLanguages'} = $languages;
    }

    if (exists $args->{'photos'}) {
        my $photos = [];
        foreach my $photo (@{$args->{'photos'}}) {
            push @$photos, WebService::Wikimapia::Photo->new($photo);
        }
        $args->{'photos'} = $photos;
    }

    return $args;
}

=head1 METHODS

=head2 id()

Returns the id of the street.

=head2 title()

Returns the title of the street.

=head2 photos()

Returns the reference to the list of objects of type L<WebService::Wikimapia::Photo>.

=head2 language_id()

Returns the language id.

=head2 language_iso()

Returns the language iso.

=head2 urlhtml()

Returns the URL.

=head2 object_type()

Returns the object type.

=head2 location()

Returns an object of type L<WebService::Wikimapia::Location>.

=head2 comments()

Returns the reference to the list of comments.

=head2 lastEditors()

=head2 related()

=head2 nearestPlaces()

Returns the reference to the list of objects of type L<WebService::Wikimapia::Place>.

=head2 nearestComments()

Returns the reference to the list of objects of type L<WebService::Wikimapia::Comment>.

=head2 nearestHotels()

Returns the reference to the list of objects of type L<WebService::Wikimapia::Hotel>.

=head2 nearestCities()

Returns the reference to the list of objects of type L<WebService::Wikimapia::City>.

=head2 nearestStreets()

Returns the reference to the list of objects of type L<WebService::Wikimapia::City>.

=head2 availableLanguages()

Returns the reference to the list of objects of type L<WebService::Wikimapia::Language>.

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

    perldoc WebService::Wikimapia::Street

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

1; # End of WebService::Wikimapia::Street
