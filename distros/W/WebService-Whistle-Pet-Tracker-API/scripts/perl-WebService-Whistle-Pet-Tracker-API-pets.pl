#!/usr/bin/perl
use strict;
use warnings;
use File::Basename qw{basename};
use Getopt::Std qw{getopts};
use JSON::XS qw{};
use WebService::Whistle::Pet::Tracker::API qw{};

my $basename = basename($0);
my $syntax   = "$basename -e WHISTLE_EMAIL -p WHISTLE_PASSWORD #or from environment\n";
my $opt      = {};

getopts('e:p:', $opt);

my $email    = $opt->{'e'} || $ENV{'WHISTLE_EMAIL'}    or die($syntax);
my $password = $opt->{'p'} || $ENV{'WHISTLE_PASSWORD'} or die($syntax);

my $ws       = WebService::Whistle::Pet::Tracker::API->new(email=>$email, password=>$password);
my $json     = JSON::XS->new->pretty;
my $pets     = $ws->pets;

print $json->encode($pets);

__END__

=head1 NAME

perl-WebService-Whistle-Pet-Tracker-API-pets.pl - Get Whistle Pet Tracker pet data

=head1 SYNOPSIS

  perl-WebService-Whistle-Pet-Tracker-API-pets.pl -e WHISTLE_EMAIL -p WHISTLE_PASSWORD 

or

  export WHISTLE_EMAIL=my_email@example.com
  export WHISTLE_PASSWORD=my_password
  perl-WebService-Whistle-Pet-Tracker-API-pets.pl

=head1 DESCRIPTION

perl-WebService-Whistle-Pet-Tracker-API-pets.pl is a command line utility which gets pet data from the Whistle Pet Tracker API.

=head1 OPTIONS

-e Specifies the Whistle account name to use for authentication

-p Specifies the Whistle account password to use for authentication

=cut
