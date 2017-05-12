# -*- perl -*-

use strict;
use warnings;

use Test::SMTP qw/plan/;

plan tests => 11;

my $c1 = Test::SMTP->connect_ok("connects to SMTP on 25",
                                Host => '127.0.0.1', 
				Port => 25, 
				Hello => 'example.com',
				AutoHello => 1,
				) or die "Can't connect to the SMTP server so can't go on testing";

$c1->banner_like(qr/BANNER/, 'Passes if banner has the Net::Server::Mail string');

$c1->domain_like(qr/xxx.com/, "Passes if domain is xxx.com");
$c1->domain_unlike(qr/example.com/, 'Passes if domain is not example.com');

$c1->mail_from_ok('success-220@success.com', 'Passes if the mail_from is ok');

$c1->rcpt_to_ok('success-220@success.com', 'Passes if the mail_from is ok');
$c1->code_is(220, 'Passes if code 220');
$c1->code_isnt(222, 'Passes if is not with code 222');

$c1->data_ok('Passes if data was accepted');
$c1->datasend([ 
    "Line 1\n",
    "Line 2\n"
]);
$c1->dataend_ok('Passes if dataend was accepted');

$c1->quit_ok('Passes because the server quits');

