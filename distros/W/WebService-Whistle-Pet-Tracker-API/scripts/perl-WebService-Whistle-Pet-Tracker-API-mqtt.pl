#!/usr/bin/perl
use strict;
use warnings;
use File::Basename qw{basename};
use Getopt::Std qw{getopts};
use Tie::IxHash qw{};
use JSON::XS qw{encode_json};
use Time::HiRes qw{};
use WebService::Whistle::Pet::Tracker::API qw{};
require Net::MQTT::Simple; #skip import

my $basename = basename($0);
my $syntax   = "$basename -h MQTT_HOST -e WHISTLE_EMAIL -p WHISTLE_PASSWORD #or from environment\n";
my $opt      = {};

getopts('e:p:h:', $opt);

my $host     = $opt->{'h'} || $ENV{'MQTT_HOST'}        || 'mqtt';
my $email    = $opt->{'e'} || $ENV{'WHISTLE_EMAIL'}    or die($syntax);
my $password = $opt->{'p'} || $ENV{'WHISTLE_PASSWORD'} or die($syntax);

my $timer    = Time::HiRes::time;
my $mqtt     = Net::MQTT::Simple->new($host);
{
  #Net::MQTT::Simple warns on connection error but we want die
  local $0               = 'MQTT';
  local $SIG{'__WARN__'} = sub {my $error = shift; die "Error: $error"};
  $mqtt->_connect;
}

my $ws       = WebService::Whistle::Pet::Tracker::API->new(email=>$email, password=>$password);
my $url      = $WebService::Whistle::Pet::Tracker::API::API_URL;
my $pets     = $ws->pets;
my $count    = 0;

foreach my $pet (@$pets) {
  my $topic = "stat/whistle-pet-tracker/pet/". $pet->{'id'};

  tie my %location, 'Tie::IxHash', (
                                    lat => $pet->{'last_location'}->{'latitude'},
                                    lon => $pet->{'last_location'}->{'longitude'},
                                    t   => $pet->{'last_location'}->{'timestamp'},
                                   );

  $count++ if $mqtt->publish("$topic/name"                  => $pet->{'name'}                       );
  $count++ if $mqtt->publish("$topic/last_location"         => encode_json(\%location)              );
  $count++ if $mqtt->publish("$topic/device/battery_level"  => $pet->{'device'}->{'battery_level'}  );
  $count++ if $mqtt->publish("$topic/device/battery_status" => $pet->{'device'}->{'battery_status'} );
}

$mqtt->tick(0.1);
$mqtt->disconnect;

$timer = Time::HiRes::time - $timer;
printf "Finished: Whistle: %s, MQTT: %s, Messages: %s, Time: %0.1f ms\n", $url, $host, $count, $timer * 1000;

__END__

=head1 NAME

perl-WebService-Whistle-Pet-Tracker-API-mqtt.pl - Publish Whistle Pet Tracker pet data to MQTT

=head1 SYNOPSIS

  perl-WebService-Whistle-Pet-Tracker-API-mqtt.pl -h MQTT_HOST -e WHISTLE_EMAIL -p WHISTLE_PASSWORD 

or

  export MQTT_HOST=mqtt
  export WHISTLE_EMAIL=my_email@example.com
  export WHISTLE_PASSWORD=my_password
  perl-WebService-Whistle-Pet-Tracker-API-mqtt.pl

=head1 DESCRIPTION

perl-WebService-Whistle-Pet-Tracker-API-mqtt.pl is a command line utility which connects to the configured MQTT broker and publishes pet data from the Whistle Pet Tracker API.

Topics:

  stat/whistle-pet-tracker/pet/123456789/name Rocky
  stat/whistle-pet-tracker/pet/123456789/last_location {"lat":38.88955018465634,"lon":-77.03530017768242,"t":"2023-04-23T13:55:01Z"}
  stat/whistle-pet-tracker/pet/123456789/device/battery_level 78
  stat/whistle-pet-tracker/pet/123456789/device/battery_status on

=head1 OPTIONS

-h Specifies the MQTT broker host name to which to connect and publish (default: mqtt)

-e Specifies the Whistle account name to use for authentication

-p Specifies the Whistle account password to use for authentication

=head1 CONFIGURATION

This distribution contains systemd configuration files which are not preconfigured.  Please use the systemd edit command to configure your credentials.

  sudo systemctl edit   perl-WebService-Whistle-Pet-Tracker-API-mqtt
  sudo systemctl enable perl-WebService-Whistle-Pet-Tracker-API-mqtt
  sudo systemctl start  perl-WebService-Whistle-Pet-Tracker-API-mqtt

=head1 TODO

Publish more data elements


=cut
