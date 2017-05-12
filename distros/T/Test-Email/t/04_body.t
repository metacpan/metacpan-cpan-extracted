#!perl
use strict;
use warnings FATAL => 'all';

use Data::Dumper;
use Mail::Sendmail;
use Test::More tests => 9;
BEGIN { use_ok('Test::POP3') };

#########################

my $pc = 1;
my ($host, $user, $pass, $smtp, $email) = get_info();

SKIP: {
    skip 'No POP3 settings found', 9 unless $host;
    my $test = Test::POP3->new({
        host    =>  $host,
        user    =>  $user,
        pass    =>  $pass,
    });

    # no tmpfiles
    my $parser = $test->get_parser();
    $parser->output_to_core(1);

    # no messages
    $test->delete_all();
    my $msg_count = $test->get_email_count(1);
    is($msg_count, 0, 'no messages');

    # send 3 messages
    sendmail(
        to      =>  $email,
        from    =>  $email,
        subject =>  'test 1',
        message =>  'message 1',
        smtp    =>  $smtp,
    );
    sendmail(
        to      =>  $email,
        from    =>  $email,
        subject =>  'test 2',
        message =>  'message 2',
        smtp    =>  $smtp,
    );
    sendmail(
        to      =>  $email,
        from    =>  $email,
        subject =>  'test 3',
        message =>  'message 3',
        smtp    =>  $smtp,
    );

    # then wait for them
    is($test->wait_for_email_count(3), 3, 'found 3 messages');

    # fail a single test
    ok(!$test->_run_tests({
        body => qr/4/,
    }, 'should not see this'), 'one wrong arg fails');

    # fail part of a multiple test
    ok(!$test->_run_tests({
        body    =>  qr/5/,
        subject =>  'test 1',
    }, 'should not see this'), 'some wrong args fail');

    $test->ok({
        body => qr/2/,
    }, 'body regexp');

    $test->ok({
        body => 'message 3',
    }, 'body string');

    $test->ok({
        body    =>  qr/1/,
        subject =>  'test 1',
    }, 'body and subject');

    is($test->delete_all(), 0, 'no others to be deleted');
};

sub get_info {
    return map $ENV{"TEST_POP3_$_"}, map uc, qw(host user pass smtp email);
}

__END__

