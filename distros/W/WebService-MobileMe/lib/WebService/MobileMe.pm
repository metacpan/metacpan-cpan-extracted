package WebService::MobileMe;

# ABSTRACT: access MobileMe iPhone stuffs from Perl

use strict;
use warnings;

use JSON 2.00;
use LWP::UserAgent;
use MIME::Base64;
use Data::Dumper;

our $VERSION = '0.007';

my %headers = (
    'X-Apple-Find-Api-Ver'  => '2.0',
    'X-Apple-Authscheme'    => 'UserIdGuest',
    'X-Apple-Realm-Support' => '1.0',
    'Content-Type'          => 'application/json; charset=utf-8',
    'Accept-Language'       => 'en-us',
    'Pragma'                => 'no-cache',
    'Connection'            => 'keep-alive',
);

my $default_uuid      = '0000000000000000000000000000000000000000';
my $default_name      = 'My iPhone';
my $base_url          = 'https://fmipmobile.icloud.com/fmipservice/device/';
my $fmi_app_version   = '1.2.1';
my $fmi_build_version = '145';
my $fmi_os_version    = '4.2.1';

sub new {
    my ( $class, %args ) = @_;
    my $self = {};
    bless $self, $class;

    $self->{debug} = $args{debug} || 0;

    $self->{ua} = LWP::UserAgent->new(
        agent => 'Find iPhone/1.1 MeKit (iPhone: iPhone OS/4.2.1)',
        autocheck => 0,
    );

    $self->{ua}->default_header( 'Authorization' => 'Basic '
            . encode_base64( $args{username} . ':' . $args{password} ) );

    while (my ($header, $value) = each %headers) {
        $self->{ua}->default_header( $header => $value);
    }

    if ( defined( $args{uuid} && $args{device_name} ) ) {
        $self->{uuid}        = $args{uuid};
        $self->{device_name} = $args{device_name};
    }
    else {
        $self->{uuid}        = $default_uuid;
        $self->{device_name} = $default_name;
    }

    $self->{ua}->default_header( 'X-Client-Uuid' => $self->{uuid} );
    $self->{ua}->default_header( 'X-Client-Name' => $self->{device_name} );

    $self->{base_url} = $base_url . $args{username};

    $self->update();

    return $self;

}

sub locate {
    my $self = shift;
    $self->update();
    my $device = $self->device(shift);
    die "Don't have location for device" unless exists $device->{location};
    return $device->{location}
}

sub device {
    my $self = shift;
    my $device_number = shift || 0;
    my $device = $self->{devices}[$device_number];
    die "Didn't find specified device number ( $device_number )" unless $device;
    return $device

}

sub sendMessage {
    my ($self, %args) = @_;
    $args{subject} ||= 'Important Message';
    $args{alarm} = $args{alarm} ? 'true' : 'false';
    die "Must specify message." unless $args{message};
    my $device = $self->device( $args{device} );
    my $post_content = sprintf(qq|{"clientContext":{"appName":"FindMyiPhone","appVersion":"$fmi_app_version","buildVersion":"$fmi_build_version","deviceUDID":"0000000000000000000000000000000000000000","inactiveTime":5911,"osVersion":"$fmi_os_version","productType":"iPad1,1","selectedDevice":"%s","shouldLocate":false},"device":"%s","serverContext":{"callbackIntervalInMS":3000,"clientId":"0000000000000000000000000000000000000000","deviceLoadStatus":"203","hasDevices":true,"lastSessionExtensionTime":null,"maxDeviceLoadTime":60000,"maxLocatingTime":90000,"preferredLanguage":"en","prefsUpdateTime":1276872996660,"sessionLifespan":900000,"timezone":{"currentOffset":-25200000,"previousOffset":-28800000,"previousTransition":1268560799999,"tzCurrentName":"Pacific Daylight Time","tzName":"America/Los_Angeles"},"validRegion":true},"sound":%s,"subject":"%s","text":"%s"}|,
        $device->{id}, $device->{id},
        $args{alarm}, $args{subject}, $args{message}
    );
    return from_json( $self->_post( '/sendMessage', $post_content )->content )->{msg};
}

sub remoteLock {
    my ($self, $passcode, $devicenum) = @_;
    die "Must specify passcode." unless $passcode;
    my $device = $self->device( $devicenum );
    my $post_content = sprintf(qq|{"clientContext":{"appName":"FindMyiPhone","appVersion":"$fmi_app_version","buildVersion":$fmi_build_version","deviceUDID":"0000000000000000000000000000000000000000","inactiveTime":5911,"osVersion":"$fmi_os_version","productType":"iPad1,1","selectedDevice":"%s","shouldLocate":false},"device":"%s","oldPasscode":"","passcode":"%s","serverContext":{"callbackIntervalInMS":3000,"clientId":"0000000000000000000000000000000000000000","deviceLoadStatus":"203","hasDevices":true,"lastSessionExtensionTime":null,"maxDeviceLoadTime":60000,"maxLocatingTime":90000,"preferredLanguage":"en","prefsUpdateTime":1276872996660,"sessionLifespan":900000,"timezone":{"currentOffset":-25200000,"previousOffset":-28800000,"previousTransition":1268560799999,"tzCurrentName":"Pacific Daylight Time","tzName":"America/Los_Angeles"},"validRegion":true}}|,
        $device->{id}, $device->{id}, $passcode
    );
    return from_json( $self->_post( '/remoteLock', $post_content )->content )->{remoteLock};
}

sub update {
    my $self = shift;
    my $response;

    my $post_content =
        qq|{"clientContext":{"appName":"FindMyiPhone","appVersion":"$fmi_app_version","buildVersion":"$fmi_build_version","deviceUDID":"|
        . $self->{uuid}
        . qq|","inactiveTime":2147483647,"osVersion":"$fmi_os_version","personID":0,"productType":"iPhone3,1"}}|;
    my $retry = 1;
    while ($retry) {
        $response = $self->_post( '/initClient', $post_content );
        if ($response->code == 330) {
            my $host = $response->headers->header('X-Apple-MME-Host');
            $self->_debug("Updating url to point to $host");
            $self->{base_url} =~ s|https://fmipmobile.icloud.com|https://$host|;
        }
        else {
            $retry = 0;
        }
    }
    if ($response->code != 200) {
        die "Failed to init, got " . $response->status_line;
    }

    my $data = from_json( $response->content );

    $self->{devices} = $data->{content};
    $self->_debug("In update, found " . scalar (@{$self->{devices}})  . " device(s)");

    return 1;
}

sub _debug {
    print STDERR $_[1] . "\n" if $_[0]->{debug};
}

sub _post {
    my $self = shift;
    return $self->{ua}->post( $self->{base_url} . $_[0], Content => $_[1] );
}

1;

__END__

=pod

=head1 NAME

WebService::MobileMe - deprecated use WebService::FindMyiPhone


=head1 DESCRIPTION

This module has been deprecated by L<WebService::FindMyiPhone>

=head1 AUTHOR

Mike Greb E<lt>michael@thegrebs.comE<gt>

=head1 COPYRIGHT

Copyright 2013- Mike Greb

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<WebService::FindMyiPhone>

=cut
