=pod

=head1 NAME

WGmeta::Parser::Show - Parser for `wg show dump`

=head1 SYNOPSIS

 use Wireguard::WGmeta::Parser::Show;

 my $out = `wg show dump`;
 my $ref_hash_parsed_show = wg_show_dump_parser($out);

=head1 DESCRIPTION

This class contains a parser for the output of C<wg show dump>.

=head1 METHODS

=cut

package Wireguard::WGmeta::Parser::Show;
use strict;
use warnings FATAL => 'all';

use experimental 'signatures';

use base 'Exporter';
our @EXPORT = qw(wg_show_dump_parser);

our $VERSION = "0.3.3"; # do not change manually, this variable is updated when calling make


=head3 wg_show_dump_parser($input)

Parser for the output of C<wg show dump>:

    {
        'interface_name' => {
            'a_peer_pub_key' => {
                'interface'     => <parent_interface>,
                'public-key'    => <interface_public_key>,
                'preshared-key' => <interface_preshared_key>,
                'and_so_on'     => <value_of_attr>
            },
            'an_interface_name => {
                'interface'     => <parent_interface>,
                'private-key'   => <interface_private_key>,
                'and_so_on'     => <value_of_attr>
            }
        },
        'an_other_interface' => {
            [...]
        }
    }

An important remark: This parser is relatively intolerant when it comes to formatting due to the input is already in a "machine readable" format.
It expects one peer/interface per line, the values in the exact same order as defined in @keys_peer/@keys_interface,
separated by a whitespace character. Usually, you don't need to worry about this - it is just meant as word of warning.

B<Parameters>

=over 1

=item

C<$input> Output of C<wg show dump>

=back

B<Returns>

A reference to a hash with the structure described above.

=cut
sub wg_show_dump_parser($input) {
    my $interface = '';
    my $parsed_show = {};

    my @keys_interface = qw(interface private-key public-key listen-port fwmark);
    my @keys_peer = qw(interface public-key preshared-key endpoint allowed-ips latest-handshake transfer-rx transfer-tx persistent-keepalive);
    for my $line (split /\n/, $input) {
        my @split_line = split /\s/, $line;
        unless ($split_line[0] eq $interface) {
            $interface = $split_line[0];
            # handle interface
            my $idx = 0;
            map {$parsed_show->{$interface}{$interface}{$_} = $split_line[$idx];
                $idx++} @keys_interface;
        }
        else {
            my %peer;
            my $idx = 0;
            map {$peer{$_} = $split_line[$idx];
                $idx++;} @keys_peer;
            $parsed_show->{$interface}{$peer{'public-key'}} = \%peer;
        }
    }
    return $parsed_show;
}

1;