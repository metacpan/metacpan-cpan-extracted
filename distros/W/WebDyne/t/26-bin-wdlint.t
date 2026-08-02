use strict;
use warnings;

use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin";
use bin_helper qw(run_cmd write_file);
use File::Temp qw(tempdir);
use File::Spec;

my $script=File::Spec->catfile('bin', 'wdlint');
ok(-f $script, 'wdlint script exists');

my $syntax_cmd="perl -c -Ilib $script";
my ($compile_out, $compile_err, $compile_rc)=run_cmd($^X, '-c', '-Ilib', $script);
is($compile_rc, 0, 'wdlint script itself compiles cleanly');
like($compile_out . $compile_err, qr/syntax OK/, 'wdlint syntax check reports OK');

my $tmp_dn=tempdir(CLEANUP => 1);
my $good_fn="$tmp_dn/good.psp";
my $bad_fn="$tmp_dn/bad.psp";

write_file($good_fn, <<'END_PSP');
<start_html>
Hello
__PERL__
sub hello {
    return 1;
}
END_PSP

write_file($bad_fn, <<'END_PSP');
<start_html>
Hello
__PERL__
sub hello {
    my 2 == 1;
}
END_PSP

my ($good_out, $good_err, $good_rc)=run_cmd($^X, '-Ilib', $script, $good_fn);
is($good_rc, 0, 'wdlint exits cleanly on valid __PERL__ section');
like($good_out, qr/\Q$good_fn\E syntax OK/, 'wdlint reports syntax OK for valid file');
is($good_err, '', 'wdlint writes no stderr for valid file');

my ($bad_out, $bad_err, $bad_rc)=run_cmd($^X, '-Ilib', $script, $bad_fn);
ok($bad_rc != 0, 'wdlint exits non-zero on invalid __PERL__ section');
like($bad_out, qr/\Q$bad_fn\E/, 'wdlint reports the original source filename on error');
like($bad_out, qr/syntax error|had compilation errors/, 'wdlint reports Perl syntax failure');
is($bad_err, '', 'wdlint writes no stderr for invalid file');

done_testing();
