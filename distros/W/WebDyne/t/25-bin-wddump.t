use strict;
use warnings;

use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin";
use bin_helper qw(run_cmd);
use File::Temp qw(tempfile);
use File::Spec;
use Storable qw(store);

my $script=File::Spec->catfile('bin', 'wddump');
ok(-f $script, 'wddump script exists');

my ($version_out, $version_err, $version_rc)=run_cmd($^X, '-Ilib', $script, '--version');
is($version_rc, 0, 'wddump --version exits cleanly');
like($version_out, qr/wddump version: \S+/, 'wddump --version reports script version');
is($version_err, '', 'wddump --version writes no stderr');

my ($fh, $dump_fn)=tempfile();
close($fh) || die $!;
store([{ alpha => 1 }, ['omega']], $dump_fn);

my ($stdout, $stderr, $rc)=run_cmd($^X, '-Ilib', $script, $dump_fn);
is($rc, 0, 'wddump exits cleanly on stored data');
like($stdout, qr/'alpha'\s*=>\s*1/, 'wddump prints stored hash content');
like($stdout, qr/'omega'/, 'wddump prints stored array content');
is($stderr, '', 'wddump writes no stderr');

my ($dump_out, $dump_err, $dump_rc)=run_cmd($^X, '-Ilib', $script, '--dump_opt');
isnt($dump_rc, 0, 'wddump --dump_opt aborts after dumping options');
is($dump_out, '', 'wddump --dump_opt writes no stdout');
like($dump_err, qr/'dump_opt'\s*=>\s*1/, 'wddump --dump_opt dumps dump_opt flag');

done_testing();
