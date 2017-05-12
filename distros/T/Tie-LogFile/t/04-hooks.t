#
# $Id: 04-hooks.t,v 1.1.1.1 2002/10/16 10:08:08 ctriv Exp $
#

use Test::More tests => 8;
use strict;

BEGIN { 
    use_ok('Tie::LogFile'); 
}


my $logfile = 'test.log';
my $fh;

unlink($logfile);

$Tie::LogFile::formats{'l'} = sub { length $_[1] };


ok(tie *LOG, 'Tie::LogFile', $logfile, 'format' => '[%l] %m');
ok(print LOG 'a');
ok(print LOG 'ab');
ok(close(LOG));

ok(open($fh, $logfile), 'Log file exists');

like(<$fh>, qr/^\[1\] a$/,  'First line matches.');
like(<$fh>, qr/^\[2\] ab$/, 'Second line matches.');

undef($fh);


unlink($logfile);

