use strict;
use warnings;

use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin";
use bin_helper qw(run_cmd write_file write_module);
use File::Temp qw(tempdir);
use File::Spec;

my $script=File::Spec->catfile('bin', 'webdyne.pagi');
ok(-f $script, 'webdyne.pagi script exists');

BEGIN {
    my @missing;
    for my $m (qw(PAGI::Server PAGI::Middleware::Builder PAGI::Request PAGI::Response PAGI::SSE PAGI::WebSocket Future::AsyncAwait)) {
        eval "require $m; 1" or push @missing, $m;
    }
    @missing and plan skip_all => 'Skipping webdyne.pagi script test: missing ' . join(', ', @missing);
}

my $stub_dn=tempdir(CLEANUP => 1);
write_module($stub_dn, 'WebDyne::PAGI', <<'END_MODULE');
package WebDyne::PAGI;
use strict;
use warnings;
use WebDyne::Constant;
our $LAST_INDEX;
our $LAST_TITLE;
sub new {
    my ($class, %opt)=@_;
    $LAST_INDEX=$opt{index};
    $LAST_TITLE=$WEBDYNE_HTML_DEFAULT_TITLE;
    return bless \%opt, $class;
}
sub to_app {
    return sub {};
}
1;
END_MODULE

write_module($stub_dn, 'PAGI::Server::Runner', <<'END_MODULE');
package PAGI::Server::Runner;
use strict;
use warnings;
sub new { bless {}, shift }
sub parse_options {
    my ($self, @argv)=@_;
    $self->{argv}=\@argv;
    return $self;
}
sub run {
    my $self=shift;
    my $app=PAGI::Server::Runner::load_app();
    print "args=" . join(' ', @{$self->{argv} || []}) . "\n";
    print "env=" . ($ENV{PAGI_ENV} // '') . "\n";
    print "index=" . ($WebDyne::PAGI::LAST_INDEX // '') . "\n";
    print "app=" . ref($app) . "\n";
    return 0;
}
1;
END_MODULE

my $tmp_dn=tempdir(CLEANUP => 1);
my ($stdout, $stderr, $rc)=run_cmd(
    $^X, '-I', $stub_dn, '-Ilib', $script,
    '--no-index', '--no-static', '--env', 'production', '--argv', '--port 6011 --workers 2',
    $tmp_dn,
);
is($rc, 0, 'webdyne.pagi exits cleanly through stubbed runner');
like($stdout, qr/args=.*--port 6011 .*--workers 2 .*--env production .*--host 0\.0\.0\.0/, 'webdyne.pagi prepends argv options, env mode, and default host');
like($stdout, qr/env=production/, 'webdyne.pagi sets PAGI_ENV from --env');
like($stdout, qr/^index=0$/m, 'webdyne.pagi --no-index sets index false');
like($stdout, qr/app=CODE/, 'webdyne.pagi passes a built app coderef to PAGI::Runner');
is($stderr, '', 'webdyne.pagi stubbed run writes no stderr');

delete $ENV{PAGI_ENV};
($stdout, $stderr, $rc)=run_cmd(
    $^X, '-I', $stub_dn, '-Ilib', $script,
    '--no-index', '--no-static', '--argv', '--port 6012',
    $tmp_dn,
);
is($rc, 0, 'webdyne.pagi runs without --env');
unlike($stdout, qr/--env/, 'webdyne.pagi does not forward env mode when omitted');
like($stdout, qr/^env=$/m, 'webdyne.pagi leaves PAGI_ENV unset when --env is omitted');
is($stderr, '', 'webdyne.pagi no-env run writes no stderr');

($stdout, $stderr, $rc)=run_cmd(
    $^X, '-I', $stub_dn, '-Ilib', $script,
    '--no-static', '--index',
    $tmp_dn,
);
is($rc, 0, 'webdyne.pagi accepts bare --index');
like($stdout, qr/^index=1$/m, 'webdyne.pagi bare --index uses built-in index mode');
is($stderr, '', 'webdyne.pagi bare --index run writes no stderr');

($stdout, $stderr, $rc)=run_cmd(
    $^X, '-I', $stub_dn, '-Ilib', $script,
    '--no-static', '--index=home.psp',
    $tmp_dn,
);
is($rc, 0, 'webdyne.pagi accepts --index with string value');
like($stdout, qr/^index=home\.psp$/m, 'webdyne.pagi --index=FILE uses supplied default document');
is($stderr, '', 'webdyne.pagi --index=FILE run writes no stderr');

local $ENV{DOCUMENT_DEFAULT}='env-default.psp';
($stdout, $stderr, $rc)=run_cmd(
    $^X, '-I', $stub_dn, '-Ilib', $script,
    '--no-static',
    $tmp_dn,
);
is($rc, 0, 'webdyne.pagi accepts DOCUMENT_DEFAULT without index option');
like($stdout, qr/^index=env-default\.psp$/m, 'webdyne.pagi DOCUMENT_DEFAULT overrides default index mode');
is($stderr, '', 'webdyne.pagi DOCUMENT_DEFAULT run writes no stderr');

($stdout, $stderr, $rc)=run_cmd(
    $^X, '-I', $stub_dn, '-Ilib', $script,
    '--no-static', '--no-index',
    $tmp_dn,
);
is($rc, 0, 'webdyne.pagi accepts --no-index spelling');
like($stdout, qr/^index=0$/m, 'webdyne.pagi --no-index overrides DOCUMENT_DEFAULT');
is($stderr, '', 'webdyne.pagi --no-index run writes no stderr');

($stdout, $stderr, $rc)=run_cmd(
    $^X, '-I', $stub_dn, '-Ilib', $script,
    '--no-static', '--no-index', '--dump_opt', "--doc-root=$tmp_dn",
);
isnt($rc, 0, 'webdyne.pagi --dump_opt aborts after dumping options');
is($stdout, '', 'webdyne.pagi --dump_opt writes no stdout');
like($stderr, qr/'dump_opt'\s*=>\s*1/, 'webdyne.pagi --dump_opt dumps dump_opt flag');
like($stderr, qr/'no_index'\s*=>\s*(?:!!)?1/, 'webdyne.pagi --dump_opt dumps generated no_index flag');
like($stderr, qr/'no_static'\s*=>\s*(?:!!)?1/, 'webdyne.pagi --dump_opt dumps generated no_static flag');
like($stderr, qr/'root'\s*=>\s*'\Q$tmp_dn\E'/, 'webdyne.pagi --dump_opt dumps root alias value');

($stdout, $stderr, $rc)=run_cmd(
    $^X, '-I', $stub_dn, '-Ilib', $script,
    '--env', 'staging',
    $tmp_dn,
);
isnt($rc, 0, 'webdyne.pagi rejects invalid env mode');
like($stderr, qr/--env must be development, production, or none/, 'webdyne.pagi reports valid env modes');

my $load_dn=tempdir(CLEANUP => 1);
write_file("$load_dn/app.psp", "<start_html>pagi\n");
write_file("$load_dn/.webdyne.conf.pl", <<'END_CONF');
$_={
    'WebDyne::Constant' => {
        WEBDYNE_HTML_DEFAULT_TITLE => 'PAGI Root Config Loaded'
    }
};
END_CONF

local $ENV{DOCUMENT_ROOT}=$load_dn;
($stdout, $stderr, $rc)=run_cmd(
    $^X, '-I', $stub_dn, '-Ilib', '-e',
    'my $app=do "./bin/webdyne.pagi"; die($@ || $!) unless $app; print "title=" . ($WebDyne::PAGI::LAST_TITLE // "") . "\n";'
);
is($rc, 0, 'webdyne.pagi loads through external server path');
like($stdout, qr/^title=PAGI Root Config Loaded$/m, 'webdyne.pagi build loads DOCUMENT_ROOT .webdyne.conf.pl');
is($stderr, '', 'webdyne.pagi external load writes no stderr');

done_testing();
