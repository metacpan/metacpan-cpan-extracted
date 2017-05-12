# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Unix-Mknod.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 11 };
use Unix::Mknod qw(:all);
use Fcntl qw(:mode);
use File::stat;

$file='/tmp/special';

#########################

# Check to make sure major maps back to itself
ok(major(makedev(10,2)), 10);

# Same with minor
ok(minor(makedev(7,5)), 5);

# Check that makedev does as well, using the rdev from /dev/null
my ($st)=stat('/dev/null');
ok(makedev(major($st->rdev), minor($st->rdev)), $st->rdev);

# Can only run mknod if we are root
skip (
	($< != 0? "Test needs to be run as root": 0),
	mknod($file, S_IFCHR|0600, makedev(1,2)),
	0
);

$st=stat($file);
skip (
	($< != 0? "Test needs to be run as root": 0),
	defined($st) && &S_ISCHR($st->mode)
);
skip (
	($< != 0? "Test needs to be run as root": 0),
	defined($st) && !&S_ISBLK($st->mode)
);
skip(
	($< != 0? "Test needs to be run as root": 0),
	defined($st) && ($st->mode & S_IRUSR|S_IWUSR)
);
unlink $file
	if ( -e $file);

skip (
	($< != 0? "Test needs to be run as root": 0),
	mknod($file, S_IFBLK|0600, makedev(1,2)),
	0
);
$st=stat($file);
skip (
	($< != 0? "Test needs to be run as root": 0),
	defined($st) && &S_ISBLK($st->mode)
);
skip (
	($< != 0? "Test needs to be run as root": 0),
	defined($st) && !&S_ISCHR($st->mode)
);
skip (
	($< != 0? "Test needs to be run as root": 0),
	defined($st) && ($st->mode & S_IRUSR|S_IWUSR)
);

unlink $file
	if ( -e $file);

