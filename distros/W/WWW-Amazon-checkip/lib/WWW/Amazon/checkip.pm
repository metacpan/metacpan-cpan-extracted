package WWW::Amazon::checkip;

  use 5.008;
  use strict;
  use warnings;

  our $VERSION = '0.01';

  use HTTP::Tiny;

  BEGIN {
    require Exporter;
    use base 'Exporter';
    our @EXPORT = 'get_ip';
    our @EXPORT_OK = ();
  }


  sub get_ip {
    my $response = HTTP::Tiny->new->get("http://checkip.amazonaws.com/");
    die sprintf 'Error fetching ip: %s %s',
      ($response->{status} || ''),
      ($response->{reason} || '') unless $response->{success};
    chomp $response->{content};
    return $response->{ content };
  }

1;

=pod

=encoding UTF-8

=head1 NAME

WWW::Amazon::checkip - Returns your ip address using L<http://checkip.amazonaws.com/>

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use WWW::Amazon::checkip;
    my $ip = get_ip();

or from the command line

    perl -MWWW::Amazon::checkip -E 'say get_ip'

=head1 EXPORTS

Exports the C<get_ip> function.

=head1 FUNCTIONS

=head2 get_ip

Returns your external ipv4 address.

=head1 SEE ALSO

L<WWW::canihazip> - a similar module that returs your up address

L<WWW::ipinfo> - a similar module that returns your ip address and more

L<WWW::hmaip> - a similar module that returns your ip address

L<WWW::IP> - a wrapper module that uses up to 3 services to retrieve your IP address

=head1 AUTHOR

Jose Luis Martinez Torres <jlmartinez@capside.com>

Based on the work by David Farrell for L<WWW::canihazip>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by CAPSiDE

This code is distributed under the Apache 2 License. The full text of the 
license can be found in the LICENSE file included with this module.

=cut
