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
plan tests => 1+ (49 * @dsn);

use_ok('DBI::Filesystem');

for my $dsn (@dsn) {
    diag("Testing with $dsn") if $ENV{HARNESS_VERBOSE};

    my $fs = DBI::Filesystem->new($dsn,{initialize=>1}) 
	or BAIL_OUT("failed to obtain a filesystem object");

# directories
    ok($fs->mkdir('a'),     'directory create 1');
    ok($fs->mkdir('a/1'),   'directory create 2');
    ok($fs->mkdir('a/1/i'), 'directory create 3');
    ok($fs->mkdir('a/1/ii'),'directory create 4');

    eval {$fs->mkdir('a/2/i')};
    like($@,qr{a/2 not found},'cannot create path if parent directory nonexistent');

    ok($fs->mkdir('a/2'),   'directory create 5');
    ok($fs->mkdir('a/2/i'), 'directory create 6');
    ok($fs->mkdir('a/2/ii'),'directory create 7');
    ok($fs->mkdir('b'),     'directory create 8');
    ok($fs->mkdir('b/1'),   'directory create 9');
    ok($fs->mkdir('b/1/i'), 'directory create 10');
    ok($fs->mkdir('b/1/ii'),'directory create 11');
    ok($fs->mkdir('b/2'),   'directory create 12');
    ok($fs->mkdir('b/2/i'), 'directory create 13');
    ok($fs->mkdir('b/2/ii'),'directory create 14');
    
    ok($fs->mknod('a/file1.txt'),    'file create 1');
    ok($fs->mknod('a/file2.txt'),    'file create 2');
    ok($fs->mknod('a/1/i/file3.txt'),'file create 3');
    ok($fs->mknod('a/1/i/file4.txt'),'file create 4');
    
    eval {$fs->mknod('c/file3.txt')};
    like($@,qr{c not found},'cannot create file if parent directory nonexistent');
    
    eval {$fs->mknod('a/file1.txt')};
    like($@,qr{file exists},'cannot create file if path already exists');

    my @entries = $fs->getdir('/');
    is_deeply(\@entries,['.','..','a','b'],'directory lookup matches root');

    @entries = $fs->getdir('a');
    is_deeply(\@entries,['.','..',1,2,'file1.txt','file2.txt'],'directory lookup matches 1');

    @entries    = $fs->getdir('a/1');
    is_deeply(\@entries,['.','..','i','ii'],'directory lookup matches 2');

    my @entries2    = $fs->getdir('/a/1');
    is_deeply(\@entries,\@entries2,'leading slash is ignored');

    ok($fs->rename('a/file1.txt','a/1/file1.txt'),'rename returns true value');
    @entries    = $fs->getdir('a');
    is_deeply(\@entries,['.','..',1,2,'file2.txt'],'original path disappears after rename');    

    @entries    = $fs->getdir('a/1');
    is_deeply(\@entries,['.','..','file1.txt','i','ii'],'new path appears after rename');    

    ok($fs->link('a/1/file1.txt','a/1/file2.txt'),'hard linking works');
    @entries    = $fs->getdir('a/1');
    is_deeply(\@entries,['.','..','file1.txt','file2.txt','i','ii'],'hard link appears in directory');        

    is($fs->path2inode('a/1/file1.txt'),$fs->path2inode('a/1/file2.txt'),'hard linked files share same inode'),
    my @paths = $fs->inode2paths($fs->path2inode('a/1/file1.txt'));
    is_deeply(\@paths,['/a/1/file1.txt','/a/1/file2.txt'],'reverse inode lookup');

    isnt(eval{$fs->link('a/1','a/bad')},1,'directory hard linking not allowed');

    my @stat1 = $fs->getattr('a/1/file1.txt');
    is($stat1[3],2,'hard linked file has two nlink');

    my @stat2 = $fs->getattr('a/1/file2.txt');
    is_deeply(\@stat1,\@stat2,'hard linked files have same stat structure');

    ok($fs->unlink('a/1/file2.txt'),'unlinking works');
    @stat1 =  $fs->getattr('a/1/file1.txt');
    is($stat2[3],2,'hard linked file has one nlink after removing other link');

    eval{$fs->getattr('a/1/file2.txt')};
    like($@,qr/not found/,'linked path gone');

    eval {$fs->rmdir('b/2')};
    like($@,qr/not empty/,"can't unlink populated directory");
    ok($fs->rmdir('b/2/i'), 'remove empty directory 1');
    ok($fs->rmdir('b/2/ii'),'remove empty directory 2');
    ok($fs->rmdir('b/2'),   'remove empty directory 3');

    my $inode = $fs->open('a/1/file1.txt',O_RDONLY);
    @stat1    = $fs->getattr('a/1/file1.txt');
    @stat2    = $fs->fgetattr('a/1/file1.txt',$inode);
    is_deeply(\@stat1,\@stat2,'getattr() and fgetattr() agree');

    $fs->unlink('a/1/file1.txt');
    eval {$fs->getattr('a/1/file1.txt')};
    like($@,qr/not found/,'getattr on unlinked file raises exception');

    @stat1    = $fs->fgetattr('a/1/file1.txt',$inode);
    is($stat1[3],0,'fgetattr() on open inode still works');    
    $fs->release($inode);

    eval {$fs->fgetattr('a/1/file1.txt',$inode)};
    like($@,qr/not found/,'fgetattr raises exception after unlinked file is released');

    ok($fs->symlink('b','c'),'symlink create');
    is($fs->readlink('c'),'b','symlink read');

    eval{$fs->symlink('a','c')};
    like($@,qr{file exists},'cannot create symlink if path already exists');
}



exit 0;
