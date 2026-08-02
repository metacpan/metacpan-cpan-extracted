use strict;
use warnings;

use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin";
use bin_helper qw(run_cmd write_module write_file);
use File::Temp qw(tempdir tempfile);
use File::Spec;

my $script=File::Spec->catfile('bin', 'webdyne.psgi');
ok(-f $script, 'webdyne.psgi script exists');

BEGIN {
    my @missing;
    for my $m (qw(Plack::Builder Plack::Request Plack::Response)) {
        eval "require $m; 1" or push @missing, $m;
    }
    @missing and plan skip_all => 'Skipping webdyne.psgi script test: missing ' . join(', ', @missing);
}

my $stub_dn=tempdir(CLEANUP => 1);
write_module($stub_dn, 'WebDyne::PSGI', <<'END_MODULE');
package WebDyne::PSGI;
use strict;
use warnings;
our $LAST_INDEX;
sub new {
    my ($class, %opt)=@_;
    $LAST_INDEX=$opt{index};
    return bless \%opt, $class;
}
sub to_app {
    return sub {
        return [200, [], ['psgi']];
    };
}
1;
END_MODULE

write_module($stub_dn, 'Plack::Runner', <<'END_MODULE');
package Plack::Runner;
use strict;
use warnings;
sub new { bless {}, shift }
sub parse_options {
    my ($self, @argv)=@_;
    $self->{argv}=\@argv;
    return $self;
}
sub run {
    my ($self, $app)=@_;
    open(my $input_fh, '<', '/dev/null') || die $!;
    my $res=$app->({
        REQUEST_METHOD     => 'GET',
        PATH_INFO          => '/app.psp',
        SCRIPT_NAME        => '',
        SERVER_NAME        => 'localhost',
        SERVER_PORT        => 80,
        'psgi.version'     => [1, 1],
        'psgi.url_scheme'  => 'http',
        'psgi.input'       => $input_fh,
        'psgi.errors'      => *STDERR,
        'psgi.multithread' => 0,
        'psgi.multiprocess'=> 0,
        'psgi.run_once'    => 1,
        'psgi.streaming'   => 0,
        'psgi.nonblocking' => 0,
    });
    print "args=" . join(' ', @{$self->{argv} || []}) . "\n";
    print "env=" . ($ENV{PLACK_ENV} // '') . "\n";
    print "index=" . ($WebDyne::PSGI::LAST_INDEX // '') . "\n";
    print "status=$res->[0]\n";
    print "body=" . join('', @{$res->[2]}) . "\n";
    return 0;
}
1;
END_MODULE

my $tmp_dn=tempdir(CLEANUP => 1);
write_file("$tmp_dn/app.psp", "<start_html>psgi\n");

my ($stdout, $stderr, $rc)=run_cmd(
    $^X, '-I', $stub_dn, '-Ilib', $script,
    '--no-index', '--no-static', '--env', 'production', '--argv', '--port 6021',
    $tmp_dn,
);
#diag($stdout);
is($rc, 0, 'webdyne.psgi exits cleanly through stubbed runner');
like($stdout, qr/args=.*--port 6021 .*--env production/, 'webdyne.psgi forwards argv options and env mode to Plack::Runner');
like($stdout, qr/env=production/, 'webdyne.psgi sets PLACK_ENV from --env');
like($stdout, qr/^index=0$/m, 'webdyne.psgi --no-index sets index false');
like($stdout, qr/status=200/, 'webdyne.psgi built app serves request through stubbed runner');
like($stdout, qr/body=.*psgi/s, 'webdyne.psgi built app returns rendered body');
is($stderr, '', 'webdyne.psgi stubbed run writes no stderr');

delete $ENV{PLACK_ENV};
($stdout, $stderr, $rc)=run_cmd(
    $^X, '-I', $stub_dn, '-Ilib', $script,
    '--no-index', '--no-static', '--argv', '--port 6022',
    $tmp_dn,
);
is($rc, 0, 'webdyne.psgi runs without --env');
unlike($stdout, qr/--env/, 'webdyne.psgi does not forward env mode when omitted');
like($stdout, qr/^env=$/m, 'webdyne.psgi leaves PLACK_ENV unset when --env is omitted');
is($stderr, '', 'webdyne.psgi no-env run writes no stderr');

($stdout, $stderr, $rc)=run_cmd(
    $^X, '-I', $stub_dn, '-Ilib', $script,
    '--no-static', '--index',
    $tmp_dn,
);
is($rc, 0, 'webdyne.psgi accepts bare --index');
like($stdout, qr/^index=1$/m, 'webdyne.psgi bare --index uses built-in index mode');
is($stderr, '', 'webdyne.psgi bare --index run writes no stderr');

($stdout, $stderr, $rc)=run_cmd(
    $^X, '-I', $stub_dn, '-Ilib', $script,
    '--no-static', '--index=home.psp',
    $tmp_dn,
);
is($rc, 0, 'webdyne.psgi accepts --index with string value');
like($stdout, qr/^index=home\.psp$/m, 'webdyne.psgi --index=FILE uses supplied default document');
is($stderr, '', 'webdyne.psgi --index=FILE run writes no stderr');

local $ENV{DOCUMENT_DEFAULT}='env-default.psp';
($stdout, $stderr, $rc)=run_cmd(
    $^X, '-I', $stub_dn, '-Ilib', $script,
    '--no-static',
    $tmp_dn,
);
is($rc, 0, 'webdyne.psgi accepts DOCUMENT_DEFAULT without index option');
like($stdout, qr/^index=env-default\.psp$/m, 'webdyne.psgi DOCUMENT_DEFAULT overrides default index mode');
is($stderr, '', 'webdyne.psgi DOCUMENT_DEFAULT run writes no stderr');

($stdout, $stderr, $rc)=run_cmd(
    $^X, '-I', $stub_dn, '-Ilib', $script,
    '--no-static', '--no-index',
    $tmp_dn,
);
is($rc, 0, 'webdyne.psgi accepts --no-index spelling');
like($stdout, qr/^index=0$/m, 'webdyne.psgi --no-index overrides DOCUMENT_DEFAULT');
is($stderr, '', 'webdyne.psgi --no-index run writes no stderr');

($stdout, $stderr, $rc)=run_cmd(
    $^X, '-I', $stub_dn, '-Ilib', $script,
    '--no-static', '--no-index', '--dump_opt', "--doc-root=$tmp_dn",
);
isnt($rc, 0, 'webdyne.psgi --dump_opt aborts after dumping options');
is($stdout, '', 'webdyne.psgi --dump_opt writes no stdout');
like($stderr, qr/'dump_opt'\s*=>\s*1/, 'webdyne.psgi --dump_opt dumps dump_opt flag');
like($stderr, qr/'no_index'\s*=>\s*(?:!!)?1/, 'webdyne.psgi --dump_opt dumps generated no_index flag');
like($stderr, qr/'no_static'\s*=>\s*(?:!!)?1/, 'webdyne.psgi --dump_opt dumps generated no_static flag');
like($stderr, qr/'root'\s*=>\s*'\Q$tmp_dn\E'/, 'webdyne.psgi --dump_opt dumps root alias value');

($stdout, $stderr, $rc)=run_cmd(
    $^X, '-I', $stub_dn, '-Ilib', $script,
    '--env', 'staging',
    $tmp_dn,
);
isnt($rc, 0, 'webdyne.psgi rejects invalid env mode');
like($stderr, qr/--env must be development, production, or none/, 'webdyne.psgi reports valid env modes');

done_testing();
