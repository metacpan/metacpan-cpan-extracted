package Win32::Wlan::API;
use strict;
use Carp qw(croak);

use Encode qw(decode);

use Exporter 'import';

use vars qw($VERSION $wlan_available %API @signatures @EXPORT_OK);
$VERSION = '0.06';

sub Zero() { "\0\0\0\0" };
# just in case we ever get a 64bit Win32::API
# Zero will have to return 8 bytes of zeroes

BEGIN {
    @signatures = (
        ['WlanOpenHandle' => 'IIPP' => 'I'],
        ['WlanCloseHandle' => 'II' => 'I'],
        ['WlanFreeMemory' => 'I' => 'I'],
        ['WlanEnumInterfaces' => 'IIP' => 'I'],
        ['WlanQueryInterface' => 'IPIIPPI' => 'I'],
        ['WlanGetAvailableNetworkList' => 'IPIIP' => 'I'],
    );

    @EXPORT_OK = (qw<$wlan_available WlanQueryCurrentConnection>, map { $_->[0] } @signatures);
};

use constant {
  not_ready               => 0,
  connected               => 1,
  ad_hoc_network_formed   => 2,
  disconnecting           => 3,
  disconnected            => 4,
  associating             => 5,
  discovering             => 6,
  authenticating          => 7 
};

if (! load_functions()) {
    # Wlan functions are not available
    $wlan_available = 0;
} else {
    $wlan_available = 1;
};

sub unpack_struct {
    # Unpacks a string into a hash
    # according to a key/unpack template structure
    my $desc = shift;
    my @keys;
    my $template = '';

    for (0..$#{$desc}) {
        if ($_ % 2) {
            $template .= $desc->[ $_ ]
        } elsif ($desc->[ $_ ] ne '') {
            push @keys, $desc->[ $_ ]
        };
    };

    my %res;
    @res{ @keys } = unpack $template, shift;
    %res
}

sub WlanOpenHandle {
    croak "Wlan functions are not available" unless $wlan_available;
    my $version = Zero;
    my $handle = Zero;
    $API{ WlanOpenHandle }->Call(2,0,$version,$handle) == 0
        or croak $^E;
    my $h = unpack "V", $handle;
    $h
};

sub WlanCloseHandle {
    croak "Wlan functions are not available" unless $wlan_available;
    my ($handle) = @_;
    $API{ WlanCloseHandle }->Call($handle,0) == 0
        or croak $^E;
};

sub WlanFreeMemory {
    croak "Wlan functions are not available" unless $wlan_available;
    my ($block) = @_;
    $API{ WlanFreeMemory }->Call($block);
};

sub _unpack_counted_array {
    my ($pointer,$template,$size) = @_;
    my $info = unpack 'P8', $pointer;
    my ($count,$curr) = unpack 'VV', $info;
    my $data = unpack "P" . (8+$count*$size), $pointer;
    my @items = unpack "x8 ($template)$count", $data;
    my @res;
    if ($count) {
        my $elements_per_item = @items / $count;
        while (@items) {
            push @res, [splice @items, 0, $elements_per_item ]
        };
    };
    @res
};

sub WlanEnumInterfaces {
    croak "Wlan functions are not available" unless $wlan_available;
    my ($handle) = @_;
    my $interfaces = Zero;
    $API{ WlanEnumInterfaces }->Call($handle,0,$interfaces) == 0
        or croak $^E;
    my @items = _unpack_counted_array($interfaces,'a16 a512 V',16+512+4);
    @items = map {
        # First element is the GUUID of the interface
        # Name is in 16bit UTF
        $_->[1] = decode('UTF-16LE' => $_->[1]);
        $_->[1] =~ s/\0+$//;
        # The third element is the status of the interface
        
        +{
            guuid => $_->[0],
            name =>  $_->[1],
            status => $_->[2],
        };
    } @items;
    
    $interfaces = unpack 'V', $interfaces;
    WlanFreeMemory($interfaces);
    @items
};

sub WlanQueryInterface {
    croak "Wlan functions are not available" unless $wlan_available;
    my ($handle,$interface,$op) = @_;
    my $size = Zero;
    my $data = Zero;
    $API{ WlanQueryInterface }->Call($handle, $interface, $op, 0, $size, $data, 0) == 0
        or return;
        
    $size = unpack 'V', $size;
    my $payload = unpack "P$size", $data;
    
    $data = unpack 'V', $data;
    WlanFreeMemory($data);
    $payload
};

=head2 C<< WlanCurrentConnection( $handle, $interface ) >>

Returns a hashref containing the following keys

=over 4

=item *

C<< state >> - state of the interface

One of the following

  Win32::Wlan::API::not_ready               => 0,
  Win32::Wlan::API::connected               => 1,
  Win32::Wlan::API::ad_hoc_network_formed   => 2,
  Win32::Wlan::API::disconnecting           => 3,
  Win32::Wlan::API::disconnected            => 4,
  Win32::Wlan::API::associating             => 5,
  Win32::Wlan::API::discovering             => 6,
  Win32::Wlan::API::authenticating          => 7 

=item *

C<< mode >>

=item *

C<< profile_name >>

C<< bss_type >>

  infrastructure   = 1,
  independent      = 2,
  any              = 3 

=item *

auth_algorithm

  DOT11_AUTH_ALGO_80211_OPEN         = 1,
  DOT11_AUTH_ALGO_80211_SHARED_KEY   = 2,
  DOT11_AUTH_ALGO_WPA                = 3,
  DOT11_AUTH_ALGO_WPA_PSK            = 4,
  DOT11_AUTH_ALGO_WPA_NONE           = 5,
  DOT11_AUTH_ALGO_RSNA               = 6, # wpa2
  DOT11_AUTH_ALGO_RSNA_PSK           = 7, # wpa2
  DOT11_AUTH_ALGO_IHV_START          = 0x80000000,
  DOT11_AUTH_ALGO_IHV_END            = 0xffffffff 

=item *

cipher_algorithm

  DOT11_CIPHER_ALGO_NONE            = 0x00,
  DOT11_CIPHER_ALGO_WEP40           = 0x01,
  DOT11_CIPHER_ALGO_TKIP            = 0x02,
  DOT11_CIPHER_ALGO_CCMP            = 0x04,
  DOT11_CIPHER_ALGO_WEP104          = 0x05,
  DOT11_CIPHER_ALGO_WPA_USE_GROUP   = 0x100,
  DOT11_CIPHER_ALGO_RSN_USE_GROUP   = 0x100,
  DOT11_CIPHER_ALGO_WEP             = 0x101,
  DOT11_CIPHER_ALGO_IHV_START       = 0x80000000,
  DOT11_CIPHER_ALGO_IHV_END         = 0xffffffff 

=back

=cut 

sub WlanQueryCurrentConnection {
    my ($handle,$interface) = @_;
    my $info = WlanQueryInterface($handle,$interface,7) || '';
    
    my @WLAN_CONNECTION_ATTRIBUTES = (
        state => 'V',
        mode  => 'V',
        profile_name => 'a512',
        # WLAN_ASSOCIATION_ATTRIBUTES
        ssid_len => 'V',
        ssid => 'a32',
        bss_type => 'V',
        mac_address => 'a6',
        dummy => 'a2', # ???
        phy_type => 'V',
        phy_index => 'V',
        signal_quality => 'V',
        rx_rate => 'V',
        tx_rate => 'V',
        security_enabled => 'V', # BOOL
        onex_enabled     => 'V', # BOOL
        auth_algorithm   => 'V',
        cipher_algorithm => 'V',
    );
    
    my %res = unpack_struct(\@WLAN_CONNECTION_ATTRIBUTES, $info);
    
    $res{ profile_name } = decode('UTF-16LE', $res{ profile_name }) || '';
    $res{ profile_name } =~ s/\0+$//;
    $res{ ssid } = substr $res{ ssid }, 0, $res{ ssid_len };
    
    $res{ mac_address } = sprintf "%02x:%02x:%02x:%02x:%02x:%02x", unpack 'C*', $res{ mac_address };
    
    %res
}

sub WlanGetAvailableNetworkList {
    my ($handle,$interface,$flags) = @_;
    $flags ||= 0;
    my $list = Zero;
    $API{ WlanGetAvailableNetworkList }->Call($handle,$interface,$flags,0,$list) == 0
        or croak $^E;
                                                # name ssid_len ssid bss  bssids connectable
    my @items = _unpack_counted_array($list, join( '', 
        'a512', # name
        'V',    # ssid_len
        'a32',  # ssid
        'V',    # bss
        'V',    # bssids
        'V',    # connectable
        'V',    # notConnectableReason,
        'V',    # PhysTypes
        'V8',   # PhysType elements
        'V',    # More PhysTypes
        'V',    # wlanSignalQuality from 0=-100dbm to 100=-50dbm, linear
        'V',    # bSecurityEnabled;
        'V',    # dot11DefaultAuthAlgorithm;
        'V',    # dot11DefaultCipherAlgorithm;
        'V',    # dwFlags
        'V',    # dwReserved;
    ), 512+4+32+20*4);
    for (@items) {
        my %info;
        @info{qw( name ssid_len ssid bss bssids connectable notConnectableReason
                  phystype_count )} = splice @$_, 0, 8;
        $info{ phystypes }= [splice @$_, 0, 8];
        @info{qw( has_more_phystypes
                  signal_quality
                  security_enabled
                  default_auth_algorithm
                  default_cipher_algorithm
                  flags
                  reserved
        )} = @$_;
        
        # Decode the elements
        $info{ ssid } = substr( $info{ ssid }, 0, $info{ ssid_len });
        $info{ name } = decode('UTF-16LE', $info{ name });
        $info{ name } =~ s/\0+$//;
        splice @{$info{ phystypes }}, $info{ phystype_count };

        $_ = \%info;
    };
    
    $list = unpack 'V', $list;
    WlanFreeMemory($list);
    @items
}

sub load_functions {
    my $ok = eval {
        require Win32::API;
        1
    };
    return if ! $ok;
    for my $sig (@signatures) {
        $API{ $sig->[0] } = eval {
            Win32::API->new( 'wlanapi.dll', @$sig );
        };
        if (! $API{ $sig->[0] }) {
            return
        };
    };
    1
};

1;

__END__

=head1 NAME

Win32::Wlan::API - Access to the Win32 WLAN API

=head1 SYNOPSIS

    use Win32::Wlan::API qw(WlanOpenHandle WlanEnumInterfaces WlanQueryCurrentConnection);
    if ($Win32::Wlan::available) {
        my $handle = WlanOpenHandle();
        my @interfaces = WlanEnumInterfaces($handle);
        my $ih = $interfaces[0]->{guuid};
        # Network adapters are identified by guuid
        print $interfaces[0]->{name};
        my $info = WlanQueryCurrentConnection($handle,$ih);
        print "Connected to $info{ profile_name }\n";        

    } else {
        print "No Wlan detected (or switched off)\n";
    };

=head1 SEE ALSO

Windows Native Wifi Reference

L<http://msdn.microsoft.com/en-us/library/ms706274%28v=VS.85%29.aspx>

=head1 REPOSITORY

The public repository of this module is 
L<http://github.com/Corion/Win32-Wlan>.

=head1 SUPPORT

The public support forum of this module is
L<http://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Win32-Wlan>
or via mail to L<win32-wlan-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2011-2011 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
