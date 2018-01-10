use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More 0.94;

plan tests => 54;

my @module_files = (
    'URI.pm',
    'URI/Escape.pm',
    'URI/Heuristic.pm',
    'URI/IRI.pm',
    'URI/QueryParam.pm',
    'URI/Split.pm',
    'URI/URL.pm',
    'URI/WithBase.pm',
    'URI/_foreign.pm',
    'URI/_generic.pm',
    'URI/_idna.pm',
    'URI/_ldap.pm',
    'URI/_login.pm',
    'URI/_punycode.pm',
    'URI/_query.pm',
    'URI/_segment.pm',
    'URI/_server.pm',
    'URI/_userpass.pm',
    'URI/data.pm',
    'URI/file.pm',
    'URI/file/Base.pm',
    'URI/file/FAT.pm',
    'URI/file/Mac.pm',
    'URI/file/OS2.pm',
    'URI/file/QNX.pm',
    'URI/file/Unix.pm',
    'URI/file/Win32.pm',
    'URI/ftp.pm',
    'URI/gopher.pm',
    'URI/http.pm',
    'URI/https.pm',
    'URI/ldap.pm',
    'URI/ldapi.pm',
    'URI/ldaps.pm',
    'URI/mailto.pm',
    'URI/mms.pm',
    'URI/news.pm',
    'URI/nntp.pm',
    'URI/pop.pm',
    'URI/rlogin.pm',
    'URI/rsync.pm',
    'URI/rtsp.pm',
    'URI/rtspu.pm',
    'URI/sftp.pm',
    'URI/sip.pm',
    'URI/sips.pm',
    'URI/snews.pm',
    'URI/ssh.pm',
    'URI/telnet.pm',
    'URI/tn3270.pm',
    'URI/urn.pm',
    'URI/urn/isbn.pm',
    'URI/urn/oid.pm'
);



# no fake home requested

my @switches = (
    -d 'blib' ? '-Mblib' : '-Ilib',
);

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-e', "require q[$lib]"))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', explain(\@warnings);

BAIL_OUT("Compilation problems") if !Test::More->builder->is_passing;
