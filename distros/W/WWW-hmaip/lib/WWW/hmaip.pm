use strict;
use warnings;
package WWW::hmaip;
$WWW::hmaip::VERSION = '0.02';
use HTTP::Tiny;
use 5.008;

# ABSTRACT: Returns your ip address using L<http://geoip.hidemyass.com/ip/>


BEGIN {
    require Exporter;
    use base 'Exporter';
    our @EXPORT = 'get_ip';
    our @EXPORT_OK = ();
}


sub get_ip {
    my $response = HTTP::Tiny->new->get('http://geoip.hidemyass.com/ip/');
    return $response->{content} if $response->{success};
    die join(' ', 'Error fetching ip: ',
                  ($response->{status} or ''),
                  ($response->{reason} or ''));
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::hmaip - Returns your ip address using L<http://geoip.hidemyass.com/ip/>

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use WWW::hmaip;

    my $ip = get_ip(); # 54.123.84.6

=head1 EXPORTS

Exports the C<get_ip> function.

=head1 FUNCTIONS

=head2 get_ip

Returns your ip address, using L<http://geoip.hidemyass.com/ip/>.

    use WWW::hmaip;

    my $ip = get_ip();

=head1 SEE ALSO

L<WWW::curlmyip> - another module that returns your ip address

L<WWW::ipinfo> - a module that returns ip address and geolocation data

=head1 AUTHOR

David Farrell <sillymoos@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by David Farrell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
