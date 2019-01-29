package WWW::Google::Places::SearchResult;

$WWW::Google::Places::SearchResult::VERSION   = '0.35';
$WWW::Google::Places::SearchResult::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

WWW::Google::Places::SearchResult - Placeholder for Search Result for WWW::Google::Places.

=head1 VERSION

Version 0.35

=cut

use 5.006;
use Data::Dumper;
use WWW::Google::Places::Geometry;

use Moo;
use namespace::clean;

use overload q{""} => 'as_string', fallback => 1;

has 'place_id' => (is => 'ro');
has 'name'     => (is => 'ro');
has 'types'    => (is => 'ro');
has 'geometry' => (is => 'ro');
has 'icon'     => (is => 'ro', default => sub { 'N/A'    });
has 'vicinity' => (is => 'ro', default => sub { 'N/A'    });
has 'scope'    => (is => 'ro', default => sub { 'GOOGLE' });

sub BUILDARGS {
    my ($class, $args) = @_;

    if (exists $args->{geometry}) {
        $args->{geometry} = WWW::Google::Places::Geometry->new($args->{geometry});
    }

    return $args;
}

=head1 METHODS

=head2 place_id()

Returns the place id.

=head2 name()

Returns place name.

=head2 types()

Returns ref to a list of place types.

=head2 geometry()

Returns an object of type L<WWW::Google::Places::Geometry>.

=head2 icon()

Returns URL of the link to the place icon.

=head2 vicinity()

Returns the vicinity of place.

=head2 scope()

Returns the place search scope.

=cut

sub as_string {
    my ($self) = @_;

    my $search_result = '';
    $search_result .= sprintf("Id      : %s\n", $self->place_id);
    $search_result .= sprintf("Name    : %s\n", $self->name);
    $search_result .= sprintf("Types   : %s\n", join(", ", @{$self->types}));
    $search_result .= sprintf("Geometry: %s\n", $self->geometry);
    $search_result .= sprintf("Icon    : %s\n", $self->icon);
    $search_result .= sprintf("Vicinity: %s\n", $self->vicinity);
    $search_result .= sprintf("Scope   : %s", $self->scope);

    return $search_result;
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

    perldoc WWW::Google::Places::SearchResult

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

1; # End of WWW::Google::Places::SearchResult
