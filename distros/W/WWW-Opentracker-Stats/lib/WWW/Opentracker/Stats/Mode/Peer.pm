package WWW::Opentracker::Stats::Mode::Peer;

use strict;
use warnings;

use parent qw/
    WWW::Opentracker::Stats::Mode
    Class::Accessor::Fast
/;


__PACKAGE__->_format('txt');
__PACKAGE__->_mode('peer');

__PACKAGE__->mk_accessors(qw/_stats/);


=head1 NAME

WWW::Opentracker::Stats::Mode::Peer

=head1 DESCRIPTION

Parses the Peer statistics from opentracker.

=head1 METHODS

=head2 parse_stats

 Args: $self, $payload

Decodes the plain text data retrieved from the peer statistics of opentracker.

The payload looks like this (no indentation):
 3
 3
 opentracker serving 2 torrents
 opentracker

=cut

sub parse_stats {
    my ($self, $payload) = @_;

    # To support thousand delimiters
    my ($raw_peers, $raw_seeds, $raw_torrents) = $payload =~ m{\A
            ([\d\'\.]+) \s
            ([\d\'\.]+) \s
            opentracker \s serving \s ([\d\'\.]+) \s torrents \s
            opentracker
        }xms
        or die "Unable to parse payload: $payload";

    my %stats = (
        'peers'     => $self->parse_thousands($raw_peers),
        'seeds'     => $self->parse_thousands($raw_seeds),
        'torrents'  => $self->parse_thousands($raw_torrents),
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

