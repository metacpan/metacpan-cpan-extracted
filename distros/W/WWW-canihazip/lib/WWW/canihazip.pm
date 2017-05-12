use strict;
use warnings;
package WWW::canihazip;
$WWW::canihazip::VERSION = '0.01';
use HTTP::Tiny;
use 5.008;

# ABSTRACT: Returns your ip address using L<http://canihazip.com>


BEGIN {
    require Exporter;
    use base 'Exporter';
    our @EXPORT = 'get_ip';
    our @EXPORT_OK = ();
}


sub get_ip {
  my $response = HTTP::Tiny->new->get("http://canihazip.com/s");
  die sprintf 'Error fetching ip: %s %s',
    ($response->{status} || ''),
    ($response->{reason} || '') unless $response->{success};
  $response->{content};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::canihazip - Returns your ip address using L<http://canihazip.com>

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use WWW::canihazip;
    my $ip = get_ip();

=head1 EXPORTS

Exports the C<get_ip> function.

=head1 FUNCTIONS

=head2 get_ip

Returns your external ipv4 address.

=head1 SEE ALSO

L<WWW::ipinfo> - a similar module that returns your ip address and more

L<WWW::hmaip> - a similar module that returns your ip address

L<WWW::IP> - a wrapper module that uses up to 3 services to retrieve your IP address

=head1 AUTHOR

David Farrell <dfarrell@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by David Farrell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
