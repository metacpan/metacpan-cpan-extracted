#!/usr/bin/perl
# 13.9.1999, Sampo Kellomaki <sampo@iki.fi>
#
# Usage: printf "test\r\n" | ./smime -mime text/plain | ./smime -cs joecool-both.pem 1234 | send.pl subject from to
#

use Net::SMTP;

($subject, $from, $to) = @ARGV;
$subject = "sign test $$" unless $subject;
$from = 'sampo2@neuronio.pt' unless $from;
$to = 'sampo2@neuronio.pt' unless $to;

$smime = join '', <STDIN>;

$msg = <<SMTP;
To: $to
From: $from
Subject: $subject
MIME-Version: 1.0
$smime
SMTP
    ;

print ">>$msg<<\n";
$msg =~ s/\r\n/\n/g;   # seems datasend will do gratuitous LF->CFLF for us

$smtp = Net::SMTP->new('mail.neuronio.pt');
$smtp->mail($from);
$smtp->to($to);
$smtp->data();
$smtp->datasend($msg);
$smtp->dataend();

print "Done.\n";

__END__

printf "test\r\n" | ./smime -mime text/plain | ./smime -cs joecool-both.pem 1234 | ./send.pl

printf "teksti\r\n" | ./smime -m image/gif openssl.gif | ./smime -cs joecool-both.pem 1234 | ./send.pl

./smime -m image/gif openssl.gif <8bit | ./smime -cs joecool-both.pem 1234 | ./send.pl | tee sig2 

