# -*- perl -*-

use strict;
use warnings;

use lib 't';

use IO::Socket;
use Net::Server::Mail::ESMTP;
use Net::Server::Mail::ESMTP::SIZE;
use Test::SMTP;
use Test::More;
use Sys::Hostname;

plan tests => 85;

my $LOCAL_PORT = $ENV{'SMTP_SERVER_PORT'} || 2525;

#spawn off a server

my $server_pid;

    my $server;
    while(not defined $server && $LOCAL_PORT < 4000)
    {
        $server = new IO::Socket::INET(
            Listen => 1,
            LocalPort => ++$LOCAL_PORT
	);
    } 

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
        $esmtp->register('Net::Server::Mail::ESMTP::SIZE');
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
				AutoHello => 1,
				) or die "Can't connect to the SMTP server so can't go on testing";

$c1->banner_like(qr/Net::Server::Mail/, 'Passes if banner has the Net::Server::Mail string');
$c1->banner_unlike(qr/This is an open relay/, 'Passes if banner does not have \'open relay\' string');

my $hostname = hostname();
$c1->domain_like(qr/$hostname/, "Passes if domain is $hostname");
$c1->domain_unlike(qr/example.com/, 'Passes if domain is not example.com');

$c1->supports_ok('8BITMIME',   'Passes if server announces 8BITMIME');
$c1->supports_ko('888BITMIME', 'Passes if server doesn\'t announce 888BITMIME');

$c1->supports_ok('PIPELINING', 'Passes if server announces PIPELINING');

$c1->supports_like('SIZE', qr/000/, 'Passes if SIZE does not contain 000');
$c1->supports_unlike('SIZE', qr/9999/, 'Passes if size does not contain 9999');

$c1->supports_cmp_ok('SIZE', '==', 1000, 'Passes if SIZE == 1000');
$c1->supports_cmp_ok('SIZE', '!=', 9999, 'Passes if SIZE != 9999');

$c1->mail_from_ko('<temporary-450@failure.com>', 'Passes if the mail_from fails');
$c1->code_is(450, 'Passes if temporary failure with code 450');
$c1->code_isnt(444, 'Passes if temporary failure is not with code 444');
$c1->message_like(qr/temporary failure for temporary-450\@failure.com/, 'Passes if expected message matches');
$c1->message_unlike(qr/success/, 'Passes if message doesn\'t say success');
$c1->code_is_temporary('Passes if code indicated temporary failure');
$c1->code_is_failure('Passes if code indicated some type of failure');
$c1->code_isnt_success('Passes if code did not indicate success');
$c1->code_isnt_permanent('Passes if code did not indicate permanent failure');

$c1->mail_from_ko('<permanent-550@failure.com>', 'Passes if the mail_from fails');
$c1->code_is(550, 'Passes if temporary failure with code 550');
$c1->code_isnt(555, 'Passes if temporary failure is not with code 555');
$c1->message_like(qr/temporary failure for permanent-550\@failure.com/, 'Passes if expected message matches');
$c1->message_unlike(qr/success/, 'Passes if message doesn\'t say success');
$c1->code_isnt_temporary('Passes if code did not indicate temporary failure');
$c1->code_is_failure('Passes if code indicated some type of failure');
$c1->code_isnt_success('Passes if code did not indicate success');
$c1->code_is_permanent('Passes if code indicated temporary failure');

$c1->mail_from_ok('<success-220@success.com>', 'Passes if the mail_from is ok');
$c1->code_is(220, 'Passes if code 220');
$c1->code_isnt(222, 'Passes if is not with code 222');
$c1->message_like(qr/success for success-220\@success.com/, 'Passes if expected message matches');
$c1->message_unlike(qr/failure/, 'Passes if message doesn\'t say failure');
$c1->code_isnt_temporary('Passes if code did not indicate temporary failure');
$c1->code_isnt_failure('Passes if code did not indicate some type of failure');
$c1->code_is_success('Passes if code indicated success');
$c1->code_isnt_permanent('Passes if code did not indicate pemanent failure');

#
# RCPT TO TESTS
# 

$c1->rcpt_to_ko('<temporary-450@failure.com>', 'Passes if the mail_from fails');
$c1->code_is(450, 'Passes if temporary failure with code 450');
$c1->code_isnt(444, 'Passes if temporary failure is not with code 444');
$c1->message_like(qr/temporary failure for temporary-450\@failure.com/, 'Passes if expected message matches');
$c1->message_unlike(qr/success/, 'Passes if message doesn\'t say success');
$c1->code_is_temporary('Passes if code indicated temporary failure');
$c1->code_is_failure('Passes if code indicated some type of failure');
$c1->code_isnt_success('Passes if code did not indicate success');
$c1->code_isnt_permanent('Passes if code did not indicate permanent failure');

$c1->rcpt_to_ko('<permanent-550@failure.com>', 'Passes if the mail_from fails');
$c1->code_is(550, 'Passes if temporary failure with code 550');
$c1->code_isnt(555, 'Passes if temporary failure is not with code 555');
$c1->message_like(qr/temporary failure for permanent-550\@failure.com/, 'Passes if expected message matches');
$c1->message_unlike(qr/success/, 'Passes if message doesn\'t say success');
$c1->code_isnt_temporary('Passes if code did not indicate temporary failure');
$c1->code_is_failure('Passes if code indicated some type of failure');
$c1->code_isnt_success('Passes if code did not indicate success');
$c1->code_is_permanent('Passes if code did indicated permanent failure');


$c1->rcpt_to_ok('<success-220@success.com>', 'Passes if the mail_from is ok');
$c1->code_is(220, 'Passes if code 220');
$c1->code_isnt(222, 'Passes if is not with code 222');
$c1->message_like(qr/success for success-220\@success.com/, 'Passes if expected message matches');
$c1->message_unlike(qr/failure/, 'Passes if message doesn\'t say failure');
$c1->code_isnt_temporary('Passes if code did not indicate temporary failure');
$c1->code_isnt_failure('Passes if code did not indicate some type of failure');
$c1->code_is_success('Passes if code indicated success');
$c1->code_isnt_permanent('Passes if code did not indicate permanent failure');

$c1->data_ok('Passes if data was accepted');
$c1->datasend([ 
    "Line 1\n",
    "Line 2\n"
]);
$c1->dataend_ok('Passes if dataend was accepted');

$c1->rset_ok('Passes if RSET accepted');

$c1->data_ko('Passes if didn\'t accept DATA');

$c1->rset_ok('Passes if RSET accepted');

$c1->hello('mydomain.com');

$c1->mail_from_ok('<success-220@success.com>');
$c1->rcpt_to_ok('<success-220@success.com>');
$c1->data_ok('Passes if data was succesful');
$c1->datasend([
    "DO NOT ACCEPT THIS MESSAGE\n",
    "Line 1\n",
    "Line 2\n"
]);
$c1->dataend_ko('Passes if did not accept the message');


$c1->rset_ok('RSET connection again');

$c1->help_like(undef, qr/HELP IN GENERAL/, 'Passes if help matches');
$c1->help_unlike(undef, qr/THIS IS NOT HELP/, 'Passes if help doesn\'t match');

$c1->help_like('RCPT', qr/HELP ON RCPT/, 'Passes if help on RCPT matches');
$c1->help_unlike('RCPT', qr/THIS IS NOT HELP/, 'Passes if help doesn\'t match');

$c1->quit_ok('Passes because the server quits');

my $c2 = Test::SMTP->connect_ok("connects to SMTP on $LOCAL_PORT",
                                Host => '127.0.0.1', 
				Port => $LOCAL_PORT, 
				Hello => 'example.com',
				AutoHello => 1,
				) or die "Can't connect to the SMTP server so can't go on testing";
$c2->help_like('STRANGE_FAILURES', qr/active/, 'Sets up strange failures');

$c2->rset_ko('Passes if server decides to not let you RSET');
$c2->quit_ko('Passes if server decides to not let you QUIT');


#$c3->hello_ko('rejectme', 'Rejected a bad EHLO');
#$c4->hello_ok('myhello', 'Accepted a good EHLO');


kill 1, $server_pid;
wait;

