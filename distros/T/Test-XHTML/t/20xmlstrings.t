#!/usr/bin/perl -w
use strict;

use Test::More tests => 4;
use Test::XHTML::Valid;
use IO::File;

#use Data::Dumper;

SKIP: {
	skip "Can't see a network connection", 4   if(pingtest());

    my $txv = Test::XHTML::Valid->new();

    my $xml = read_file('./t/samples/test01.html');
    $txv->process_xml($xml);                # test XML as a string
    my $result = $txv->process_results();
    is($result->{PASS},1,"XHTML validity check for XML string - PASS");
    is($result->{FAIL},0,"XHTML validity check for XML string - No FAIL");

    #diag(Dumper($result));

    $txv->clear();                          # clear all current errors and results

    $xml = read_file('./t/samples/test03.html');
    $txv->process_xml($xml);                # test XML as a string
    $result = $txv->process_results();
    is($result->{PASS},0,"XHTML validity check for XML string - No PASS");
    is($result->{FAIL},1,"XHTML validity check for XML string - FAIL");

    #diag(Dumper($result));
}

# crude, but it'll hopefully do ;)
sub pingtest {
  system("ping -q -c 1 www.w3c.org >/dev/null 2>&1");
  my $retcode = $? >> 8;
  # ping returns 1 if unable to connect
  return $retcode;
}

sub read_file {
    my $file = shift;
    my $text;

    my $fh = IO::File->new($file,'r')  or die "Cannot open file [$file]: $!\n";
    while(<$fh>) { $text .= $_; }
    $fh->close;

    return $text;
}
