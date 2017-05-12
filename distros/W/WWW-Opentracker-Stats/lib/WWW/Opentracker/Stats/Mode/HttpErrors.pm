package WWW::Opentracker::Stats::Mode::HttpErrors;

use strict;
use warnings;

use parent qw/
    WWW::Opentracker::Stats::Mode
    Class::Accessor::Fast
/;


__PACKAGE__->_format('txt');
__PACKAGE__->_mode('herr');

__PACKAGE__->mk_accessors(qw/_stats/);


=head1 NAME

WWW::Opentracker::Stats::Mode::HttpErrors

=head1 DESCRIPTION

Parses the HTTP errors statistics from opentracker.

=head1 METHODS

=head2 parse_stats

 Args: $self, $payload

Decodes the plain text data retrieved from the HTTP errors statistics of
opentracker.

The payload looks like this (no indentation):
 302 RED 1
 400 ... 2
 400 PAR 3
 400 COM 4
 403 IP  5
 404 INV 6
 500 SRV 46

=cut

sub parse_stats {
    my ($self, $payload) = @_;

    my ($e302red, $e400, $e400par, $e400com, $e403ip, $e404inv, $e500srv)
        = $payload =~ m{\A
            302 \s RED      \s+ (\d+) \s
            400 \s \.{3}    \s+ (\d+) \s
            400 \s PAR      \s+ (\d+) \s
            400 \s COM      \s+ (\d+) \s
            403 \s IP       \s+ (\d+) \s
            404 \s INV      \s+ (\d+) \s
            500 \s SRV      \s+ (\d+)
        }xms
        or die "Unable to parse payload: $payload";

    my %stats = (
        '302red'    => $e302red,
        '400'       => $e400,
        '400par'    => $e400par,
        '400com'    => $e400com,
        '403ip'     => $e403ip,
        '404inv'    => $e404inv,
        '500srv'    => $e500srv,
    );

    return \%stats;
}


=head1 SEE ALSO

L<WWW::Opentracker::Stats::Mode>

=head1 AUTHOR

Knut-Olav Hoven, E<lt>knutolav@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Knut-Olav Hoven

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;

