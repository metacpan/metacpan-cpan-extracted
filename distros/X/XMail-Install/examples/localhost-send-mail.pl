#!/usr/bin/perl

use strict;
use warnings;

use Email::Send;

# --------------

my $message = <<'EOS';
To: xmailuser@xmailserver.test
From: ron@savage.net.au
Subject: Testing installation of XMail from the command line

A charm of finches.
EOS

my $sender = Email::Send->new({mailer => 'SMTP'});
$sender->mailer_args([Host => '127.0.0.1']);
$sender->send($message);

print "Message sent. \n";
