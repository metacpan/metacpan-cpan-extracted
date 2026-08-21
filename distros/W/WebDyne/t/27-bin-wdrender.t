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

my ($header_out, $header_err, $header_rc)=run_cmd(
    $^X, '-Ilib', $script,
    '--header', '--quiet', '--no-colour', '--no-lineno', '--test',
);
is($header_rc, 0, 'wdrender --header exits cleanly');
is($header_err, '', 'wdrender --header writes no stderr');
my @content_type_lines=grep { /^Content-Type:/i } split /\n/, $header_out;
is(scalar(@content_type_lines), 1, 'wdrender --header emits one Content-Type header');
is($content_type_lines[0], 'Content-Type: text/html; charset=UTF-8', 'wdrender --header keeps encoded HTML Content-Type');

my ($plain_header_out, $plain_header_err, $plain_header_rc)=run_cmd(
    $^X, '-Ilib', $script,
    '--header', '--no-colour', '--no-tidy', '--no-lineno', '--test',
);
is($plain_header_rc, 0, 'wdrender --header without colour/tidy exits cleanly');
is($plain_header_err, '', 'wdrender --header without colour/tidy writes no stderr');
my @plain_content_type_lines=grep { /^Content-Type:/i } split /\n/, $plain_header_out;
is(scalar(@plain_content_type_lines), 1, 'wdrender --header without colour/tidy emits one Content-Type header');
is($plain_content_type_lines[0], 'Content-Type: text/html; charset=UTF-8', 'wdrender --header without colour/tidy keeps encoded HTML Content-Type');

my $head_insert_re=qr/<style>\s*:root\s*\{/;

SKIP: {
    eval { require WebDyne::PSGI; require Plack::Test; 1 }
        or skip 'Skipping wdrender PSGI backend test: missing PSGI dependencies', 3;

    my ($psgi_out, $psgi_err, $psgi_rc)=run_cmd(
        $^X, '-Ilib', $script,
        '--psgi', '--no-colour', '--no-tidy', '--no-lineno', '--test',
    );
    is($psgi_rc, 0, 'wdrender --psgi --test exits cleanly');
    is($psgi_err, '', 'wdrender --psgi --test writes no stderr');
    like($psgi_out, qr/WebDyne Test File/, 'wdrender --psgi --test renders default test page');

    my ($psgi_head_out, $psgi_head_err, $psgi_head_rc)=run_cmd(
        $^X, '-Ilib', $script,
        '--psgi', '--head-insert', '--no-colour', '--no-tidy', '--no-lineno', '--test',
    );
    is($psgi_head_rc, 0, 'wdrender --psgi --head-insert exits cleanly');
    is($psgi_head_err, '', 'wdrender --psgi --head-insert writes no stderr');
    unlike($psgi_out, $head_insert_re, 'wdrender --psgi --test suppresses default head insert');
    like($psgi_head_out, $head_insert_re, 'wdrender --psgi --head-insert keeps default head insert');
}

SKIP: {
    require pagi_compat_helper;
    my $pagi_skip=pagi_compat_helper::pagi_skip_reason(qw(PAGI::Request PAGI::Response PAGI::Test::Client PAGI::SSE PAGI::WebSocket Future::AsyncAwait));
    skip "Skipping wdrender PAGI backend test: $pagi_skip", 3
        if $pagi_skip;
    eval { require WebDyne::PAGI; require PAGI::Test::Client; 1 }
        or skip "Skipping wdrender PAGI backend test: $@", 3;

    my ($pagi_out, $pagi_err, $pagi_rc)=run_cmd(
        $^X, '-Ilib', $script,
        '--pagi', '--no-colour', '--no-tidy', '--no-lineno', '--test',
    );
    is($pagi_rc, 0, 'wdrender --pagi --test exits cleanly');
    is($pagi_err, '', 'wdrender --pagi --test writes no stderr');
    like($pagi_out, qr/WebDyne Test File/, 'wdrender --pagi --test renders default test page');

    my ($pagi_head_out, $pagi_head_err, $pagi_head_rc)=run_cmd(
        $^X, '-Ilib', $script,
        '--pagi', '--head-insert', '--no-colour', '--no-tidy', '--no-lineno', '--test',
    );
    is($pagi_head_rc, 0, 'wdrender --pagi --head-insert exits cleanly');
    is($pagi_head_err, '', 'wdrender --pagi --head-insert writes no stderr');
    unlike($pagi_out, $head_insert_re, 'wdrender --pagi --test suppresses default head insert');
    like($pagi_head_out, $head_insert_re, 'wdrender --pagi --head-insert keeps default head insert');
}

SKIP: {
    require apache_harness_helper;
    my @missing=apache_harness_helper::apache_prereq_missing();
    skip 'Skipping wdrender Apache backend test: missing ' . join(', ', @missing), 5 if @missing;
    skip 'Skipping wdrender Apache backend test: cannot run tests as root user', 5 if $> == 0;

    my ($apache_out, $apache_err, $apache_rc)=run_cmd(
        $^X, '-Ilib', $script,
        '--mod_perl', '--no-colour', '--no-tidy', '--no-lineno', '--test',
    );
    if ($apache_rc && apache_harness_helper::apache_startup_unavailable($apache_err)) {
        skip 'Skipping wdrender Apache backend test: Apache test server unavailable', 5;
    }
    is($apache_rc, 0, 'wdrender --mod_perl --test exits cleanly');
    like($apache_out, qr/WebDyne Test File/, 'wdrender --mod_perl --test renders default test page');

    my ($apache_head_out, $apache_head_err, $apache_head_rc)=run_cmd(
        $^X, '-Ilib', $script,
        '--mod_perl', '--head-insert', '--no-colour', '--no-tidy', '--no-lineno', '--test',
    );
    is($apache_head_rc, 0, 'wdrender --mod_perl --head-insert exits cleanly');
    unlike($apache_out, $head_insert_re, 'wdrender --mod_perl --test suppresses default head insert');
    like($apache_head_out, $head_insert_re, 'wdrender --mod_perl --head-insert keeps default head insert');
}

done_testing();
