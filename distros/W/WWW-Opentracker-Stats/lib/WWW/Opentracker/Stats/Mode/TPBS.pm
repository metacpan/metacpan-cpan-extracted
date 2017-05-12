package WWW::Opentracker::Stats::Mode::TPBS;

use strict;
use warnings;

use parent qw/
    WWW::Opentracker::Stats::Mode
    Class::Accessor::Fast
/;

use WWW::Opentracker::Stats::Mode::TPBS::Bencode;

__PACKAGE__->_format('ben');
__PACKAGE__->_mode('tpbs');

__PACKAGE__->mk_accessors(qw/_stats/);


=head1 NAME

WWW::Opentracker::Stats::Mode::TPBS

=head1 DESCRIPTION

Parses the TPBS statistics from opentracker.

=head1 METHODS

=head2 parse_stats

 Args: $self, $payload

Decodes the bencoded payload data retrieved from the TPBS statistics
of opentracker.

=cut

sub parse_stats {
    my ($self, $payload) = @_;

    return WWW::Opentracker::Stats::Mode::TPBS::Bencode->decode_stats($payload);
}


=head2 SEE ALSO

L<WWW::Opentracker::Stats::Mode::TPBS::Bencode>,
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

