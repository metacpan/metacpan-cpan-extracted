package WWW::Opentracker::Stats::Mode::Fullscrape;

use strict;
use warnings;

use parent qw/
    WWW::Opentracker::Stats::Mode
    Class::Accessor::Fast
/;


__PACKAGE__->_format('txt');
__PACKAGE__->_mode('fscr');

__PACKAGE__->mk_accessors(qw/_stats/);


=head1 NAME

WWW::Opentracker::Stats::Mode::Fullscrape

=head1 DESCRIPTION

Parses the fullscrape statistics from opentracker.

=head1 METHODS

=head2 parse_stats

 Args: $self, $payload

Decodes the plain text data retrieved from the fullscrape statistics of opentracker.

The payload looks like this (no indentation):
 21000
 1701
 36369 seconds (10 hours)
 opentracker full scrape stats, 0 conns/s :: 0 bytes/s.

=cut

sub parse_stats {
    my ($self, $payload) = @_;

    my ($count, $size, $seconds, $count_per_sec, $size_per_sec)
        = $payload =~ m{\A
            (\d+) \s
            (\d+) \s
            (\d+) \s seconds \s \( \d+ \s hours \) \s
            opentracker \s full \s scrape \s stats , \s
                (\d+) \s conns/s \s :: \s (\d+) \s bytes/s \.
        }xms
        or die "Unable to parse payload: $payload";

    my %stats = (
        'count'         => $count,
        'size'          => $size,
        'uptime'        => $seconds,
        'count_per_sec' => $count_per_sec,
        'size_per_sec'  => $size_per_sec,
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

