use strict;
use warnings;

use Data::Dump 'pp';
use Test::More;
use WebService::Moodle::Simple;

unless (
    $ENV{TEST_WSMS_SCHEME} &&
    $ENV{TEST_WSMS_DOMAIN} &&
    $ENV{TEST_WSMS_PORT} &&
    $ENV{TEST_WSMS_TARGET} &&
    $ENV{TEST_WSMS_TOKEN} &&
    $ENV{TEST_WSMS_COURSE}
    ) {

    plan skip_all => '

Not running live tests. To enable this test set environment variables:

* TEST_WSMS_SCHEME    - http or https
* TEST_WSMS_DOMAIN    - the moodle server
* TEST_WSMS_PORT      - the port (443 / HTTPS by default)
* TEST_WSMS_TARGET    - The name of the moodle webservice
* TEST_WSMS_TOKEN     - the token for accessing TEST_WSMS_TARGET
* TEST_WSMS_COURSE    - the course in which to enrol the test student

WARNING: This test will modify the database of the Moodle server

';

}




my $moodle = WebService::Moodle::Simple->new(
    scheme   =>  $ENV{TEST_WSMS_SCHEME},
    domain   =>  $ENV{TEST_WSMS_DOMAIN},
    port     =>  $ENV{TEST_WSMS_PORT},
    target   =>  $ENV{TEST_WSMS_TARGET},
    token    =>  $ENV{TEST_WSMS_TOKEN},
);

is(ref($moodle), 'WebService::Moodle::Simple');

my $username;


subtest 'add_user, get_user, check_password, set_password' => sub {
    $username = 'test_'.time(); my $password = 'test_pwd';

    {
        my $resp = $moodle->add_user(
            firstname => 'Test',
            lastname  => 'User',
            email     => $username.'@example.com',
            username  => $username,
            password  => $password,
        );
        ok $resp->{ok}, 'add_user succeeded in adding a user';
        ok $resp->{id} && $resp->{username}, 'add_user retrieved id and username';

        my $user = $moodle->get_user( username => $username );
        is $user->{username}, $username, 'get_user returns a user with the correct username';
    }


    {
        my $resp = $moodle->add_user(
            firstname => 'Test',
            lastname  => 'User',
            email     => $username.'@example.com',
            username  => $username,
            password  => $password,
        );
        ok ! $resp->{ok}, 'add_user failed to add a user twice';
    }

    {
        my $resp = $moodle->check_password(
            username  => $username,
            password  => $password,
        );
        ok $resp->{ok}, 'check_password passed the correct passord';

        my $newpassword = $password."foo";
        $resp = $moodle->check_password(
            username  => $username,
            password  => $newpassword,
        );
        ok !$resp->{ok}, 'check_password failed the new passord';

        $resp = $moodle->set_password(
            username  => $username,
            password  => $newpassword,
        );

        ok $resp->{ok}, 'set_password succeeded in setting the new password';

        $resp = $moodle->check_password(
            username  => $username,
            password  => $newpassword,
        );
        ok $resp->{ok}, 'check_password passes the new passord';
    }


};

subtest 'suspend_user' => sub {
    my $user = $moodle->get_user( username => $username );
    ok ! $user->{suspended}, 'get_user shows that the user has not been suspended';
    $moodle->suspend_user( username => $username );
    $user = $moodle->get_user( username => $username );
    ok $user->{suspended}, 'get_user shows that the user has been suspended';
    $moodle->suspend_user( username => $username, suspend => 0 );
    $user = $moodle->get_user( username => $username );
    ok ! $user->{suspended}, 'get_user shows that the user has been unsuspended';
};

subtest 'get_course_id, enrol_student' => sub {

    my $course_id = $moodle->get_course_id(
        short_cname => $ENV{TEST_WSMS_COURSE},
    );

    ok $course_id, "get_course_id returned a course id";

    my $enrol_resp = $moodle->enrol_student(
        username => $username,
        course   => $ENV{TEST_WSMS_COURSE},
    );
    ok $enrol_resp->{ok}, 'enrol_student succeeded in enrolling student - '.$enrol_resp->{msg};

    $enrol_resp = $moodle->enrol_student(
        username => $username.'foo',
        course   => $ENV{TEST_WSMS_COURSE},
    );
    ok ! $enrol_resp->{ok}, 'enrol_student failed in enrolling non-student - '.$enrol_resp->{msg};
note pp($enrol_resp);

};




done_testing();


