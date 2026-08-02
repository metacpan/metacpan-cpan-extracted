use strict;
use warnings;

use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin";
use bin_helper qw(run_cmd);
use File::Spec;

my $script=File::Spec->catfile('bin', 'wdcompile');
ok(-f $script, 'wdcompile script exists');

my ($version_out, $version_err, $version_rc)=run_cmd($^X, '-Ilib', $script, '--version');
is($version_rc, 0, 'wdcompile --version exits cleanly');
like($version_out, qr/wdcompile version: \S+/, 'wdcompile --version reports script version');
like($version_out, qr/WebDyne version: \S+/, 'wdcompile --version reports WebDyne version');
is($version_err, '', 'wdcompile --version writes no stderr');

my ($meta_out, $meta_err, $meta_rc)=run_cmd($^X, '-Ilib', $script, '--meta', 't/start_html_text.psp');
is($meta_rc, 0, 'wdcompile --meta exits cleanly');
like($meta_out, qr/'manifest'\s*=>\s*\[\s*'t\/start_html_text\.psp'/, 'wdcompile --meta prints manifest metadata');
is($meta_err, '', 'wdcompile --meta writes no stderr');

my ($repeat_out, $repeat_err, $repeat_rc)=run_cmd($^X, '-Ilib', $script, '--repeat', '2', '--meta', 't/start_html_text.psp');
is($repeat_rc, 0, 'wdcompile --repeat exits cleanly');
my $manifest_count=()=($repeat_out =~ /'manifest'/g);
is($manifest_count, 2, 'wdcompile --repeat prints metadata twice');
is($repeat_err, '', 'wdcompile --repeat writes no stderr');

done_testing();
