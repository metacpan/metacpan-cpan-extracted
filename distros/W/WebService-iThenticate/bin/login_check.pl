#!/usr/bin/perl

use strict;
use warnings;

=head1 NAME

 login_check.pl

=head1 SYNOPSIS

 # set env IT_USERNAME, IT_PASSWORD, IT_API_URL
 login_check.pl

=head1 DESCRIPTION

Checks the environment variables IT_USERNAME and IT_PASSWORD against the
environment at IT_API_URL for successful authentication. Use this to test your
login credentials.

=cut

use Getopt::Long;
use Pod::Usage;

my ( $help, $man );

GetOptions(
    'man'  => \$man,
    'help' => \$help,
);

pod2usage( 1 ) if $help;
pod2usage( -verbose => 2 ) if $man;

pod2usage( 2 ) unless
    $ENV{IT_USERNAME} && $ENV{IT_PASSWORD} && $ENV{IT_API_URL};

use WebService::iThenticate::Client;
use Data::Dumper;

my %args = (
    username => $ENV{IT_USERNAME},
    password => $ENV{IT_PASSWORD},
    url      => $ENV{IT_API_URL},

);

my $client = WebService::iThenticate::Client->new( \%args );
my $response;
eval { $response = $client->login };

# first stage error checking - look for an exception
die "Error: $@\n" if $@;

# second stage error checking - look for errors in errors field
if ( $response->errors ) {

    die 'Login error: ' . Dumper( $response->errors ) . "\n";

} elsif ( my @messages = $response->messages ) {

    # third stage - messages on login means there were problems
    die 'login error:  ' . Dumper( $response->messages );

} else {

    print "Login successful\n";
}

