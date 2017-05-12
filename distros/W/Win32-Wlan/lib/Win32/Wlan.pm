package Win32::Wlan;
use strict;
use Carp qw(croak);
use Win32::Wlan::API qw<
    WlanOpenHandle
    WlanCloseHandle
    WlanQueryCurrentConnection
    WlanEnumInterfaces
    WlanGetAvailableNetworkList
    $wlan_available
>;
use vars qw<$VERSION>;
$VERSION = '0.06';

# Ideally, the handle should be (another) singleton
# that fetches and keeps the handle until the application
# closes or the last Win32::Wlan object gets destroyed

=head1 NAME

Win32::Wlan - Query wlan properties

=head1 SYNOPSIS

    require Win32::Wlan;
    my $wlan = Win32::Wlan->new;
    if ($wlan->available) {
        print "Connected to ", $wlan->connection->{profile_name},"\n";
        print "I see the following networks\n";
        for ($wlan->visible_networks) {
            printf "%s\t-%d dbm\n", $_->{name}, $_->{signal_quality};
        };

    } else {
        print "No Wlan detected (or switched off)\n";
    };

=head1 METHODS

=head2 C<< Win32::Wlan->new( %args ) >>

    my $wlan = Win32::Wlan->new();

Creates a new Win32::Wlan object.

=over 4

=item *

C<available> - optional argument to force detection of general Wlan availability

=item *

C<handle> - optional argument to give an existing Wlan handle to the object

=item *

C<interface> - optional argument to give an existing guuid to the object

=back

=cut

sub new {
    my ($class,%args) = @_;
    
    if ($args{ available } or !exists $args{ available }) {
        $args{available} ||= $wlan_available;
        $args{handle} ||= WlanOpenHandle();
        if (! $args{ interface }) {
            my @interfaces = WlanEnumInterfaces($args{handle});
            if (@interfaces > 1) {
                warn "More than one Wlan interface found. Using first.";
            };
            $args{interface} = $interfaces[0];
        };
    };
    bless \%args => $class;
};

sub DESTROY {
    my ($self) = @_;
    if ($self->handle and $self->available) {
        WlanCloseHandle($self->handle);
    };
}

=head2 C<< $wlan->handle >>

Returns the Windows API handle for the Wlan API.

=cut

sub handle { $_[0]->{handle} };

=head2 C<< $wlan->interface >>

    print $wlan->interface->{name};

Returns a hashref describing the interface. The keys are
C<guuid> for the guuid, C<name> for the human-readable name and
C<status> for the status of the interface.

=cut

sub interface { $_[0]->{interface} };

=head2 C<< $wlan->available >>

    $wlan->available
        or warn "Wlan API is not available";

Returns whether the Wlan API is available. The Wlan API is available
on Windows XP SP3 or higher.

=cut

sub available { $_[0]->{available} };

=head2 C<< $wlan->connected >>

    $wlan->connected
        or warn "Wlan connection unavailable";

Returns whether a Wlan connection is established. No connection is established
when Wlan is switched off or no access point is in range.

=cut

sub connected {
    my $conn = $_[0]->connection;
    defined $conn->{profile_name} && $conn->{profile_name}
};

=head2 C<< $wlan->connection >>

    if ($wlan->connected) {
        print "Connected to ";
        print $wlan->connection->{profile_name};
    };

Returns information about the current connection in a hashref. The keys
are

=over 4

=item *

C<profile_name> - the name of the profile of the current connection

=back

=cut

sub connection {
    my ($self) = @_;
    if ($self->available) {
        return { WlanQueryCurrentConnection( $self->handle, $self->interface->{guuid} ) };
    };
};

=head2 C<< $wlan->visible_networks >>

Returns information about the currently visible networks as a list of
hashrefs.

=over 4

=item *

C<ssid> - the SSID of the network

=item *

C<signal_quality> - the signal quality ranging linearly from 0 to 100
meaning -100 dbm to -50 dbm

=back

=cut

sub visible_networks {
    my ($self) = @_;
    if ($self->available) {
        return WlanGetAvailableNetworkList( $self->handle, $self->interface->{guuid} );
    };
};

1;

__END__

=head1 SIMPLIFICATIONS

This module only supports the first wireless connection. If your machine
has more than one wireless connection, you will need to use
L<Win32::Wlan::API> directly.

Currently, the module also has no way of determining whether Wlan
gets switched on or off.

=head1 SEE ALSO

L<Win32::Wlan::API> - the wrapper for the Windows API

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
