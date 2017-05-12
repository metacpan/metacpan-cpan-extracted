#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
use Data::Dumper;

BEGIN { plan tests => 2 };
use Treemap;
ok(1); # If we made it this far, we're ok.

if ( 0 )
{

$tm = Treemap->new();
ok(1);

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

# Test Data
my $sample_data;
$sample_data->{name} = "root";
$sample_data->{size} = 12;
$sample_data->{colour} = "#FFFFFF";
$sample_data->{children}->[0]->{name} = "one";
$sample_data->{children}->[0]->{size} = 4;
$sample_data->{children}->[0]->{colour} = "#FFFFFF";
$sample_data->{children}->[1]->{name} = "two";
$sample_data->{children}->[1]->{size} = 3;
$sample_data->{children}->[1]->{colour} = "#FFFFFF";
$sample_data->{children}->[1]->{children}->[0]->{name} = "red";
$sample_data->{children}->[1]->{children}->[0]->{size} = 1;
$sample_data->{children}->[1]->{children}->[0]->{colour} = "#FFFFFF";
$sample_data->{children}->[1]->{children}->[1]->{name} = "green";
$sample_data->{children}->[1]->{children}->[1]->{size} = 2;
$sample_data->{children}->[1]->{children}->[1]->{colour} = "#FFFFFF";
$sample_data->{children}->[2]->{name} = "three";
$sample_data->{children}->[2]->{size} = 5;
$sample_data->{children}->[2]->{colour} = "#FFFFFF";

$tm->slice_process( $sample_data, 0, 0, 1023, 767 );

ok(1);
}

use Treemap::Data::Dir;
$data = Treemap::Data::Dir->new();
ok( $data->load( "./functions/" ) );

print Dumper( $data->{ DATA } );

use Treemap::Squarified;
$tm2 = Treemap::Squarified->new();
ok( $tm );

$tm2->map( $data->{ DATA }, 0, 0, 1023, 767 );
ok(1);
