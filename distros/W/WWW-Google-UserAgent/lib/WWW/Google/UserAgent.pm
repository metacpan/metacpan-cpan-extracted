package WWW::Google::UserAgent;

$WWW::Google::UserAgent::VERSION   = '0.21';
$WWW::Google::UserAgent::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

WWW::Google::UserAgent - Low-level HTTP request handler for Google API.

=head1 VERSION

Version 0.21

=cut

use 5.006;
use Data::Dumper;

use HTTP::Tiny;
use WWW::Google::UserAgent::Exception;

use Moo;
use namespace::clean;

has 'api_key' => ( is => 'ro', required => 1 );
has 'ua'      => ( is => 'rw', default => sub { HTTP::Tiny->new(agent => "WWW-Google/0.01"); } );

=head1 DESCRIPTION

It provides common useragent library for Google API services.

=head1 METHODS

=head2 get($url)

It  expects  one parameter i.e.  URL  and returns the standard response. On error
throws exception of type L<WWW::Google::UserAgent::Exception>.

=cut

sub get {
    my ($self, $url) = @_;

    my $ua       = $self->ua;
    my $response = $ua->request('GET', $url);
    my @caller   = caller(1);
    @caller = caller(2) if $caller[3] eq '(eval)';

    unless ($response->{success}) {
	WWW::Google::UserAgent::Exception->throw({
            method      => $caller[3],
            code        => $response->{status},
            message     => $response->{reason},
            filename    => $caller[1],
            line_number => $caller[2] });
    }

    return $response;
}

=head2 post($url, \%headers, $content)

It expects  three  parameters i.e. URL, Headers and Content in the same order and
returns the standard response. The c<$content> should be JSON formatted. On error
throws exception of type L<WWW::Google::UserAgent::Exception>.

=cut

sub post {
    my ($self, $url, $headers, $content) = @_;

    my $ua       = $self->ua;
    my $response = $ua->request('POST', $url, { headers => $headers, content => $content });
    my @caller   = caller(1);
    @caller = caller(2) if $caller[3] eq '(eval)';

    unless ($response->{success}) {
        WWW::Google::UserAgent::Exception->throw({
            method      => $caller[3],
            code        => $response->{status},
            message     => $response->{reason},
            filename    => $caller[1],
            line_number => $caller[2] });
    }

    return $response;
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/WWW-Google-UserAgent>

=head1 SEE ALSO

=over 4

=item * L<WWW::Google::CustomSearch>

=item * L<WWW::Google::Places>

=item * L<WWW::Google::APIDiscovery>

=item * L<WWW::Google::DistanceMatrix>

=item * L<WWW::Google::URLShortener>

=item * L<WWW::Google::PageSpeedOnline>

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-google-useragent at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Google-UserAgent>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Google::UserAgent

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Google-UserAgent>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Google-UserAgent>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Google-UserAgent>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Google-UserAgent/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 - 2015 Mohammad S Anwar.

This  program  is  free software;  you can redistribute it and/or modify it under
the  terms  of the the Artistic  License (2.0). You may obtain a copy of the full
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

1; # End of WWW::Google::UserAgent
