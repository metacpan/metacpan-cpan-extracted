package WWW::Opentracker::Stats::Mode::TPBS::Bencode;

use strict;
use warnings;

use Bit::Vector;
use Convert::Bencode qw(bencode bdecode);


=head1 NAME

WWW::Opentracker::Stats::Mode::TPBS::Bencode

=head1 DESCRIPTION

Decodes the bencoded TPBS statistics from Opentracker.

=head1 METHODS

=head2 decode_stats

 Args: $class, $payload

Returns a HASHREF of the decoded stats structure.

The structure looks something like this:

 $VAR1 => {
    files => {
       INFOHASH => {
           incomplete  => 2,
           downloaded  => 52,
           complete    => 71,
       },
       INFOHASH => ...
    }
 }

=cut

sub decode_stats {
    my ($class, $payload) = @_;

    return {} unless $payload;

    my $t = bdecode($payload);

    $t->{'files'} = {} unless defined $t->{'files'};

    my @replace = keys %{$t->{'files'}};
    
    for my $key (@replace) {
        my $value   = delete $t->{'files'}->{$key};
        my $bin     = unpack('B*', $key);
    
        my $v = Bit::Vector->new_Bin(160, $bin);
        my $hex = $v->to_Hex;
    
        $t->{'files'}->{$hex} = $value;
    }

    return $t;
}


=head1 SEE ALSO

L<Bit::Vector>,
L<Convert::Bencode>


=head1 AUTHOR

Knut-Olav Hoven, E<lt>knutolav@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Knut-Olav Hoven

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
