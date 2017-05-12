#!/usr/bin/perl -w

#
# Copyright (c) 2001 Giulio Motta. All rights reserved.
# http://www-sms.sourceforge.net/
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

######################################################################
### Cron this job on a server to have a SMS alert when you receive ###
### an e-mail (you'll love getting SPAM!) ;)                       ###
######################################################################

use strict;
use WWW::SMS;
use Net::POP3;

my $server = 'my_pop_server';
my $username = 'username';
my $password = 'password';
my $intpref = 'intpref';
my $opprefix = 'opprefix';
my $phonenumber = 'phonenumber';

my ($subject, $from);

my %oldmsg;

open(IN, "< messages.txt");
while (<IN>) {
    chomp;
    $oldmsg{$_}++;
}
close(IN);

my $pop = Net::POP3->new($server);

my $mail = $pop->login($username, $password) || die "Can't connect to $server\n";

my %uid = %{$pop->uidl()};

for my $msgnum (keys %uid) {
    unless (exists $oldmsg{ $uid{$msgnum} }) {
        my $mailH = join ('', @{$pop->top( $msgnum )} );
        my ($from)    = $mailH =~ /^From: (.+)/m;
        my ($subject) = $mailH =~ /^Subject: (.+)/m;
        $_ =~ tr/@/A/ for ($from, $subject); #this is cause some gates don't like @
        my $sms = WWW::SMS->new
            ($intpref, $opprefix, $phonenumber, "New message from $from - $subject");
        for my $gate ( $sms->gateways(sorted => 'reliability') ) {
            $sms->send($gate) && last;
        }
    }
}

$pop->quit();

open(OUT, "> messages.txt");
    print OUT join($/, values %uid);
close(OUT);
