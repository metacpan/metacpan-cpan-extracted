#-*-Perl-*-

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use FindBin '$Bin';
use lib $Bin,"$Bin/../lib";

use Test::More;
use File::Temp;
use POSIX qw(ENOENT EISDIR ENOTDIR EINVAL ENOTEMPTY EACCES EIO 
             O_RDONLY O_WRONLY O_RDWR F_OK R_OK W_OK X_OK);
use select_dsn;

$SIG{INT}=$SIG{TERM}=sub {exit 0 };
my ($child,$pid,$mtpt);

my @dsn = all_dsn();
plan tests => 1+ (22 * @dsn);

use_ok('DBI::Filesystem');
for my $dsn (@dsn) {
    diag("Testing with $dsn") if $ENV{HARNESS_VERBOSE};

    system "fusermount -u $mtpt 2>/dev/null" if $mtpt;

    my $fs = DBI::Filesystem->new($dsn,{initialize=>1}) 
	or BAIL_OUT("failed to obtain a filesystem object");

    $mtpt = File::Temp->newdir();
    
    $child = fork();
    defined $child or BAIL_OUT("fork failed: $!");
    if (!$child) {
	$fs->mount($mtpt,{mountopts=>'fsname=sqlfs'});
	exit 0;
    }

    wait_for_mount($mtpt,20) or BAIL_OUT("didn't see mountpoint appear");
    ok(1,'mountpoint appears');
    
    umask 002;
    ok(mkdir("$mtpt/dir1"),'mkdir');
    ok(-d "$mtpt/dir1",'directory exists');
    my @stat = stat("$mtpt/dir1");
    is($stat[2],040775,'stat correct');

    my $fh;

    open($fh,'>',"$mtpt/dir1");
    is($!,'Is a directory');
    close $fh;

    ok(!mkdir("$mtpt/.."),'refuse to create .. directory');
    is($!,'File exists','create duplicate directory blocked');
    ok(!rmdir("$mtpt/.."),'refuse to remove .. directory');
    is($!,'Directory not empty','remove .. directory blocked');

    ok(open($fh,'>',"$mtpt/dir1/test.txt"),'open for write ok');
    ok(print($fh "now is the time"),'print ok');
    ok(close($fh),'close ok');
    ok(open($fh,'<'."$mtpt/dir1/test.txt"),'open for read ok');
    my $data = <$fh>;
    is($data,'now is the time','read ok');
    close $fh;

    @stat = stat("$mtpt/dir1/test.txt");
    is($stat[7],length('now is the time'),'length ok');

    chmod(0200,"$mtpt/dir1/test.txt"); # write only
    ok(open($fh,'>',"$mtpt/dir1/test.txt"),'can open write-only file for writing');
    print $fh 'this is a test';
    close $fh;
    ok(!open($fh,'<',"$mtpt/dir1/test.txt"),"can't open write-only file for reading");
    chmod(0600,"$mtpt/dir1/test.txt"); # read/write
    ok(open($fh,'<',"$mtpt/dir1/test.txt"),"can open read/write file for reading");
    $data = <$fh>;
    is($data,'this is a test','contents match');
    close $fh;

    open($fh,'<'."$mtpt/dir1/test.txt");
    ok(unlink("$mtpt/dir1/test.txt"),'unlink ok');
    ok(!-e "$mtpt/dir1/test.txt",'path removed');
    $data = <$fh>;
    is($data,'this is a test','read on unlinked file ok');
    close $fh;

    sleep 2;
}    


exit 0;

END {
    system "fusermount -u $mtpt 2>/dev/null" if $mtpt;
    kill TERM=>$pid if $pid;
    waitpid($pid,0) if $pid;
}

sub wait_for_mount {
    my ($mtpt,$timeout) = @_;
    local $SIG{ALRM} = sub {die "timeout"};
    alarm($timeout);
    eval {
	while (1) {
	    my $df = `df $mtpt`;
	    last if $df =~ /^sqlfs/m;
	    sleep 1;
	}
	alarm(0);
    };
    return 1 unless $@;
}
