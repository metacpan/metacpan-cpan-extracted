=pod

=head1 NAME

WGmeta::Wrapper::Show - Class for interfacing `wg show dump` output

=head1 SYNOPSIS

 use Wireguard::WGmeta::Wrapper::Show;
 my $wg_show = Wireguard::WGmeta::Wrapper::Show->new(<wg show dump output as string>);

=head1 DESCRIPTION

This class provides wrapper-functions around the output of L<Wireguard::WGmeta::Parser::Show>.

=head1 EXAMPLES

 use Wireguard::WGmeta::Wrapper::Show;
 use Wireguard::WGmeta::Wrapper::Bridge;

 my ($out, $err) = get_wg_show();
 my $wg_show = Wireguard::WGmeta::Wrapper::Show->new($out);

 # get a specific interface section
 wg_show->get_interface_section('wg0', '<interface_public_key>');

=head1 METHODS

=cut
use v5.20.0;
package Wireguard::WGmeta::Wrapper::Show;
use strict;
use warnings FATAL => 'all';
use experimental 'signatures';


our $VERSION = "0.2.2";

use constant FALSE => 0;
use constant TRUE => 1;
use Wireguard::WGmeta::Utils;
use Wireguard::WGmeta::Parser::Show;

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

1;