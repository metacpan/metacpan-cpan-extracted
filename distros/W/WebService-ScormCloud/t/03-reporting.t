#!perl -T

use strict;
use warnings;

use File::Spec;
use Test::More tests => 18;

use lib File::Spec->curdir;
require File::Spec->catfile('t', '_test_util.pl');

my ($ScormCloud, $skip_live_tests) = getScormCloudObject();

diag 'Live tests will be skipped' if $skip_live_tests;

can_ok($ScormCloud, 'getAccountInfo');

SKIP:
{
    skip 'Skipping live tests', 17 if $skip_live_tests;

    my $account_info = $ScormCloud->getAccountInfo;

    isa_ok($account_info, 'HASH', '$ScormCloud->getAccountInfo');

    my %expected = (
                    accounttype => '',
                    company     => '',
                    email       => '',
                    firstname   => '',
                    lastname    => '',
                    usage       => 'HASH',
                   );

    foreach my $key (sort keys %expected)
    {
        my $msg1 = "\$ScormCloud->getAccountInfo includes $key";
        my $msg2 = "ref(\$ScormCloud->getAccountInfo->{$key})";

        if (exists $account_info->{$key})
        {
            pass($msg1);
            is(ref($account_info->{$key}), $expected{$key}, $msg2);
        }
        else
        {
            fail($msg1);
            fail($msg2);
        }
    }

    my $usage = $account_info->{usage};

    foreach my $key (qw(totalcourses totalregistrations))
    {
        my $msg1 = "\$ScormCloud->getAccountInfo->{usage} includes $key";
        my $msg2 = "\$ScormCloud->getAccountInfo->{usage}->{$key} is numeric";

        if (exists $usage->{$key})
        {
            pass($msg1);
            like($usage->{$key}, qr/^\d+$/, $msg2);
        }
        else
        {
            fail($msg1);
            fail($msg2);
        }
    }
}

