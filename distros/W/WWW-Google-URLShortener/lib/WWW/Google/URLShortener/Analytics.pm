package WWW::Google::URLShortener::Analytics;

$WWW::Google::URLShortener::Analytics::VERSION   = '0.23';
$WWW::Google::URLShortener::Analytics::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

WWW::Google::URLShortener::Analytics - Placeholder for the analytics of short URL.

=head1 VERSION

Version 0.23

=cut

use 5.006;
use Moo;
use namespace::clean;

has id      => (is => 'ro');
has longUrl => (is => 'ro');
has kind    => (is => 'ro');
has result  => (is => 'ro');

=head1 SYNOPSIS

    use strict; use warnings;
    use WWW::Google::URLShortener;

    my $api_key   = 'Your API Key';
    my $short_url = 'Your Short URL';
    my $google    = WWW::Google::URLShortener->new( 'api_key' => $api_key );
    my $analytics = $google->get_analytics($short_url);

    print "Id: ", $analytics->id, "\n";
    print "Long URL: ", $analytics->longUrl, "\n";
    print "Kind: ", $analytics->kind, "\n";
    foreach my $result (@{$analytics->result}) {
        print "Type: ", $result->type, "\n";
        print "Short URL Clicks: ", $result->shortUrlClicks, "\n";
        print "Long URL Clicks: ", $result->longUrlClicks, "\n";
        print "Countries:\n";
        foreach my $country (@{$result->countries}) {
            print $country->as_string, "\n";
        }
        print "Browsers:\n";
        foreach my $browser (@{$result->browsers}) {
            print $browser->as_string, "\n";
        }
        print "Platforms:\n";
        foreach my $platform (@{$result->platforms}) {
            print $platform->as_string, "\n";
        }
        print "Referrers:\n";
        foreach my $referrer (@{$result->referrers}) {
            print $referrer->as_string, "\n";
        }
    }

=head1 METHODS

=head2 id()

Returns the id of the analytics.

=head2 longUrl()

Returns the long URL of the analytics.

=head2 kind()

Returns the kind of the analytics.

=head2 result()

Returns tle reference to the list of result L<WWW::Google::URLShortener::Analytics::Result> of the analytics.

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/WWW-Google-URLShortener>

=head1 BUGS

Please  report  any bugs  or feature requests to C<bug-www-google-urlshortener at
rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Google-URLShortener>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Google::URLShortener::Analytics

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Google-URLShortener>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Google-URLShortener>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Google-URLShortener>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Google-URLShortener/>

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

1; # End of WWW::Google::URLShortener::Analytics
