use strict;
use warnings;

use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin";
use bin_helper qw(run_cmd write_file write_module);
use File::Temp qw(tempdir);
use File::Spec;

my $script=File::Spec->catfile('bin', 'webdyne.apache');
ok(-f $script, 'webdyne.apache script exists');

my $stub_dn=tempdir(CLEANUP => 1);
write_module($stub_dn, 'Apache2::Build', "package Apache2::Build; 1;\n");
write_module($stub_dn, 'Apache::Test', "package Apache::Test; 1;\n");
write_module($stub_dn, 'Module::CoreList', "package Module::CoreList; 1;\n");
write_module($stub_dn, 'Apache::TestConfig', "package Apache::TestConfig; 1;\n");
write_module($stub_dn, 'Apache::TestRunPerl', <<'END_MODULE');
package Apache::TestRunPerl;
use strict;
use warnings;
sub new { bless {}, shift }
sub run {
    my ($self, @argv)=@_;
    print join("\n", @argv), "\n";
    CORE::exit 0;
}
1;
END_MODULE

my $tmp_dn=tempdir(CLEANUP => 1);
my $source_fn="$tmp_dn/app.psp";
write_file($source_fn, "<start_html>apache\n");
my $fake_apxs=File::Spec->catfile($tmp_dn, 'apxs');
write_file($fake_apxs, "#!/bin/sh\nprintf '%s\\n' '$tmp_dn'\n");
chmod 0755, $fake_apxs or die "unable to make fake apxs executable: $!";

my ($stdout, $stderr, $rc);
{
    local $ENV{'APACHE_TEST_HTTPD'}='/tmp/webdyne-test-httpd';
    local $ENV{'APACHE_TEST_APXS'}=$fake_apxs;
    ($stdout, $stderr, $rc)=run_cmd(
        $^X, '-I', $stub_dn, '-Ilib', $script,
        '--port', '5123', '--no-index', $source_fn,
    );
}
is($rc, 0, 'webdyne.apache exits cleanly through stubbed pause');
like($stdout, qr/-httpd\s+\/tmp\/webdyne-test-httpd/, 'webdyne.apache forwards explicit Apache test httpd');
like($stdout, qr/-apxs\s+\Q$fake_apxs\E/, 'webdyne.apache forwards explicit Apache test apxs');
like($stdout, qr/-port\s+5123/, 'webdyne.apache forwards requested port to Apache runner');
like($stdout, qr/PerlSetEnv DOCUMENT_ROOT \Q$source_fn\E/, 'webdyne.apache preserves file root as DOCUMENT_ROOT in postamble');
unlike($stdout, qr/Alias \/index\.psp/, 'webdyne.apache --no-index omits index alias postamble for file-root startup');
like($stderr, qr/^(?:|unable to write to stderr,stdout - reverting to log files\n)$/, 'webdyne.apache stubbed run writes no unexpected stderr');

{
    local $ENV{DOCUMENT_ROOT}=$tmp_dn;
    local $ENV{DOCUMENT_DEFAULT}='home.psp';
    my ($env_out, $env_err, $env_rc)=run_cmd(
        $^X, '-I', $stub_dn, '-Ilib', $script,
        '--dump_opt',
    );
    isnt($env_rc, 0, 'webdyne.apache --dump_opt aborts after dumping environment-derived options');
    is($env_out, '', 'webdyne.apache environment dump writes no stdout');
    my $env_opt_hr=dump_opt_hash($env_err);
    is($env_opt_hr->{'index'}, 'home.psp', 'webdyne.apache DOCUMENT_DEFAULT seeds index option');
    ok(!$env_opt_hr->{'no_index'}, 'webdyne.apache DOCUMENT_DEFAULT keeps no_index false');
    is($env_opt_hr->{'root'}, $tmp_dn, 'webdyne.apache DOCUMENT_ROOT seeds root option');
}

{
    local $ENV{DOCUMENT_ROOT}=$tmp_dn;
    local $ENV{DOCUMENT_DEFAULT}='home.psp';
    my ($env_no_out, $env_no_err, $env_no_rc)=run_cmd(
        $^X, '-I', $stub_dn, '-Ilib', $script,
        '--no-index', '--dump_opt',
    );
    isnt($env_no_rc, 0, 'webdyne.apache --no-index --dump_opt aborts after dumping options');
    is($env_no_out, '', 'webdyne.apache --no-index environment dump writes no stdout');
    my $env_no_opt_hr=dump_opt_hash($env_no_err);
    ok(!$env_no_opt_hr->{'index'}, 'webdyne.apache --no-index overrides DOCUMENT_DEFAULT');
    ok($env_no_opt_hr->{'no_index'}, 'webdyne.apache --no-index regenerates no_index true');
}

{
    my $home_dn=tempdir(CLEANUP => 1);
    write_file("$home_dn/.webdyne.apache.opt", "{ no_index => 1 }\n");
    local $ENV{HOME}=$home_dn;
    my ($seed_out, $seed_err, $seed_rc)=run_cmd(
        $^X, '-I', $stub_dn, '-Ilib', $script,
        '--dump_opt',
    );
    isnt($seed_rc, 0, 'webdyne.apache seeded no_index --dump_opt aborts after dumping options');
    is($seed_out, '', 'webdyne.apache seeded no_index dump writes no stdout');
    my $seed_opt_hr=dump_opt_hash($seed_err);
    ok(!$seed_opt_hr->{'index'}, 'webdyne.apache seeded no_index normalizes index false');
    ok($seed_opt_hr->{'no_index'}, 'webdyne.apache seeded no_index regenerates no_index true');

    my ($override_out, $override_err, $override_rc)=run_cmd(
        $^X, '-I', $stub_dn, '-Ilib', $script,
        '--index', '--dump_opt',
    );
    isnt($override_rc, 0, 'webdyne.apache --index overrides seeded no_index and aborts after dump');
    is($override_out, '', 'webdyne.apache --index override dump writes no stdout');
    my $override_opt_hr=dump_opt_hash($override_err);
    ok($override_opt_hr->{'index'}, 'webdyne.apache --index overrides seeded no_index');
    ok(!$override_opt_hr->{'no_index'}, 'webdyne.apache --index regenerates no_index false');
}

my ($dump_out, $dump_err, $dump_rc)=run_cmd(
    $^X, '-I', $stub_dn, '-Ilib', $script,
    '--port', '5124', '--no-index', '--dump_opt', $source_fn,
);
isnt($dump_rc, 0, 'webdyne.apache --dump_opt aborts after dumping options');
is($dump_out, '', 'webdyne.apache --dump_opt writes no stdout');
my $dump_opt_hr=dump_opt_hash($dump_err);
ok($dump_opt_hr->{'dump_opt'}, 'webdyne.apache --dump_opt dumps dump_opt flag');
ok($dump_opt_hr->{'no_index'}, 'webdyne.apache --dump_opt dumps generated no_index flag');
is($dump_opt_hr->{'root_pn'}, $source_fn, 'webdyne.apache --dump_opt dumps resolved file root');
#diag($stderr);
done_testing();


sub dump_opt_hash {

    my $dump=shift();
    my $VAR1;
    my $ok=eval "$dump; 1";
    die "unable to parse dumped webdyne.apache options: $@" unless $ok;
    die "dumped webdyne.apache options are not a hash reference"
        unless ref($VAR1) eq 'HASH';
    return $VAR1;

}
