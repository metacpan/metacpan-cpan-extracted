package WWW::Opentracker::Stats::Mode::Scrape;

use strict;
use warnings;

use parent qw/
    WWW::Opentracker::Stats::Mode
    Class::Accessor::Fast
/;


__PACKAGE__->_format('txt');
__PACKAGE__->_mode('scrp');

__PACKAGE__->mk_accessors(qw/_stats/);


=head1 NAME

WWW::Opentracker::Stats::Mode::Scrape

=head1 DESCRIPTION

Parses the scrape statistics from opentracker.

=head1 METHODS

=head2 parse_stats

 Args: $self, $payload

Decodes the plain text data retrieved from the scrape statistics of opentracker.

The payload looks like this (no indentation):
 19
 0
 33275 seconds (9 hours)
 opentracker scrape stats, 1 scrape/s (tcp and udp)

=cut

sub parse_stats {
    my ($self, $payload) = @_;

    my ($tcp_scrapes, $udp_scrapes, $seconds, $scrapes_per_sec)
        = $payload =~ m{\A
            (\d+) \s
            (\d+) \s
            (\d+) \s seconds \s \( \d+ \s hours \) \s
            opentracker \s scrape \s stats , \s
                (\d+) \s scrape/s \s
        }xms
        or die "Unable to parse payload: $payload";

    my %stats = (
        'tcp_scrapes'       => $tcp_scrapes,
        'udp_scrapes'       => $udp_scrapes,
        'uptime'            => $seconds,
        'scrapes_per_sec'   => $scrapes_per_sec,
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

