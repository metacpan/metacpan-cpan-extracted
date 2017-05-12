#!/usr/bin/perl -Ilib/ -I../lib/
#
# Test that we can create/delete/lookup zones, and that the caching
# works as expected.
#

use strict;
use warnings;

use DB_File;
use File::Temp qw/ tempfile /;
use Test::More qw! no_plan !;

$ENV{ 'PERL_LWP_SSL_VERIFY_HOSTNAME' } = 0;

#
#  Load the module.
#
BEGIN {use_ok('WebService::Amazon::Route53::Caching');}
require_ok('WebService::Amazon::Route53::Caching');

#
# Gain access to the Amazon credentials from the environment.
#
my $AWS_ID  = $ENV{ 'AWS_ID' }  || "";
my $AWS_KEY = $ENV{ 'AWS_KEY' } || "";

#
#  Should we skip this testing?
#
my $skip = 0;
$skip = 1 if ( !length($AWS_KEY) || !length($AWS_ID) );


SKIP:
{
    skip "We don't have the AWS credentials in the environment"
      unless ( !$skip );

    #
    #  Create a tempory file for our cache-store.
    #
    my ( $fh, $file ) = tempfile();
    ok( -e $file, "We created a temporary file for our cache: $file" );


    #
    #  Create the object.
    #
    my $aws =
      WebService::Amazon::Route53::Caching->new( id   => $AWS_ID,
                                                 key  => $AWS_KEY,
                                                 path => $file
                                               );

    isa_ok( $aws,
            "WebService::Amazon::Route53::Caching",
            "The object has the correct type" );


    #
    #  We're going to operate on some stub domains
    #
    my @domains;
    push( @domains, "aws-test-zone-$$.com" );
    push( @domains, "aws-test-zone-$$.org" );

    foreach my $zone (@domains)
    {

        #
        #  Ensure the domain doesn't exist.
        #
        my $id = $aws->find_hosted_zone( name => $zone );
        ok( !$id, "Failed to find a zone before it was created " );

        #
        #  Now create the zone.
        #
        my $created =
          $aws->create_hosted_zone( name             => $zone,
                                    caller_reference => $zone . "_01" );

        ok( $created, "The zone was created" );

        #
        #  The creation should result in a zone ID.
        #
        my $zone_id = $created->{ 'zone' }->{ 'id' };
        $zone_id =~ s/\/hostedzone\///g;
        ok( defined($zone_id), "A newly created zone has an ID: $zone_id" );

        #
        #  Lookup the ID of the newly created zone
        #
        $id = $aws->find_hosted_zone( name => $zone );
        my $zone_id2 = $id->{ 'zone' }->{ 'id' };
        $zone_id2 =~ s/\/hostedzone\///g;

        #
        #  Ensure the two zone IDs match.
        #
        is( $zone_id2, $zone_id, "Found the zone post-create" );

        #
        #  Now delete the newly-created zone, via the ID.
        #
        $aws->delete_hosted_zone( zone_id => $zone_id );

        #
        # At this point lookups should fail once more.
        #
        $id = $aws->find_hosted_zone( name => $zone );
        is( $id, 0, "We shouldn't find a zone once it is deleted " );


        #
        #  At this point our backing-store should contain no keys
        # and no values.
        #
        my %h;
        tie %h, "DB_File", $file, O_RDWR | O_CREAT, 0666, $DB_HASH or
          die "Failed to tie";
        is( scalar( keys( %h ) ), 0, "Post-deletion the cache is empty" );
        untie( %h );

        unlink($file) if ( -e $file );
    }

}
