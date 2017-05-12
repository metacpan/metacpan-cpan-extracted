#!/usr/bin/perl -w
use strict;

use Test::More tests => 11;
use Test::XHTML;
use IO::File;

my $logfile = './test10.log';
unlink($logfile);

SKIP: {
	skip "Can't see a network connection", 11   if(pingtest());

    setlog( logfile => $logfile, logclean => 1 );

    my $tests = "t/samples/10-filetests.csv";
    runtests($tests);

    ok(-f $logfile,'log file exists');
    my $source = read_file($logfile);
    my $target = read_file('./t/samples/test10.log');
    is($source,$target,'logfile as expected');
}

unlink($logfile);


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
