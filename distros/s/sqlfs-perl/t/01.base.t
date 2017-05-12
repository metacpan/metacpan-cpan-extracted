#-*-Perl-*-

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use FindBin '$Bin';
use lib $Bin,"$Bin/../lib";

use Test::More;
use POSIX qw(ENOENT EISDIR ENOTDIR EINVAL ENOTEMPTY EACCES EIO);
use select_dsn;

my @dsn = all_dsn();
if (@dsn) {
   plan tests => 1+15*@dsn;
} else {
  plan skip_all => 'could not find a usable database source';
}

use_ok('DBI::Filesystem');
for my $dsn (@dsn) {
    diag("Testing with $dsn") if $ENV{HARNESS_VERBOSE};
    my $fs = DBI::Filesystem->new($dsn,{initialize=>1}) 
	or BAIL_OUT("failed to obtain a filesystem object");
    ok($fs,'filesystem object created');
    is($fs->dsn,$dsn,'dsn matches');
    ok($fs->dbh,'dbh created');
    is($fs->ignore_permissions(1),undef,'default restrictive permissions');
    is($fs->ignore_permissions(0),1,'can relax permissions');
    is($fs->mounted,undef,'mounted() reports correct state');
    is($fs->errno('foobar not found'),-ENOENT(),'errno ENOENT');
    is($fs->errno('foobar is a directory'),-EISDIR(),'errno EISDIR');
    is($fs->errno('foobar not a directory'),-ENOTDIR(),'errno ENOTDIR');
    is($fs->errno('length beyond end of file'),-EINVAL(),'errno EINVAL');
    is($fs->errno('permission denied'),-EACCES(),'errno EACCESS');
    
    open my $olderr,">&STDERR";
    close STDERR;
    my $stderr = '';
    open(STDERR,'>',\$stderr);
    is($fs->errno('# testing error reporting here'),-EIO(),'errno EIO');
    open STDERR,'>&',$olderr;
    like ($stderr,qr/testing error reporting here/,'unknown errors appear on STDERR');

    is($fs->blocksize,4096,'blocksize');
    ok($fs->flushblocks>0,'flushblocks');
}
