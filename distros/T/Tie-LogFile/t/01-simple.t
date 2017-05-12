#
# $Id: 01-simple.t,v 1.1.1.1 2002/10/16 10:08:08 ctriv Exp $
#

use Test::More tests => 27;
use strict;

BEGIN { 
    use_ok('Tie::LogFile'); 
}

my $logfile = 'test.log';
my $fh;

unlink($logfile);

ok(tie *LOG, 'Tie::LogFile', $logfile);
ok(print LOG "Test begun");
ok(printf LOG "%s", "testing still");
ok(close(LOG));


ok(open($fh, $logfile), 'Log file exists');
like(<$fh>,  qr/^\[.*?\] Test begun$/,    'First line matches');
like(<$fh>,  qr/^\[.*?\] testing still$/, 'Second line matches');
undef($fh);


unlink($logfile);

ok(tie *LOG2, 'Tie::LogFile', $logfile, 'format' => '"%m" -- %% -- %p -- <%d>');
ok(print LOG2 "Funky Format");
ok(close(LOG2));

ok(open($fh, $logfile), 'Log file exists');
like(<$fh>,  qr/^"Funky Format" -- % -- $$ -- <.*?>$/,    'First line matches');
undef($fh);

unlink($logfile);

ok(tie *LOG3, 'Tie::LogFile', $logfile, 'tformat' => '%X');
ok(print LOG3 "Time Format!");
ok(close(LOG3));

my $date = Tie::LogFile::misc::time2str('%X');

ok(open($fh, $logfile), 'Log file exists');
like(<$fh>,  qr/^\[$date\] Time Format!$/,    'First line matches');
undef($fh);

unlink($logfile);

#
# Make sure the default mode is append
#

ok(tie *APD, 'Tie::LogFile', $logfile);
ok(print APD "one");
ok(close(APD));

ok(tie *APD2, 'Tie::LogFile', $logfile);
ok(print APD2 "two");
ok(close(APD2));


ok(open($fh, $logfile), 'Log file exists');
like(<$fh>,  qr/^\[.*?\] one$/,    'First line matches');
like(<$fh>,  qr/^\[.*?\] two$/,    'First line matches');
undef($fh);

unlink($logfile);
