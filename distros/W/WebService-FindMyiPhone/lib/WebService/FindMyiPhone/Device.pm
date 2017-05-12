package WebService::FindMyiPhone::Device;

use strict;
use warnings;

use 5.010_001;
our $VERSION = '0.02';

use Carp;

# use Data::Dumper;    # TODO: remove

sub new {
    my ( $class, $parent, $data ) = @_;
    my $self = { _parent => $parent, %$data };
    return bless $self, $class;
}

sub _update_self {
    my ( $self, $new_data ) = @_;
    $self->{$_} = $new_data->{$_} for keys %$new_data;
}

sub send_message {
    my ( $self, $sound, $message, $subject ) = @_;
    $sound = $sound ? 'true' : 'false';
    $subject ||= 'Important Message';
    my $post
        = sprintf(
        '{"clientContext":{"appName":"FindMyiPhone","appVersion":"1.4","buildVersion":"145","deviceUDID":"0000000000000000000000000000000000000000","inactiveTime":5911,"osVersion":"3.2","productType":"iPad1,1","selectedDevice":"%s","shouldLocate":false},"device":"%s","serverContext":{"callbackIntervalInMS":3000,"clientId":"0000000000000000000000000000000000000000","deviceLoadStatus":"203","hasDevices":true,"lastSessionExtensionTime":null,"maxDeviceLoadTime":60000,"maxLocatingTime":90000,"preferredLanguage":"en","prefsUpdateTime":1276872996660,"sessionLifespan":900000,"timezone":{"currentOffset":-25200000,"previousOffset":-28800000,"previousTransition":1268560799999,"tzCurrentName":"Pacific Daylight Time","tzName":"America/Los_Angeles"},"validRegion":true},"sound":%s,"subject":"%s","text":"%s","userText":true}',
        $self->{id}, $self->{id}, $sound, $subject, $message );
    return $self->{_parent}->_post( '/sendMessage', $post )->json;
}

sub remote_lock {
    my ( $self, $passcode ) = @_;
    my $post
        = sprintf(
        '{"clientContext":{"appName":"FindMyiPhone","appVersion":"1.4","buildVersion":"145","deviceUDID":"0000000000000000000000000000000000000000","inactiveTime":5911,"osVersion":"3.2","productType":"iPad1,1","selectedDevice":"%s","shouldLocate":false},"device":"%s","oldPasscode":"","passcode":"%s","serverContext":{"callbackIntervalInMS":3000,"clientId":"0000000000000000000000000000000000000000","deviceLoadStatus":"203","hasDevices":true,"lastSessionExtensionTime":null,"maxDeviceLoadTime":60000,"maxLocatingTime":90000,"preferredLanguage":"en","prefsUpdateTime":1276872996660,"sessionLifespan":900000,"timezone":{"currentOffset":-25200000,"previousOffset":-28800000,"previousTransition":1268560799999,"tzCurrentName":"Pacific Daylight Time","tzName":"America/Los_Angeles"},"validRegion":true}}',
        $self->{id}, $self->{id}, $passcode );
    return $self->{_parent}->_post( '/remoteLock', $post );
}

sub location {
    my ($self) = @_;
    my $count = 0;
    while ( !$self->{location}{locationFinished} ) {
        # print Dumper( $self->{location} );
        sleep 2;
        $self->{_parent}->update_devices;
        last if ++$count >= 3;
        # warn "Sleeping and checking again";

    }
    return $self->{location};
}

1;
__END__

=encoding utf-8

=head1 NAME

WebService::FindMyiPhone::Device - Device object for WebService::FindMyiPhone

=head1 SYNOPSIS

  use WebService::FindMyiPhone;
  my $fmiphone = WebService::FindMyiPhone->new(
      username => 'email@address',
      password => 'YaakovLOVE',
  );
  my $iphone = $fmiphone->get_device_by( name => 'mmm cake');
  my $location = $iphone->location();
  $iphone->send_message(1, 'Where did I leave you?');

=head1 DESCRIPTION

WebService::FindMyiPhone::Device is the class used for
L<WebService::FindMyiPhone> devices. See the documentation there for more
information.

Device objects are stored as a blessed hashref, the C<_parent> key is a
reference to the L<WebService::FindMyiPhone> object that created it.  The rest
of the keys are directly from Apple.  You are incouraged to inspect the data
there and make use of anything interesting to you.

=head1 METHODS

=head2 send_message( $sound, $message, $subject )

Send a message to the device.  C<$sound> determines if a sound should be
played with the message, a true value will cause a sound even if the phone or
iPad is in silent mode.  C<$message> is the message to display.  C<$subject> is
optional and defaults to 'Important Message'.

=head2 remote_lock($passcode)

Lock the device remotely and require C<$passcode> to unlock.

=head2 location()

Returns a hashref with location data.  Keys include C<latitude>, C<longitude>,
C<horizontalAccuracy>, C<positionType>, C<isInaccurate>, C<isOld >,
C<locationType>, C<locationFinished>, and C<timeStamp>.

If <locationFinished> is false, the method will sleep 2 seconds, call the
parent's C<update_devices> method and check again.  It will try up to 3 times
and then return what it has.

Possible values for C<positionType> are 'GPS' and 'Wifi'.

C<timeStamp> is epoch time with milliseconds, divide by 1000 for standard time
with milliseconds.

=head1 AUTHOR

Mike Greb E<lt>michael@thegrebs.comE<gt>

=head1 COPYRIGHT

Copyright 2013- Mike Greb

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
