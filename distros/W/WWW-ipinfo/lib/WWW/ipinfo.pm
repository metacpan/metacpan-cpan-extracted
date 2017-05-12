use strict;
use warnings;
package WWW::ipinfo;
$WWW::ipinfo::VERSION = '0.05';
use HTTP::Tiny;
use 5.008;
use JSON;

# ABSTRACT: Returns your ip address and geolocation data using L<http://ipinfo.io>


BEGIN {
    require Exporter;
    use base 'Exporter';
    our @EXPORT = 'get_ipinfo';
    our @EXPORT_OK = ();
}



sub get_ipinfo {
    my $ip = shift;
    my $url = $ip ? "http://ipinfo.io/$ip/json" : "http://ipinfo.io/json";
    my $response = HTTP::Tiny->new->get($url);
    die join(' ', 'Error fetching ip: ',
                  ($response->{status} or ''),
                  ($response->{reason} or '')) unless $response->{success};
   decode_json($response->{content});
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::ipinfo - Returns your ip address and geolocation data using L<http://ipinfo.io>

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    use WWW::ipinfo;

    my $ipinfo = get_ipinfo();
    my $city = $ipinfo->{city};

=head1 EXPORTS

Exports the C<get_ipinfo> function.

=head1 FUNCTIONS

=head2 get_ipinfo

Returns a hashref containing ip and geolocation data. Optionally you can provide an ip address argument to get a hashref for an IP that is not your own. Works with IPv4 and IPv6 addresses.

    {
      ip        => "198.115.6.53",
      hostname" => "cpe-198-115-6-53.nyc.res.rr.com",
      city      => "New York",
      region    => "New York",
      country   => "US",
      loc       => "43.7805,-79.9512",
      org       => "Time Warner Cable Internet LLC",
      postal    => "11154"
    }

Example

    use WWW::ipinfo;

    my $ipinfo = get_ipinfo(); # get IP info for your IP address
    my $ip = $ipinfo->{ip}; # your IP address

    my $other_ipinfo = get_ipinfo('FE80::0202:B3FF:FE1E:8329'); #works with IPv6 addresses
    my $country = $other_ipinfo->{country};

=head1 SEE ALSO

L<WWW::curlmyip> - a similar module that returns your ip address

L<WWW::hmaip> - a similar module that returns your ip address

L<WWW::IP> - a module that uses up to 3 services to retrieve your IP address

=head1 CONTRIBUTORS

John D Jones III

=head1 AUTHOR

David Farrell <sillymoos@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by David Farrell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
