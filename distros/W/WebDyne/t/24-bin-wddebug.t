use strict;
use warnings;

use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin";
use bin_helper qw(run_cmd write_file);
use File::Temp qw(tempdir);
use File::Spec;

my $script=File::Spec->catfile('bin', 'wddebug');
ok(-f $script, 'wddebug script exists');

my $root_dn=tempdir(CLEANUP => 1);
write_file("$root_dn/WebDyne.pm", <<'END_PM');
package WebDyne;
0 && debug('root');
1;
END_PM
write_file("$root_dn/WebDyne/Foo.pm", <<'END_PM');
package WebDyne::Foo;
debug('foo');
1;
END_PM

my ($status_out, $status_err, $status_rc)=run_cmd($^X, '-Ilib', $script, '--directory', $root_dn, '--status');
is($status_rc, 0, 'wddebug --status exits cleanly');
like($status_out, qr/debug disabled: WebDyne\.pm/, 'wddebug reports disabled root module');
like($status_out, qr/debug\s+enabled: WebDyne\/Foo\.pm/, 'wddebug reports enabled child module');
is($status_err, '', 'wddebug --status writes no stderr');

my (undef, $enable_err, $enable_rc)=run_cmd($^X, '-Ilib', $script, '--directory', $root_dn, '--enable', '--yes');
is($enable_rc, 0, 'wddebug --enable exits cleanly');
is($enable_err, '', 'wddebug --enable writes no stderr');
open(my $root_fh, '<', "$root_dn/WebDyne.pm") || die $!;
local $/;
my $root_pm=<$root_fh>;
close($root_fh) || die $!;
like($root_pm, qr/1 && debug\('root'\)/, 'wddebug --enable flips disabled debug guard on root module');

my (undef, $disable_err, $disable_rc)=run_cmd($^X, '-Ilib', $script, '--directory', $root_dn, '--disable', '--yes');
is($disable_rc, 0, 'wddebug --disable exits cleanly');
is($disable_err, '', 'wddebug --disable writes no stderr');
open(my $foo_fh, '<', "$root_dn/WebDyne/Foo.pm") || die $!;
my $foo_pm=<$foo_fh>;
close($foo_fh) || die $!;
like($foo_pm, qr/0 && debug\('foo'\)/, 'wddebug --disable prefixes bare debug call in child module');

my ($dump_out, $dump_err, $dump_rc)=run_cmd($^X, '-Ilib', $script, '--dir', $root_dn, '--dump_opt');
isnt($dump_rc, 0, 'wddebug --dump_opt aborts after dumping options');
is($dump_out, '', 'wddebug --dump_opt writes no stdout');
like($dump_err, qr/'dump_opt'\s*=>\s*1/, 'wddebug --dump_opt dumps dump_opt flag');
like($dump_err, qr/'directory'\s*=>\s*'\Q$root_dn\E'/, 'wddebug --dump_opt dumps directory alias value');

done_testing();
