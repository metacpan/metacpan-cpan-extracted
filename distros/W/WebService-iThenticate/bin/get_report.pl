#!/usr/bin/perl

use strict;
use warnings;

=head1 NAME

 get_report.pl

=head1 SYNOPSIS

 doc_submit.pl --section_id=70

 doc_submit.pl --help

 doc_submit.pl --man

=head1 DESCRIPTION

This short example program shows how to us the WebService::iThenticate libraries to
get a report for a particular document section.
 
=cut

use Getopt::Long;
use Pod::Usage;

my $section_id;
my ( $help, $man );

pod2usage( 1 ) unless @ARGV;
GetOptions(
    'section_id=i' => \$section_id,
    'man'          => \$man,
    'help'         => \$help,
) or pod2usage( 2 );


pod2usage( 1 ) unless $section_id;
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
$response = $client->get_report( {
        id => $section_id,
} );

die 'Errors in response: ' . Dumper( $response->errors ) . "\n" if $response->errors;

print 'Report data: ' . Dumper( $response->report ) . "\n";

# 3 newline break
print "\n" x 3;

print 'Response XML data: ' . $response->as_xml . "\n";

