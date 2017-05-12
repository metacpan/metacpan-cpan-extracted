package WWW::Opentracker::Stats::Mode::Renew;

use strict;
use warnings;

use parent qw/
    WWW::Opentracker::Stats::Mode
    Class::Accessor::Fast
/;


__PACKAGE__->_format('txt');
__PACKAGE__->_mode('renew');

__PACKAGE__->mk_accessors(qw/_stats/);


=head1 NAME

WWW::Opentracker::Stats::Mode::Renew

=head1 DESCRIPTION

Parses the renew statistics from opentracker.

=head1 METHODS

=head2 parse_stats

 Args: $self, $payload

Decodes the plain text data retrieved from the renew statistics of
opentracker.

The payload looks like this (no indentation):
 00 51
 01 79
 02 69
 03 80
 ...
 41 0
 42 1
 43 2
 44 3

=cut

sub parse_stats {
    my ($self, $payload) = @_;

    my %stats = ();

    for my $line (split "\n", $payload) {
        chomp $line;

        my ($idx, $count) = $line =~ m{^(\d+) (\d+)}
            or die "Unable to parse line: $line";

        $stats{$idx} = $count;
    }

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

