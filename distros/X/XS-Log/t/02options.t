use strict; use warnings; use Test::More; use XS::Log qw(:all);
setLogLevel(LOG_LEVEL_DEBUG); pass('set level'); setLogMode(LOG_MODE_CYCLE); pass('set mode'); setLogColor(0); pass('set color'); setLogTargets(LOG_TARGET_CONSOLE); pass('set targets'); ok(setLogOptions('show_file_info',0),'set option'); ok(!setLogOptions('unknown',1),'reject unknown'); done_testing;
