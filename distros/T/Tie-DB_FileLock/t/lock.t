use strict;
use Tie::DB_FileLock;

$| = 1;

print "1..5\n";

sub ok
{
    my $no = shift ;
    my $result = shift ;
 
    print "not " unless $result ;
    print "ok $no\n" ;
}

my %h;
my $db = tie(%h, 'Tie::DB_FileLock', 'mydb.tmp');
ok(1, $db);

$h{parent} = 1;
ok(2, $h{parent} == 1);

undef($db);
untie(%h);

unless (my $pid = fork()) {
	# child process.
	sleep(2);
#print STDERR "child run\n";
	my %g;
	tie(%g, 'Tie::DB_FileLock', 'mydb.tmp');
#print STDERR "child store\n";
	$g{set} = 'child';
	untie(%g);
	exit;
} else {
	# parent goes first.
#print STDERR "parent run\n";
	my %g;
	my $db = tie(%g, 'Tie::DB_FileLock', 'mydb.tmp');
#print STDERR "parent store\n";
	$g{set} = "parent";
#print STDERR "set: $g{set}\n";
	sleep(5);	# outwait the child.
#print STDERR "set: $g{set}\n";
	ok(3, $g{set} eq 'parent');
#print STDERR "parent unlock\n";
	$db->unlockDB();
	waitpid($pid, 0);
#print STDERR "child exit\n";
#print STDERR "set: $g{set}\n";
	$db->lockDB();
	ok(4, $g{set} eq 'child');
	$g{set} = 'parent';
	undef($db);
	untie(%g);
}

tie(%h, 'Tie::DB_FileLock', 'mydb.tmp');
ok(5, $h{set} eq 'parent');

unlink('mydb.tmp');
