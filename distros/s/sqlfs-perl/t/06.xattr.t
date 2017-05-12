#-*-Perl-*-

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use FindBin '$Bin';
use lib $Bin,"$Bin/../lib";

use Test::More;
use POSIX qw(ENOENT EISDIR ENOTDIR EINVAL ENOTEMPTY EACCES EIO 
             O_RDONLY O_WRONLY O_RDWR F_OK R_OK W_OK X_OK);
use Fuse ':xattr';
use select_dsn;

my @dsn = all_dsn();
plan tests => 1+ (10 * @dsn);

use_ok('DBI::Filesystem');

for my $dsn (@dsn) {
    diag("Testing with $dsn") if $ENV{HARNESS_VERBOSE};

    my $fs = DBI::Filesystem->new($dsn,{initialize=>1}) 
	or BAIL_OUT("failed to obtain a filesystem object");

    ok($fs->mkdir('a'),                'directory create');
    ok($fs->mknod('a/test.txt',0666),  'file create');

    is($fs->setxattr('a/test.txt','Author','John Doe',0),0,'setxattr create with flags 0');
    is($fs->setxattr('a/test.txt','Author','John Donn',0),0,'setxattr replace with flags 0');
    is($fs->setxattr('a/test.txt','Author','Jane Doe', XATTR_REPLACE),0,'setxattr with XATTR_REPLACE');
    is($fs->setxattr('a/test.txt','Editor','Jane Fonda',XATTR_CREATE),0,'setxattr with XATTR_CREATE');

    eval {$fs->setxattr('a/test.txt','Author','Jane Fonda',XATTR_CREATE)};
    like($@,qr/attribute exists/,'setxattr with XATTR_CREATE on existing value');

    eval {$fs->setxattr('a/test.txt','Auditor','Plain Jane',XATTR_REPLACE)};
    like($@,qr/no such attribute/,'setxattr with XATTR_REPLACE on nonexisting');

    my @l = $fs->listxattr('a/test.txt');
    is_deeply(\@l,['Author','Editor'],'listxattr');

    is($fs->getxattr('a/test.txt','Author'),'Jane Doe','getxattr');
}

exit 0;
