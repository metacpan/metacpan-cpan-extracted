#!perl -T

use strict;
use warnings;

use File::Spec;
use Test::More tests => 13;

use lib File::Spec->curdir;
require File::Spec->catfile('t', '_test_util.pl');

my ($ScormCloud, $skip_live_tests) = getScormCloudObject();

diag 'Live tests will be skipped' if $skip_live_tests;

can_ok($ScormCloud, 'getCourseList');
can_ok($ScormCloud, 'courseExists');
can_ok($ScormCloud, 'getMetadata');

SKIP:
{
    skip 'Skipping live tests', 10 if $skip_live_tests;

    my $course_list;

    $course_list = $ScormCloud->getCourseList({filter => 'i do not exist'});
    isa_ok($course_list, 'ARRAY', '$ScormCloud->getCourseList');
    is(scalar(@{$course_list}), 0, '$ScormCloud->getCourseList empty');

    $course_list = $ScormCloud->getCourseList;

    isa_ok($course_list, 'ARRAY', '$ScormCloud->getCourseList');

    ##########

    is($ScormCloud->courseExists('i do not exist'),
        0, '$ScormCloud->courseExists');

  SKIP:
    {
        skip 'No courses exist for further testing', 6
          unless @{$course_list} > 0;

        my $course_id = $course_list->[0]->{id};
        is($ScormCloud->courseExists($course_id),
            1, '$ScormCloud->courseExists');

        my $metadata = $ScormCloud->getMetadata($course_id);
        isa_ok($metadata, 'HASH', '$ScormCloud->getMetadata');

        my %expected = (
                        metadata => 'HASH',
                        object   => 'HASH',
                       );

        foreach my $key (sort keys %expected)
        {
            my $msg1 = "\$ScormCloud->getMetadata includes $key";
            my $msg2 = "ref(\$ScormCloud->getMetadata->{$key})";

            if (exists $metadata->{$key})
            {
                pass($msg1);
                is(ref($metadata->{$key}), $expected{$key}, $msg2);
            }
            else
            {
                fail($msg1);
                fail($msg2);
            }
        }
    }
}

