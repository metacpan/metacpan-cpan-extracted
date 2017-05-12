#
#
my $a = 0;
print "1..5\n";

use Win32::File qw(:DEFAULT GetAttributes SetAttributes);

# create a new file
open(F,">foo") or die "Can't create 'foo': $!";

SetAttributes('foo', NORMAL|ARCHIVE|HIDDEN|SYSTEM|READONLY) or print "not ";
print "ok 1\n";

GetAttributes('foo', $a) or print "not ";
print "ok 2\n";

($a & ARCHIVE)&&($a & HIDDEN)&&($a & SYSTEM)&&($a & READONLY) or print "not ";
print "ok 3\n";

SetAttributes('foo', NORMAL) or print "not ";
print "ok 4\n";

GetAttributes('foo', $a) and ($a & (ARCHIVE|HIDDEN|SYSTEM|READONLY))
and printf "# |%x|\nnot ", $a;
print "ok 5\n";

close(F);
unlink('foo') or die "$!";
