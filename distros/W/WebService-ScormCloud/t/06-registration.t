#!perl -T

use strict;
use warnings;

use File::Spec;
use Test::More tests => 35;

use lib File::Spec->curdir;
require File::Spec->catfile('t', '_test_util.pl');

my ($ScormCloud, $skip_live_tests) = getScormCloudObject();

diag 'Live tests will be skipped' if $skip_live_tests;

can_ok($ScormCloud, 'getRegistrationList');
can_ok($ScormCloud, 'createRegistration');
can_ok($ScormCloud, 'resetGlobalObjectives');
can_ok($ScormCloud, 'resetRegistration');
can_ok($ScormCloud, 'deleteRegistration');
can_ok($ScormCloud, 'getRegistrationResult');
can_ok($ScormCloud, 'launchURL');

SKIP:
{
    skip 'Skipping live tests', 28 if $skip_live_tests;

    my $bogus_registration_id1 =
      'BOGUS_REGISTRATION_ID_FOR_TESTING_ONLY_1_' . $$;
    my $bogus_registration_id2 =
      'BOGUS_REGISTRATION_ID_FOR_TESTING_ONLY_2_' . $$;
    my $bogus_first_name = 'Fake';
    my $bogus_last_name  = 'User';
    my $bogus_learner_id = 'BOGUS_LEARNER_ID_FOR_TESTING_ONLY';

##########

    my $registration_list;

    $registration_list =
      $ScormCloud->getRegistrationList({filter => 'i do not exist'});
    isa_ok($registration_list, 'ARRAY', '$ScormCloud->getRegistrationList');
    is(scalar(@{$registration_list}),
        0, '$ScormCloud->getRegistrationList empty');

    $registration_list =
      $ScormCloud->getRegistrationList({coursefilter => 'i do not exist'});
    isa_ok($registration_list, 'ARRAY', '$ScormCloud->getRegistrationList');
    is(scalar(@{$registration_list}),
        0, '$ScormCloud->getRegistrationList empty');

    $registration_list = $ScormCloud->getRegistrationList;
    isa_ok($registration_list, 'ARRAY', '$ScormCloud->getRegistrationList');

    # If any registrations already exists, check if any of them are for
    # testing only, and delete if so:
    #
    foreach my $registration (@{$registration_list})
    {
        my $registration_id = $registration->{id};
        if ($registration_id =~ /^BOGUS_REGISTRATION_ID_FOR_TESTING_ONLY/)
        {
            $ScormCloud->deleteRegistration($registration_id);
        }
    }

    my $course_list = $ScormCloud->getCourseList;

  SKIP:
    {
        skip 'No courses exist for create/reset/delete testing', 7
          unless @{$course_list} > 0;

        my $course_id = $course_list->[0]->{id};

        ok(
            $ScormCloud->createRegistration(
                                     $course_id,        $bogus_registration_id1,
                                     $bogus_first_name, $bogus_last_name,
                                     $bogus_learner_id
                                           ),
            'createRegistration'
          );

        ok($ScormCloud->resetGlobalObjectives($bogus_registration_id1),
            'resetGlobalObjectives');

        ok($ScormCloud->resetRegistration($bogus_registration_id1),
            'resetRegistration');

        ok($ScormCloud->deleteRegistration($bogus_registration_id1),
            'deleteRegistration');

        # Create a different bogus registration for list testing:
        #
        # Note: Tried to use the same ID, but apparently there is some
        # caching going on such that if you try to create a registration
        # using the same ID of one you just deleted, it complains that
        # the deleted registration still exists...
        #
        $ScormCloud->createRegistration(
                                        $course_id,
                                        $bogus_registration_id2,
                                        $bogus_first_name,
                                        $bogus_last_name,
                                        $bogus_learner_id
                                       );
    }

    $registration_list = $ScormCloud->getRegistrationList;    # refresh the list

    {
        skip 'No registrations exist for further testing', 14
          unless @{$registration_list} > 0;

        # Use bogus registration if we have one, otherwise just grab
        # first in list:
        #
        my ($registration) =
          grep { $_->{id} eq $bogus_registration_id2 } @{$registration_list};
        $registration ||= $registration_list->[0];

        my $registration_id = $registration->{id};

        my $url = $ScormCloud->launchURL($registration_id, 'closer') || '';
        my $service_url = $ScormCloud->service_url;
        like($url, qr{^$service_url[?]}, 'launchURL matches service URL');
        like($url,
             qr{\bmethod=rustici.registration.launch\b},
             'launchURL contains method');
        like($url, qr{\bregid=$registration_id\b}, 'launchURL contains regid');
        like($url, qr{\bsig=[a-f0-9]+\b},          'launchURL contains sig');
        like($url, qr{\bredirecturl=closer\b},
             'launchURL contains redirecturl');

        my $result = $ScormCloud->getRegistrationResult($registration_id);
        isa_ok($result, 'HASH', '$ScormCloud->getRegistrationResult');

        my %expected = (
                        complete => '',
                        score    => '',
                        success  => '',
                       );

        foreach my $key (sort keys %expected)
        {
            my $msg1 = "\$ScormCloud->getRegistrationResult includes $key";
            my $msg2 = "ref(\$ScormCloud->getRegistrationResult->{$key})";

            if (exists $result->{$key})
            {
                pass($msg1);
                is(ref($result->{$key}), $expected{$key}, $msg2);
            }
            else
            {
                fail($msg1);
                fail($msg2);
            }
        }

        $result = $ScormCloud->getRegistrationResult($registration_id, 'full');
        isa_ok($result, 'HASH', '$ScormCloud->getRegistrationResult');

        %expected = (
                     activity => 'ARRAY',
                     format   => '',
                     regid    => '',
                    );

        foreach my $key (sort keys %expected)
        {
            my $msg1 = "\$ScormCloud->getRegistrationResult includes $key";
            my $msg2 = "ref(\$ScormCloud->getRegistrationResult->{$key})";

            if (exists $result->{$key})
            {
                pass($msg1);
                is(ref($result->{$key}), $expected{$key}, $msg2);
            }
            else
            {
                fail($msg1);
                fail($msg2);
            }
        }
    }

    # Clean up any test registrations:
    #
    $registration_list = $ScormCloud->getRegistrationList(
                        {filter => 'BOGUS_REGISTRATION_ID_FOR_TESTING_ONLY.*'});
    foreach my $bogus_registration (@{$registration_list})
    {
        $ScormCloud->deleteRegistration($bogus_registration->{id});
    }
}

