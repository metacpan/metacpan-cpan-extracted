package WWW::Opentracker::Stats::Mode::Top10;

use strict;
use warnings;

use parent qw/
    WWW::Opentracker::Stats::Mode
    Class::Accessor::Fast
/;


__PACKAGE__->_format('txt');
__PACKAGE__->_mode('top10');

__PACKAGE__->mk_accessors(qw/_stats/);


=head1 NAME

WWW::Opentracker::Stats::Mode::Top10

=head1 DESCRIPTION

Parses the top 10 statistics from opentracker.

=head1 METHODS

=head2 parse_stats

 Args: $self, $payload

Decodes the plain text data retrieved from the top 10 statistics of
opentracker.

The payload looks like this (no indentation):
 Top 10 torrents by peers:
         44      8C18F57626C3D514E5CFD9B991EF0D723059D0E0
         36      644AA544E92C6C4F498437FCD0A08D8401F55A55
         11      9CAD13D1C771069F36634682F02233018A582B8B
         11      BE4C3155BB0709DFE5475BC938CE15BF5D6E9EC8
         10      0EAA0651DFBA2DF49C8E96E252527FC79F648A1E
         10      6DD48BFFD481D905E33F331689CE13B27DD42FFD
         10      BEE8EDA4916BCD7A7ABB6AACADC4EA18F4855B3D
         9       C407ECB3D0ACF0D0E01488960005B844BFCF2F03
 Top 10 torrents by seeds:
         44      8C18F57626C3D514E5CFD9B991EF0D723059D0E0
         36      644AA544E92C6C4F498437FCD0A08D8401F55A55
         11      9CAD13D1C771069F36634682F02233018A582B8B
         11      BE4C3155BB0709DFE5475BC938CE15BF5D6E9EC8
         10      0EAA0651DFBA2DF49C8E96E252527FC79F648A1E
         10      6DD48BFFD481D905E33F331689CE13B27DD42FFD
         10      BEE8EDA4916BCD7A7ABB6AACADC4EA18F4855B3D
         9       C407ECB3D0ACF0D0E01488960005B844BFCF2F03

=cut

sub parse_stats {
    my ($self, $payload) = @_;

    my @bypeers = ();
    my @byseeds = ();

    my $current = undef;

    for my $line (split "\n", $payload) {
        chomp $line;

        if ($line =~ m{^Top .* peers}) {
            $current = 'peers';
            next;
        }

        if ($line =~ m{^Top .* seeds}) {
            $current = 'seeds';
            next;
        }

        die "Unable to group torrent statistics" unless $current;

        my ($count, $infohash)
            = $line =~ m{\A
                \s+ (\d+) \s+ ([A-Fa-f0-9]{40})
            }xms
            or die "Failed to parse line of payload for $current: $line";

        my %torrent = (
            'torrent'   => $infohash,
            'count'     => $count,
        );

        push @bypeers, \%torrent if 'peers' eq $current;
        push @byseeds, \%torrent if 'seeds' eq $current;
    }

    my %stats = (
        'peers'     => \@bypeers,
        'seeds'     => \@byseeds,
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

