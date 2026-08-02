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

my ($stdout, $stderr, $rc)=run_cmd(
    $^X, '-I', $stub_dn, '-Ilib', $script,
    '--port', '5123', '--no-index', $source_fn,
);
is($rc, 0, 'webdyne.apache exits cleanly through stubbed pause');
like($stdout, qr/-port\n5123/, 'webdyne.apache forwards requested port to Apache runner');
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
    like($env_err, qr/'index'\s*=>\s*'home\.psp'/, 'webdyne.apache DOCUMENT_DEFAULT seeds index option');
    like($env_err, qr/'no_index'\s*=>\s*(?:!!)?0/, 'webdyne.apache DOCUMENT_DEFAULT keeps no_index false');
    like($env_err, qr/'root'\s*=>\s*'\Q$tmp_dn\E'/, 'webdyne.apache DOCUMENT_ROOT seeds root option');
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
    like($env_no_err, qr/'index'\s*=>\s*0/, 'webdyne.apache --no-index overrides DOCUMENT_DEFAULT');
    like($env_no_err, qr/'no_index'\s*=>\s*(?:!!)?1/, 'webdyne.apache --no-index regenerates no_index true');
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
    like($seed_err, qr/'index'\s*=>\s*0/, 'webdyne.apache seeded no_index normalizes index false');
    like($seed_err, qr/'no_index'\s*=>\s*(?:!!)?1/, 'webdyne.apache seeded no_index regenerates no_index true');

    my ($override_out, $override_err, $override_rc)=run_cmd(
        $^X, '-I', $stub_dn, '-Ilib', $script,
        '--index', '--dump_opt',
    );
    isnt($override_rc, 0, 'webdyne.apache --index overrides seeded no_index and aborts after dump');
    is($override_out, '', 'webdyne.apache --index override dump writes no stdout');
    like($override_err, qr/'index'\s*=>\s*1/, 'webdyne.apache --index overrides seeded no_index');
    like($override_err, qr/'no_index'\s*=>\s*(?:!!)?0/, 'webdyne.apache --index regenerates no_index false');
}

my ($dump_out, $dump_err, $dump_rc)=run_cmd(
    $^X, '-I', $stub_dn, '-Ilib', $script,
    '--port', '5124', '--no-index', '--dump_opt', $source_fn,
);
isnt($dump_rc, 0, 'webdyne.apache --dump_opt aborts after dumping options');
is($dump_out, '', 'webdyne.apache --dump_opt writes no stdout');
like($dump_err, qr/'dump_opt'\s*=>\s*1/, 'webdyne.apache --dump_opt dumps dump_opt flag');
like($dump_err, qr/'no_index'\s*=>\s*(?:!!)?1/, 'webdyne.apache --dump_opt dumps generated no_index flag');
like($dump_err, qr/'root_pn'\s*=>\s*'\Q$source_fn\E'/, 'webdyne.apache --dump_opt dumps resolved file root');
#diag($stderr);
done_testing();
