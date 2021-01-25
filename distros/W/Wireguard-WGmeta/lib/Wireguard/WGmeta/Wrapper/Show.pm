=pod

=head1 NAME

WGmeta::Wrapper::Show - Class for parsing the `wg show dump` output

=head1 SYNOPSIS

 use Wireguard::WGmeta::Wrapper::Show;
 my $wg_show = Wireguard::WGmeta::Wrapper::Show->new(<wg show dump output as string>);

 # if you need just the parser
 my $out = `wg show dump`;
 my $ref_hash_parsed_show = wg_show_dump_parser($out);


=head1 DESCRIPTION

This class contains a parser for the output of C<wg show dump> together with an interface to retrieve the parsed data.
An important note: This class does not perform the necessary I/O by itself and therefore the output of the command
C<wg show dump> has to be captured into a string externally (e.g using L<Wireguard::WGmeta::Wrapper::Bridge/get_wg_show()>).


=head1 EXAMPLES

 use Wireguard::WGmeta::Wrapper::Show;
 use Wireguard::WGmeta::Wrapper::Bridge;

 my ($out, $err) = get_wg_show();
 my $wg_show = Wireguard::WGmeta::Wrapper::Show->new($out);

 # get a specfic interface section
 wg_show->get_interface_section('wg0', '<interface_public_key>');

=head1 METHODS

=cut
use v5.20.0;
package Wireguard::WGmeta::Wrapper::Show;
use strict;
use warnings FATAL => 'all';
use experimental 'signatures';

use base 'Exporter';
our @EXPORT = qw(wg_show_dump_parser);

our $VERSION = "0.1.2";

use constant FALSE => 0;
use constant TRUE => 1;
use Data::Dumper;
use Wireguard::WGmeta::Utils;

=head3 new($wg_show_dump)

Creates a new instance of the show parser

B<Parameters>

=over 1

=item

C<$wg_show_dump> Output of the (external) command C<wg show dump>.

=back

B<Returns>

Instance

=cut
sub new($class, $wg_show_dump) {
    my $self = {
        'parsed_show' => wg_show_dump_parser($wg_show_dump)
    };

    bless $self, $class;

    return $self;
}

=head3 wg_show_dump_parser($input)

Parser for the output of C<wg show dump>. Aims to create a compatible with:
L<Wireguard::WGmeta::Wrapper::Config/read_wg_configs($wireguard_home, $wg_meta_prefix, $disabled_prefix)>:

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
separated by a whitespace character. Usually, you don't have to worry about this - it is just meant as word of warning.

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

    # ToDo: Make use of WGmeta::ValidAttributes
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

=head3 get_interface_list()

Returns a list with all available interface names

B<Parameters>

B<Returns>

A list with valid interface names.

=cut
sub get_interface_list($self) {
    return sort keys %{$self->{parsed_show}};
}

=head3 iface_exists($interface)

Simply checks if data is available for a specific interface. Useful to check if an interface is up.

B<Parameters>

=over 1

=item

C<$interface> An interface name

=back

B<Returns>

If yes, returns True else False

=cut
sub iface_exists($self, $interface) {
    return exists $self->{parsed_show}{$interface};
}

=head3 get_interface_section($interface, $identifier)

Returns a specific section of an interface

B<Parameters>

=over 1

=item

C<$interface> A valid interface name, ideally retrieved through L</get_interface_list()>.

=item

C<$identifier> A valid identifier, if the requested section is a peer this is its public-key, otherwise the interface
name again.

=back

B<Returns>

A hash of the requested section. If non-existent, empty hash.

=cut
sub get_interface_section($self, $interface, $identifier) {
    if (exists($self->{parsed_show}{$interface}{$identifier})) {
        return %{$self->{parsed_show}{$interface}{$identifier}};
    }
    else {
        return ();
    }
}
=head3 get_section_list($interface)

Returns a sorted list of all peers belonging to given interface

B<Parameters>

=over 1

=item

C<$interface> A valid interface name, ideally retrieved through L</get_interface_list()>.

=back

B<Returns>

A list of peer public-keys (identifiers), if the interface does not exist -> empty list.

=cut
sub get_section_list($self, $interface) {
    if (exists($self->{parsed_show}{$interface})) {
        return sort keys %{$self->{parsed_show}{$interface}};
    }
    else {
        return {};
    }
}
=head3 dump()

Simple dumper method to print contents of C<< $self->{parsed_show} >>.

=cut
sub dump($self) {
    print Dumper $self->{parsed_show};
}


1;