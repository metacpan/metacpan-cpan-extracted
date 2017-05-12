#!/usr/bin/perl

use strict;
use warnings;

=head1 NAME

 doc_submit.pl

=head1 SYNOPSIS

 doc_submit.pl --title='test document' --author_first='Harvey'
    --author_last='Mudd' --filename='my_file.txt' --folder_id=45
    --non_blocking_upload=1

 doc_submit.pl --help

 doc_submit.pl --man

=head1 DESCRIPTION

This short example program shows how to us the WebService::iThenticate libraries to
submit a document to the iThenticate service.
 
=cut

use Getopt::Long;
use Pod::Usage;

my ( $title, $author_first, $author_last, $filename, $folder_id, $non_blocking_upload );
my ( $help, $man );

pod2usage( 1 ) unless @ARGV;
GetOptions(
    'title=s'               => \$title,
    'author_first=s'        => \$author_first,
    'author_last=s'         => \$author_last,
    'filename=s'            => \$filename,
    'folder_id=i'           => \$folder_id,
    'non_blocking_upload=i' => \$non_blocking_upload,
    'man'                   => \$man,
    'help'                  => \$help,
) or pod2usage( 2 );


pod2usage( 1 ) if $help;
pod2usage( -verbose => 2 ) if $man;

die "$filename is not a file\n" unless -f $filename;

use WebService::iThenticate::Client;
use Data::Dumper;

my %args = (
    username => $ENV{IT_USERNAME},
    password => $ENV{IT_PASSWORD},
    url      => $ENV{IT_API_URL} || 'https://api.ithenticate.com/rpc',
);

print "logging in...\n";
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

print "logged in ok, uploading file $filename...\n";

my $fh;
open( $fh, '<', $filename ) or die $!;
my $file_content = do { local $/; <$fh> };    # slurp the file
close( $fh );

# upload the document
$response = eval { $client->add_document( {
            title               => $title,
            author_first        => $author_first,
            author_last         => $author_last,
            filename            => $filename,
            folder              => $folder_id,
            submit_to           => 1,               # 1 => ’Generate Report Only’
            non_blocking_upload => 1,
            upload              => $file_content,
} ) };

die $@ if $@;

die 'Errors in response: ' . Dumper( $response->errors ) . "\n" if $response->errors;

print 'Response is: ' . Dumper( $response ) . "\n";

# 3 newline break
print "\n" x 3;

print 'Response XML data: ' . $response->as_xml;

print "\n" x 3;

print "file $filename uploaded successfully\n";
