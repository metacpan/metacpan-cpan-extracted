#-*-Perl-*-

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use FindBin '$Bin';
use lib $Bin,"$Bin/../lib";

use Test::More;
use POSIX qw(ENOENT EISDIR ENOTDIR EINVAL ENOTEMPTY EACCES EIO O_RDONLY);
use select_dsn;

my @dsn = all_dsn();
plan tests => 1+ (17 * @dsn);

use_ok('DBI::Filesystem');

umask 022;

for my $dsn (@dsn) {
    diag("Testing with $dsn") if $ENV{HARNESS_VERBOSE};

    my $fs = DBI::Filesystem->new($dsn,{initialize=>1}) 
	or BAIL_OUT("failed to obtain a filesystem object");

    ok($fs->mkdir('a'),              'directory create 1');
    ok($fs->mknod('a/file1.txt'),    'file create 1');

    my @stat = $fs->getattr('a');
    is($stat[2],0040777,'default directory mode');

    @stat    = $fs->getattr('a/file1.txt');
    is($stat[2],0100777,'default file mode');

    ok($fs->unlink('a/file1.txt'),'unlink');
    ok($fs->rmdir('a'),'rmdir');

    ok($fs->mkdir('a',0777&~umask()),           'directory create 2');
    ok($fs->mknod('a/file1.txt',0666&~umask()), 'file create 2');

    @stat  = $fs->getattr('a/file1.txt');
    is($stat[2],0100644,  'file mode set at creation');
    @stat  = $fs->getattr('a');
    is($stat[2],0040755,  'directory mode set at creation');
    $fs->chmod('a/file1.txt',0600);
    @stat  = $fs->getattr('a/file1.txt');
    is($stat[2],0100600,  'file mode can be changed');

    is($stat[4],$<,'uid matches');
    my ($gid) = $( =~ /^(\d+)/;
    is($stat[5],$gid,'gid matches');
    eval {$fs->chown('a/file1.txt',100,100)};
    like($@,qr/permission denied/,"permission checks forbid ownership change");
    $fs->ignore_permissions(1);

    ok(eval {$fs->chown('a/file1.txt',100,100)},'permission checks turn off');

    @stat  = $fs->getattr('a/file1.txt');
    is($stat[4],100,'uid can be changed');
    is($stat[5],100,'gid can be changed');

}



exit 0;
