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
plan tests => 1+ (17 * @dsn);

use_ok('DBI::Filesystem');

for my $dsn (@dsn) {
    diag("Testing with $dsn") if $ENV{HARNESS_VERBOSE};

    my $fs = DBI::Filesystem->new($dsn,{initialize=>1}) 
	or BAIL_OUT("failed to obtain a filesystem object");

    ok($fs->mkdir('a'),                'directory create');
    ok($fs->mknod('a/test.txt',0666),  'file create');
    
    my $inode = $fs->open('a/test.txt',O_RDWR);
    ok($inode,'file open');
    
    ok($fs->write('a/test.txt','now is the time for all good men',0)>0,  'path write');
    is($fs->read('a/test.txt',1024,0),'now is the time for all good men','path read');

    ok($fs->write(undef,'this is the time for all good men',0,$inode)>0,  'inode write');
    is($fs->read(undef,1024,0,$inode),'this is the time for all good men','inode read');

    is($fs->read('a/test.txt',1024,5),'is the time for all good men','path offset read');

    is($fs->write('a/test.txt','date',12),4,'inode write with offset');
    is($fs->read('a/test.txt',1024,0),'this is the date for all good men','random update');

    my $blocksize = $fs->blocksize;
    my $bigdata = 'a'x($blocksize*2);
    is($fs->write('a/test.txt',$bigdata,0),$blocksize*2,'write two blocks');
    is($fs->read('a/test.txt',$blocksize*3,0),$bigdata, 'read two blocks');

    # holes
    $bigdata = 'a'x$blocksize;
    ok($fs->truncate('a/test.txt',0),'truncate');
    is($fs->write('a/test.txt',$bigdata,0),$blocksize,'write one block');
    is($fs->write('a/test.txt',$bigdata,$blocksize*2),$blocksize,'skip one block');
    is($fs->read('a/test.txt',$blocksize*10,0),
       ('a'x$blocksize."\0"x$blocksize.'a'x$blocksize),'hole present');

    my $dbh = $fs->dbh;
    my ($rows) = $dbh->selectrow_array("select count(*) from extents where inode=$inode");
    is($rows,2,'hole is not present among extents');

    $fs->release($inode);
}

exit 0;
