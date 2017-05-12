#
# $Id: 03-count.t,v 1.1.1.1 2002/10/16 10:08:08 ctriv Exp $
#

use Test::More tests => 24;
use strict;

BEGIN { 
    use_ok('Tie::LogFile'); 
}


my $logfile = 'test.log';
my $fh;

unlink($logfile);

ok(tie *NONEWLINE, 'Tie::LogFile', $logfile, 'format' => '%c -- %m');
ok(print NONEWLINE $_) for (1 .. 10);
ok(close(NONEWLINE));

ok(open($fh, $logfile), 'Log file exists');

for (1 .. 10) {
	my $line; chomp($line = <$fh>);
	is($line, "$_ -- $_", "line $_ matches");
}

undef($fh);


unlink($logfile);

