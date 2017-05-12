#-*-Perl-*-

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use FindBin '$Bin';
use lib $Bin,"$Bin/../lib";

use Test::More;
use POSIX qw(ENOENT EISDIR ENOTDIR EINVAL ENOTEMPTY EACCES EIO 
             O_RDONLY O_WRONLY O_RDWR F_OK R_OK W_OK X_OK);
use select_dsn;

my @dsn = all_dsn();
plan tests => 1+ (29 * @dsn);

use_ok('DBI::Filesystem');

for my $dsn (@dsn) {
    diag("Testing with $dsn") if $ENV{HARNESS_VERBOSE};

    my $fs = DBI::Filesystem->new($dsn,{initialize=>1}) 
	or BAIL_OUT("failed to obtain a filesystem object");

    ok($fs->mkdir('a'),                'directory create 1');
    ok($fs->mkdir('a/b'),              'directory create 2');
    ok($fs->mkdir('a/b/c'),            'directory create 3');
    ok($fs->mknod('a/b/c/f.txt',0444), 'file create');   # read-only file

    # should be able to open file for reading, but not for writing
    my $inode = eval {$fs->open('a/b/c/f.txt',O_RDONLY)};
    is($@,'','read-only file can be opened for reading');
    $fs->release($inode) if $inode;

    $inode    = eval {$fs->open('a/b/c/f.txt',O_RDWR)};
    like($@,qr/permission denied/,'read-only file cannot be opened for writing 1');
    $fs->release($inode) if $inode;

    $inode    = eval {$fs->open('a/b/c/f.txt',O_WRONLY)};
    like($@,qr/permission denied/,'read-only file cannot be opened for writing 2');
    $fs->release($inode) if $inode;

    ok($fs->chmod('a/b/c/f.txt',0644),'chmod ok 1');

    $inode    = eval {$fs->open('a/b/c/f.txt',O_RDWR)};
    is($@,'','read/write file can be opened for read/write');
    $fs->release($inode) if $inode;
    
    $inode    = eval {$fs->open('a/b/c/f.txt',O_WRONLY)};
    is($@,'','read/write file can be opened for writing');
    $fs->release($inode) if $inode;

    ok($fs->chmod('a/b/c/f.txt',0220),'chmod ok 2');
    $inode    = eval {$fs->open('a/b/c/f.txt',O_WRONLY)};
    is($@,'','write only file can be opened for writing');
    $fs->release($inode) if $inode;

    $inode    = eval {$fs->open('a/b/c/f.txt',O_RDWR)};
    like($@,qr/permission denied/,'write-only file cannot be opened read/write');
    $fs->release($inode) if $inode;

    eval{$fs->chown('a/b/c/f.txt',0,0)};
    like($@,qr/permission denied/,'cannot change ownership of file without superuser privileges');
    
    my $uid = $<;
    my $gid = $(;
    my ($primary_gid,@supplementary_gid) = split /\s+/,$gid;
  SKIP: {
      skip('no supplementary GIDs to test',2) unless @supplementary_gid;
      ok(eval{$fs->chown('a/b/c/f.txt',$uid,$primary_gid)},'can chown to primary uid/gid');      
      ok(eval{$fs->chown('a/b/c/f.txt',$uid,$supplementary_gid[0])},'can chown to primary uid/ secondary gid');      
    };

    # change ownership to root to test group permission check
    $fs->ignore_permissions(1);
    $fs->chown('a/b/c/f.txt',0,$supplementary_gid[0]);
    $fs->ignore_permissions(0);

    ok($fs->chmod('a/b/c/f.txt',0060),'chmod ok 3');  # supplementary group read/write
    $inode    = eval {$fs->open('a/b/c/f.txt',O_RDWR)};
    is($@,'','supplementary group read/write file can be opened for read/write');
    $fs->release($inode) if $inode;

    $fs->ignore_permissions(1);
    $fs->chown('a/b/c/f.txt',0,$primary_gid);
    $fs->ignore_permissions(0);

    $inode    = eval {$fs->open('a/b/c/f.txt',O_RDWR)};
    is($@,'','primary group read/write file can be opened for read/write');
    $fs->release($inode) if $inode;

    # remove -x bit from directory
    ok($fs->chmod('a',0666),'chmod ok 4');
    eval {$fs->access('a/b/c/f.txt',F_OK)};
    like($@,qr/permission denied/,'access control via enclosing directory X byte');

    $inode = eval {$fs->open('a/b/c/f.txt',O_RDONLY)};
    like($@,qr/permission denied/,"can't open a file if enclosing directory is not executable");
    $fs->release($inode) if $inode;
    
    eval {$fs->getdir('a')};
    like($@,qr/permission denied/,"can't read a directory if directory is not executable");

    eval {$fs->getdir('a/b')};
    like($@,qr/permission denied/,"can't read a directory if enclosing directory is not executable");

    my @stat = eval{$fs->getattr('a/b/c/f.txt')};
    like($@,qr/permission denied/,"can't stat a file if enclosing directory is not executable");

    $fs->chmod('a',0777);
    $fs->chmod('a/b',0311); # executable, not readable

    @stat = eval{$fs->getattr('a/b/c/f.txt')};
    ok(scalar @stat,'can stat a file even if enclosing directory is not readable');

    @stat = eval{$fs->getattr('a/b/c')};
    ok(scalar @stat,'can stat a directory even if parent is not readable');

    @stat = eval{$fs->getattr('a/b')};
    ok(scalar @stat,'can stat a directory even if it is not readable');

    my @entries = eval {$fs->getdir('a/b')};
    like($@,qr/permission denied/,'cannot read directory that is not readable');

}

exit 0;
