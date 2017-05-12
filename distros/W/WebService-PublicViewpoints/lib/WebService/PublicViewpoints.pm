package WebService::PublicViewpoints;
use strict;
our $VERSION = '0.01';

package WebService::PublicViewpoints::Point;
use Object::Tiny qw{url country_code country state city lat lng};

package WebService::PublicViewpoints;
use URI;
use constant APP_URI => URI->new("http://public-viewpoints.appspot.com/get_viewpoint");

use LWP::Simple;
use Text::CSV::Slurp;

sub find {
    shift;
    my $uri = APP_URI->clone;
    $uri->query_form({@_, format => "csv"});
    return map { WebService::PublicViewpoints::Point->new(%$_) } @{ Text::CSV::Slurp->load(string => "url,country_code,country,state,city,lat,lng,,\n" . get($uri)) }
}

1;

__END__

=head1 NAME

WebService::PublicViewpoints - The Perl API to access the public-viewpoints geo-webservice.

=head1 SYNOPSIS

  use WebService::PublicViewpoints;

  my @points = WebService::PublicViewpoints->find(num => 10, country => "JP");

  for (@points) {
      say $->lat, $_->lng, $_->url;
  }

=head1 DESCRIPTION

WebService::PublicViewpoints is a Perl API to access the
public-viewpoints geo-webservice available at
L<http://public-viewpoints.appspot.com>. Each viewpoint is basically
a camera shoting at something.

To use it, invoke its `find` class method with constraints:

    my @points = WebService::PublicViewpoints->find(num => 10, country => "JP");

The possibile constraint key-values are:

=over 4

=item

num: At least 1, the maximum number of results.

=item

random: "true" or "false".

=item

latitude, longitude: The viewpoints around this location are wanted.

=item

country_code: UK, US, JP, DE, FR.. etc.

=item

city: The city name, like "Miami".

=back

The find method returns a list of point objects, so you catch them in
an array. Each point object has these attributes:

=over 4

=item

url: The URL of camera image.

=item

country_code: UK, US, JP, DE, FR.. etc.

=item

country: The name of the associated country_code.

=item

state: The state abbrevation for US.

=item

city: The city name.

=item

lat: The latitude of this camera image.

=item

lng: The longitude of this camera image.

=back

The detail of the feasible contry/city values are unknown due to the
lack of documentation of the origianl application site.

This work is a based on the work of public-viewpoints service at L<http://public-viewpoints.appspot.com>

=head1 AUTHOR

Kang-min Liu E<lt>gugod@gugod.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Kang-min Liu C<< <gugod@gugod.org> >>.

This is free software, licensed under:

    The MIT (X11) License

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
