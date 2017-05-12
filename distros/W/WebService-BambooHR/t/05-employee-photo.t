#!perl

use strict;
use warnings;
use utf8;

use LWP::Online ':skip_all';
use Test::More 0.88 tests => 4;
use WebService::BambooHR;
my $domain  = 'testperl';
my $api_key = 'bfb359256c9d9e26b37309420f478f03ec74599b';
my $bamboo;
my @changes;
my $photo;
my $expected_photo;

# David Bagley
my $EMPLOYEE_ID = 11634;

SKIP: {

    my $bamboo = WebService::BambooHR->new(
                        company => $domain,
                        api_key => $api_key);
    ok(defined($bamboo), "instantiate BambooHR class");

    eval {
        $photo = $bamboo->employee_photo($EMPLOYEE_ID);
    };
    ok(!$@ && defined($photo), 'get employee photo');

    $expected_photo = read_employee_photo($EMPLOYEE_ID);

    ok(defined($expected_photo), 'get expected employee photo');

    ok($expected_photo eq $photo, "compare photos");

};

sub read_employee_photo
{
    my $employee_id = shift;
    my $filename    = "t/data/photo-$employee_id.jpg";
    my $fh;
    local $/;
    my $bytes;

    open($fh, '<', $filename) || return undef;
    $bytes = <$fh>;
    close($fh);

    return $bytes;
}

