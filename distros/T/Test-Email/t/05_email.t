#!perl
use strict;
use warnings FATAL => 'all';

use Data::Dumper;
use Mail::Sendmail;
use MIME::Parser;
use Test::More tests => 7;
BEGIN { use_ok('Test::Email') };

#########################

my $parser = MIME::Parser->new();
$parser->interface(ENTITY_CLASS => 'Test::Email');
$parser->output_to_core(1); # no tmpfiles

# setup the email for testing
my $email = $parser->parse_data(<<'END');
From:<james@localhost>
To:<james@localhost>
Subject: Tester

This is the message
END

# pass some tests
$email->header_like('to', qr/localhost/, 'to');
$email->header_ok('from', '<james@localhost>', 'from');
$email->header_is('subject', 'Tester', 'subject');

$email->body_like(qr/^This is/, 'body_like');
$email->body_ok('This is the message', 'body_ok');
$email->body_is('This is the message', 'body_is');

__END__

