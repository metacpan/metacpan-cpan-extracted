# -*- perl -*-

use strict;
use warnings;

use IO::Socket;
use Net::Server::Mail::ESMTP;
use Test::SMTP;
use Test::More;
use Test::Builder::Tester tests => 2;

my $LOCAL_PORT = ($ENV{'SMTP_SERVER_PORT'} || 2525) + 1;

#spawn off a server

    my $server;
    while(not defined $server && $LOCAL_PORT < 4000)
    {
        $server = new IO::Socket::INET(
            Listen => 1,
            LocalPort => ++$LOCAL_PORT
        );
    }

my $server_pid;

$server_pid = fork();

if ($server_pid == 0){
    # I'm the child process
    my $conn_number = 0;
    my $conn;
    while ($conn = $server->accept)
    {
        my $issue_an_error_on_quit = 0;
	my $issue_an_error_on_rset = 0;

        my $esmtp = Net::Server::Mail::ESMTP->new(socket => $conn);
        # activate some extensions
        $esmtp->register('Net::Server::Mail::ESMTP::8BITMIME');
        $esmtp->register('Net::Server::Mail::ESMTP::PIPELINING');
	# adding some handlers
	$esmtp->set_callback(MAIL => sub {
            my ($session, $from) = @_;
	    if ($from eq 'temporary-450@failure.com'){
                return (0, 450, 'temporary failure for temporary-450@failure.com');
	    } elsif ($from eq 'permanent-550@failure.com'){
                return (0, 550, 'temporary failure for permanent-550@failure.com');
	    } elsif ($from eq 'success-220@success.com'){
                return (1, 220, 'success for success-220@success.com');
	    }
	});
        $esmtp->set_callback(RCPT => sub {
            my ($session, $recipient) = @_;
	    if ($recipient eq 'temporary-450@failure.com'){
                return (0, 450, 'temporary failure for temporary-450@failure.com');
	    } elsif ($recipient eq 'permanent-550@failure.com'){
                return (0, 550, 'temporary failure for permanent-550@failure.com');
	    } elsif ($recipient eq 'success-220@success.com'){
                return (1, 220, 'success for success-220@success.com');
	    }
	});
        $esmtp->set_callback(DATA => sub {
	    my ($session, $data) = @_;
	    if ($$data =~ m/DO NOT ACCEPT THIS MESSAGE/){
	        return (0, 550, 'message rejected');
	    } else {
	        return 1;
	    }
	});
	$esmtp->set_callback(HELP => sub {
            my ($session, $help) = @_;

	    if (not defined $help){
	         return (1, 214, 'HELP IN GENERAL');
            } elsif ($help eq 'RCPT'){
                 return (1, 214, 'HELP ON RCPT');
            } elsif ($help eq 'STRANGE_FAILURES'){
	         $issue_an_error_on_rset = 1;
		 $issue_an_error_on_quit = 1;
	         return (1, 250, 'STRANGE_FAILURES active');
	    } else {
                 return 0;
	    }
	});
        $esmtp->set_callback(RSET => sub {
            my ($session) = @_;
	    if ($issue_an_error_on_rset == 1){
	    	return (0, 550, 'Can\'t RSET');
	    } else {
                return 1;
	    }
	});
        $esmtp->set_callback(QUIT => sub {
            my ($session) = @_;
	    if ($issue_an_error_on_quit == 1){
	    	return (0, 550, 'Can\'t QUIT');
	    } else {
                return 1;
	    }
	});
	$esmtp->process();
        $conn->close();
	$conn_number++;
        if ($conn_number == 2) {
	   $server->close;
	   exit 1;
	};
    }
}

diag("Spawned server pid: $server_pid");
diag("Starting tests");
sleep 1; 

my $c1 = Test::SMTP->connect_ok("connects to SMTP on $LOCAL_PORT",
                                Host => '127.0.0.1', 
				Port => $LOCAL_PORT, 
				Hello => 'example.com',
				AutoHello => 1
				) or die "Can't connect to the SMTP server so can't go on testing";


test_out('not ok 1 - Fails if server announces 8BITMIME');
test_fail(+1);
$c1->supports_ko('8BITMIME',   'Fails if server announces 8BITMIME');
test_out('not ok 2 - Fails if server doesn\'t announce 888BITMIME');
test_fail(+1);
$c1->supports_ok('888BITMIME', 'Fails if server doesn\'t announce 888BITMIME');
test_out('not ok 3 - Fails if server announces PIPELINING');
test_fail(+1);
$c1->supports_ko('PIPELINING', 'Fails if server announces PIPELINING');
test_out('not ok 4 - Fails if the mail_from fails');
$c1->mail_from_ok('<temporary-450@failure.com>', 'Fails if the mail_from fails');
test_fail(+1);
test_out('not ok 5 - Fails if the mail_from fails');
test_fail(+1);
$c1->mail_from_ok('<permanent-550@failure.com>', 'Fails if the mail_from fails');
test_out('not ok 6 - Fails if the mail_from is ok');
test_fail(+1);
$c1->mail_from_ko('<success-220@success.com>', 'Fails if the mail_from is ok');

#
# RCPT TO TESTS
# 

test_out('not ok 7 - Fails if the mail_from fails');
test_fail(+1);
$c1->rcpt_to_ok('<temporary-450@failure.com>', 'Fails if the mail_from fails');
test_out('not ok 8 - Fails because last code was temporary');
test_fail(+1);
$c1->code_isnt_temporary('Fails because last code was temporary');
test_out('not ok 9 - Fails because last code was temporary');
test_fail(+1);
$c1->code_is_success('Fails because last code was temporary');
test_out('not ok 10 - Fails because last code was temporary');
test_fail(+1);
$c1->code_is_permanent('Fails because last code was temporary');
test_out('not ok 11 - Fails because last code was temporary');
test_fail(+1);
$c1->code_isnt_failure('Fails because last code was temporary');



test_out('not ok 12 - Fails if the mail_from fails');
test_fail(+1);
$c1->rcpt_to_ok('<permanent-550@failure.com>', 'Fails if the mail_from fails');
test_out('not ok 13 - Fails because last code was permanent');
test_fail(+1);
$c1->code_is_temporary('Fails because last code was permanent');
test_out('not ok 14 - Fails because last code was permanent');
test_fail(+1);
$c1->code_is_success('Fails because last code was permanent');
test_out('not ok 15 - Fails because last code was permanent');
test_fail(+1);
$c1->code_isnt_permanent('Fails because last code was permanent');
test_out('not ok 16 - Fails because last code was permanent');
test_fail(+1);
$c1->code_isnt_failure('Fails because last code was permanent');


test_out('not ok 17 - Fails if the mail_from is ok');
test_fail(+1);
$c1->rcpt_to_ko('<success-220@success.com>', 'Fails if the mail_from is ok');

test_out('not ok 18 - Fails because last code was success');
test_fail(+1);
$c1->code_is_permanent('Fails because last code was success');
test_out('not ok 19 - Fails because last code was success');
test_fail(+1);
$c1->code_isnt_success('Fails because last code was success');
test_out('not ok 20 - Fails because last code was success');
test_fail(+1);
$c1->code_is_temporary('Fails because last code was success');
test_out('not ok 21 - Fails because last code was success');
test_fail(+1);
$c1->code_is_failure('Fails because last code was success');



test_out('not ok 22 - Fails if data was accepted');
test_fail(+1);
$c1->data_ko('Fails if data was accepted');

$c1->datasend([ 
    "Line 1\n",
    "Line 2\n"
]);
test_out('not ok 23 - Fails if dataend was accepted');
test_fail(+1);
$c1->dataend_ko('Fails if dataend was accepted');

test_out('not ok 24 - Fails if RSET accepted');
test_fail(+1);
$c1->rset_ko('Fails if RSET accepted');
test_out('not ok 25 - Fails if didn\'t accept DATA');
test_fail(+1);
$c1->data_ok('Fails if didn\'t accept DATA');
test_out('not ok 26 - Fails if RSET accepted');
test_fail(+1);
$c1->rset_ko('Fails if RSET accepted');

$c1->hello('mydomain.com');

test_out('not ok 27 - Fails if QUIT accepted'); 
test_fail(+1);
$c1->quit_ko('Fails if QUIT accepted');

test_out("not ok 28 - connects to SMTP on $LOCAL_PORT");
test_fail(+1);
my $c2 = Test::SMTP->connect_ko("connects to SMTP on $LOCAL_PORT",
                                Host => '127.0.0.1',
                                Port => $LOCAL_PORT,
                                Hello => 'example.com',
                                AutoHello => 1,
                                ); 

$c2->mail_from('<success-220@success.com>');
$c2->rcpt_to('<success-220@success.com>');

$c2->data;
$c2->datasend([ "DO NOT ACCEPT THIS MESSAGE\n", "L2\n" ]);

test_out('not ok 29 - Fails because the message is not accepted');
test_fail(+1);
$c2->dataend_ok('Fails because the message is not accepted');

$c2->help('STRANGE_FAILURES');

test_out('not ok 30 - Fails because RSET was rejected');
test_fail(+1);
$c2->rset_ok('Fails because RSET was rejected');

test_out('not ok 31 - Fails because QUIT was rejected');
test_fail(+1);
$c2->quit_ok('Fails because QUIT was rejected');

test_test(name => "Planned failures work ok", skip_err => 1);

kill 1, $server_pid;
wait;
