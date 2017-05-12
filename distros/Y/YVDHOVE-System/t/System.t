# Before `make install' is performed this script should be runnable with `make test'
# After `make install' it should work as `perl String.t'

#########################

use Test::More tests => 4;
BEGIN { use_ok('YVDHOVE::System', qw(:all)) };

#########################

my($rc, $stdout, $stderr) = execCMD('perl -v', 1, 0);

is($rc, 1, 'execCMD - RC');
like($stdout, qr/This is perl/, 'execCMD - STDOUT');
is($stderr, '', 'execCMD - STDERR');