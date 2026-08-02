use strict;
use warnings;

use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin";
use bin_helper qw(run_cmd write_file);
use File::Temp qw(tempdir tempfile);
use File::Spec;

my $script=File::Spec->catfile('bin', 'wdrender');
ok(-f $script, 'wdrender script exists');

my ($version_out, $version_err, $version_rc)=run_cmd($^X, '-Ilib', $script, '--version');
is($version_rc, 0, 'wdrender --version exits cleanly');
like($version_out, qr/wdrender version: \S+/, 'wdrender --version reports script version');
like($version_out, qr/WebDyne version: \S+/, 'wdrender --version reports WebDyne version');
is($version_err, '', 'wdrender --version writes no stderr');

my $tmp_dn=tempdir(CLEANUP => 1);
my $source_fn="$tmp_dn/render.psp";
write_file($source_fn, <<'END_PSP');
<start_html>
<perl handler="handler">
Value: ${value}
</perl>
__PERL__
sub handler {
    my ($self, $param_hr)=@_;
    return $self->render($param_hr);
}
END_PSP

my ($stdout, $stderr, $rc)=run_cmd(
    $^X, '-Ilib', $script,
    '--no-colour', '--no-tidy', '--no-lineno',
    '--param', 'value=omega',
    $source_fn,
);
is($rc, 0, 'wdrender exits cleanly when rendering to stdout');
like($stdout, qr/Value:\s*omega/, 'wdrender renders handler param to stdout');
is($stderr, '', 'wdrender stdout render writes no stderr');

my ($outfile_fh, $outfile_fn)=tempfile();
close($outfile_fh) || die $!;
my ($file_out, $file_err, $file_rc)=run_cmd(
    $^X, '-Ilib', $script,
    '--no-colour', '--no-tidy', '--no-lineno',
    '--param', 'value=sigma',
    '--outfile', $outfile_fn,
    $source_fn,
);
is($file_rc, 0, 'wdrender exits cleanly when rendering to outfile');
is($file_out, '', 'wdrender with outfile does not print HTML to stdout');
is($file_err, '', 'wdrender outfile render writes no stderr');
open(my $verify_fh, '<', $outfile_fn) || die $!;
local $/;
my $written_html=<$verify_fh>;
close($verify_fh) || die $!;
like($written_html, qr/Value:\s*sigma/, 'wdrender writes rendered HTML to outfile');

done_testing();
