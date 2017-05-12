#!/usr/bin/perl

use strict;
use warnings;

=head1 NAME

 folder_list.pl

=head1 SYNOPSIS

 folder_list.pl --help

 folder_list.pl --man

=head1 DESCRIPTION

This short example program shows how to us the WebService::iThenticate libraries to
get a report for a particular document section.
 
=cut

use Getopt::Long;
use Pod::Usage;

my ( $help, $man );

GetOptions(
    'man'  => \$man,
    'help' => \$help,
) or pod2usage( 2 );


pod2usage( 1 ) if $help;
pod2usage( -verbose => 2 ) if $man;


use WebService::iThenticate::Client;
use Data::Dumper;

my %args = (
    username => $ENV{IT_USERNAME},
    password => $ENV{IT_PASSWORD},
    url      => 'https://api.ithenticate.com/rpc',
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
}

# check the document status
$response = $client->list_folders;

die 'Errors in response: ' . Dumper( $response->errors ) . "\n" if $response->errors;

print 'Folders: ' . Dumper( $response->folders ) . "\n";

# 3 newline break
print "\n" x 3;

print 'Response XML data: ' . $response->as_xml . "\n";

