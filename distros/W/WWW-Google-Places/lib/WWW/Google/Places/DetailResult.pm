package WWW::Google::Places::DetailResult;

$WWW::Google::Places::DetailResult::VERSION   = '0.35';
$WWW::Google::Places::DetailResult::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

WWW::Google::Places::DetailResult - Placeholder for detail Search Result for WWW::Google::Places.

=head1 VERSION

Version 0.35

=cut

use 5.006;
use Data::Dumper;
use WWW::Google::Places::Photo;
use WWW::Google::Places::Review;
use WWW::Google::Places::Address;
use WWW::Google::Places::Geometry;

use Moo;
use namespace::clean;

use overload q{""} => 'as_string', fallback => 1;

has 'place_id'               => (is => 'ro', required => 1            );
has 'website'                => (is => 'ro', default  => sub { 'N/A' });
has 'formatted_phone_number' => (is => 'ro', default  => sub { 'N/A' });
has 'opening_hours'          => (is => 'ro', default  => sub { 'N/A' });
has 'internation_number'     => (is => 'ro', default  => sub { 'N/A' });
has 'photos'                 => (is => 'ro', default  => sub { 'N/A' });
has 'utf_offset'             => (is => 'ro', default  => sub { 'N/A' });
has 'rating'                 => (is => 'ro', default  => sub { 'N/A' });
has 'user_ratings_total'     => (is => 'ro', default  => sub { 'N/A' });
has 'reviews'                => (is => 'ro');
has 'vicinity'               => (is => 'ro');
has 'adr_address'            => (is => 'ro');
has 'reference'              => (is => 'ro');
has 'geometry'               => (is => 'ro');
has 'scope'                  => (is => 'ro');
has 'icon'                   => (is => 'ro');
has 'name'                   => (is => 'ro');
has 'types'                  => (is => 'ro');
has 'formatted_address'      => (is => 'ro');
has 'url'                    => (is => 'ro');
has 'address_components'     => (is => 'ro');

sub BUILDARGS {
    my ($class, $args) = @_;

    my $reviews = [];
    if (exists $args->{reviews}) {
        foreach (@{$args->{reviews}}) {
            push @$reviews, WWW::Google::Places::Review->new($_);
        }
    }
    else {
        push @$reviews, WWW::Google::Places::Review->new;
    }

    $args->{reviews} = $reviews;

    if (exists $args->{geometry}) {
        $args->{geometry} = WWW::Google::Places::Geometry->new($args->{geometry});
    }

    if (exists $args->{photos}) {
        my $photos = [];
        foreach (@{$args->{photos}}) {
            push @$photos, WWW::Google::Places::Photo->new($_);
        }

        $args->{photos} = $photos;
    }

    if (exists $args->{address_components}) {
        my $address_components = [];
        foreach (@{$args->{address_components}}) {
            push @$address_components, WWW::Google::Places::Address->new($_);
        }

        $args->{address_components} = $address_components;
    }

    return $args;
}

=head1 METHODS

=head2 name()

Returns place name.

=head2 types()

Returns ref to a list of place types as defined in the pod document of L<WWW::Google::Places>.

=head2 url()

Returns place URL.

=head2 place_id()

Returns place id.

=head2 vicinity()

=head2 website()

Returns place website.

=head2 formatted_phone_number()

Returns place formatted phone number.

=head2 adr_address()

=head2 reference()

Returns place reference.

=head2 utf_offset()

=head2 geometry()

Returns an object of type L<WWW::Google::Places::Geometry>.

=head2 scope()

Returns place search scope.

=head2 icon()

Returns link to the place icon.

=head2 reviews()

Returns ref to a list of objects of type L<WWW::Google::Places::Review>.

=head2 rating()

Returns place rating.

=head2 user_ratings_total()

Retuns place total user ratings.

=head2 formatted_address()

Returns place address.

=head2 address_components()

Returns ref to a list of objects of type L<WWW::Google::Places::Address>.

=head2 opening_hours()

Returns place opening hours.

=head2 internation_number()

Returns place internation number.

=head2 photos()

Returns ref to a list of objects of type L<WWW::Google::Places::Photo>.

=cut

sub as_string {
    my ($self) = @_;

    my $detail_result = '';
    $detail_result .= sprintf("Place ID          : %s\n", $self->place_id);
    $detail_result .= sprintf("Name              : %s\n", $self->name);
    $detail_result .= sprintf("Website           : %s\n", $self->website);
    $detail_result .= sprintf("URL               : %s\n", $self->url);
    $detail_result .= sprintf("Phone Number      : %s\n", $self->formatted_phone_number);
    $detail_result .= sprintf("Opening Hours     : %s\n", $self->opening_hours);
    $detail_result .= sprintf("Internation Number: %s\n", $self->internation_number);
    $detail_result .= sprintf("UTF Offset        : %s\n", $self->utf_offset);
    $detail_result .= sprintf("Rating            : %s\n", $self->rating);
    $detail_result .= sprintf("User Ratings      : %s\n", $self->user_ratings_total);
    $detail_result .= sprintf("Vicinity          : %s\n", $self->vicinity);
    $detail_result .= sprintf("Address           : %s\n", $self->adr_address);
    $detail_result .= sprintf("Reference         : %s\n", $self->reference);
    $detail_result .= sprintf("Geometry          : %s\n", $self->geometry);
    $detail_result .= sprintf("Scope             : %s\n", $self->scope);
    $detail_result .= sprintf("Icon              : %s\n", $self->icon);
    $detail_result .= sprintf("Types             : %s\n", join(", ", @{$self->types}));
    $detail_result .= sprintf("Address           : %s\n", $self->formatted_address);

    if (@{$self->address_components}) {
        $detail_result .= sprintf("Address Components:\n");
        foreach (@{$self->address_components}) {
            $detail_result .= sprintf("\tShort Name: %s\n", $_->short_name);
            $detail_result .= sprintf("\tLong Name : %s\n", $_->long_name);
            $detail_result .= sprintf("\tTypes     : %s\n", join(", ", @{$_->types}));
            $detail_result .= sprintf("\t-----------\n");
        }
    }

    if (@{$self->reviews}) {
        $detail_result .= sprintf("Reviews           :\n");
        foreach (@{$self->reviews})  {
            $detail_result .= sprintf("\tAuthor Name: %s\n", $_->author_name);
            $detail_result .= sprintf("\tAuthor URL : %s\n", $_->author_url);
            $detail_result .= sprintf("\tLanguage   : %s\n", $_->language);
            $detail_result .= sprintf("\tRating     : %s\n", $_->rating);
            $detail_result .= sprintf("\tText       : %s\n", $_->text);
            $detail_result .= sprintf("\tTime       : %s\n", $_->time);
            $detail_result .= sprintf("\tAspects    : %s\n", $_->aspects||'N/A');
            $detail_result .= sprintf("\t-----------\n");
        }
    }
    if (@{$self->photos}) {
        $detail_result .= sprintf("Photos            : \n");
        foreach (@{$self->photos}) {
            $detail_result .= sprintf("\tWidth             :%s\n", $_->width);
            $detail_result .= sprintf("\tHeight            :%s\n", $_->height);
            $detail_result .= sprintf("\tReference         :%s\n", $_->photo_reference);
            $detail_result .= sprintf("\tHTML Attributions :%s\n", join("<BR", @{$_->html_attributions}));
            $detail_result .= sprintf("\t-------------------\n");
        }
    }

    return $detail_result;
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/WWW-Google-Places>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-google-places at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Google-Places>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Google::Places::DetailResult

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Google-Places>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Google-Places>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Google-Places>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Google-Places/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 - 2016 Mohammad S Anwar.

This  program is  free software; you can redistribute it and / or modify it under
the  terms   of the the Artistic License (2.0). You may obtain a copy of the full
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

1; # End of WWW::Google::Places::DetailResult
