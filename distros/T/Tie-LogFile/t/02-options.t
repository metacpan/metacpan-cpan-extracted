#
# $Id: 02-options.t,v 1.1.1.1 2002/10/16 10:08:08 ctriv Exp $
#

use Test::More tests => 17;
use strict;

BEGIN { 
    use_ok('Tie::LogFile'); 
}


my $logfile = 'test.log';
my $fh;

unlink($logfile);

ok(tie *NONEWLINE, 'Tie::LogFile', $logfile, force_newline => 0);
ok(print NONEWLINE 'Hi ');
ok(print NONEWLINE "There\n");
ok(close(NONEWLINE));

ok(open($fh, $logfile), 'Log file exists');
like(<$fh>,  qr/^\[.*?\] Hi \[.*?\] There$/, 'First line matches');
undef($fh);


ok(tie *OVERWRITE, 'Tie::LogFile', $logfile, mode => '>');
ok(print OVERWRITE "Overwritten");
ok(close(OVERWRITE));

ok(open($fh, $logfile), 'Log file exists');
like(<$fh>,  qr/^\[.*?\] Overwritten$/,      'First line matches');
undef($fh);

unlink($logfile);

ok(tie *AF, 'Tie::LogFile', $logfile, autoflush => 1);
ok(print AF "Autoflush");


ok(open($fh, $logfile), 'Log file exists');
like(<$fh>,  qr/^\[.*?\] Autoflush$/,      'First line matches');
undef($fh);


ok(close(AF));

unlink($logfile);

