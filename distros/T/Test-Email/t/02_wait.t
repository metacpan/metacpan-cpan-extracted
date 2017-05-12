#!perl
use strict;
use warnings FATAL => 'all';

use Data::Dumper;
use Mail::Sendmail;
use Test::More tests => 5;
BEGIN { use_ok('Test::POP3') };

#########################

my ($host, $user, $pass, $smtp, $email) = get_info();


SKIP: {
    skip 'No POP3 settings found', 5 unless $host;

    my $pop3 = Test::POP3->new({
        host    =>  $host,
        user    =>  $user,
        pass    =>  $pass,
    });
    
    # no tmpfiles
    my $parser = $pop3->get_parser();
    $parser->output_to_core(1);
    
    # no messages
    $pop3->delete_all();
    my $msg_count = $pop3->get_email_count(0);
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
    is($pop3->wait_for_email_count(3,30), 3, 'waited for 3 messages');
    
    is($pop3->delete_all(), 3, 'deleted 3 messages');
    
    # then timeout waiting for a message that's not there
    is($pop3->wait_for_email_count(1,10), 0, 'timed out');
};

sub get_info {
    return map $ENV{"TEST_POP3_$_"}, map uc, qw(host user pass smtp email);
}

__END__

