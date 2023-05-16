#!/usr/bin/perl
use strict;
use warnings;
use File::Basename qw{basename};
use Getopt::Std qw{getopts};
use JSON::XS qw{};
use WebService::Whistle::Pet::Tracker::API qw{};

my $basename = basename($0);
my $syntax   = "$basename -e WHISTLE_EMAIL -p WHISTLE_PASSWORD device [device [...]]\n";
my $opt      = {};

getopts('e:p:', $opt);

my $email    = $opt->{'e'} || $ENV{'WHISTLE_EMAIL'}    or die($syntax);
my $password = $opt->{'p'} || $ENV{'WHISTLE_PASSWORD'} or die($syntax);
die($syntax) unless @ARGV;

my $ws       = WebService::Whistle::Pet::Tracker::API->new(email=>$email, password=>$password);
my $json     = JSON::XS->new->pretty;

foreach my $argv (@ARGV) {
  my $device = $ws->device($argv);
  print $json->encode($device);
}

__END__

=head1 NAME

perl-WebService-Whistle-Pet-Tracker-API-device.pl - Get Whistle Pet Tracker device data

=head1 SYNOPSIS

  perl-WebService-Whistle-Pet-Tracker-API-device.pl -e WHISTLE_EMAIL -p WHISTLE_PASSWORD 

or

  export WHISTLE_EMAIL=my_email@example.com
  export WHISTLE_PASSWORD=my_password
  perl-WebService-Whistle-Pet-Tracker-API-device.pl

=head1 DESCRIPTION

perl-WebService-Whistle-Pet-Tracker-API-device.pl is a command line utility which gets device data from the Whistle Pet Tracker API.

=head1 OPTIONS

-e Specifies the Whistle account name to use for authentication

-p Specifies the Whistle account password to use for authentication

=cut
