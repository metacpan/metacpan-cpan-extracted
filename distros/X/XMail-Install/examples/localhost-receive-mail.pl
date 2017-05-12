#!/usr/bin/perl

use strict;
use warnings;

use Mail::POP3Client;

# --------------

my($pop) = Mail::POP3Client -> new
(
	USER		=> 'xmailuser@xmailserver.test',
	PASSWORD	=> 'xmail',
	HOST		=> '127.0.0.1',
	AUTH_MODE	=> 'PASS',
);
my($count) = $pop -> Count();

print "Server has $count message(s) waiting to be read. \n";
print '-' x 50, "\n";

my(@body);
my(@head);
my($i);

for ($i = 1; $i <= $count; $i++)
{
	@head = $pop -> Head($i);

	print "Received head: $_\n" for @head;
	print "\n";

	@body = $pop -> Body($i);

	print "Received body: $_\n" for @body;
	print '-' x 50, "\n";

	$pop -> Delete($i);
}

$pop -> Close();
