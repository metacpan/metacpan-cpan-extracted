print "1..62\n";

$Dfile="TEST.DAT";
$DBFDL = "FILE; ORGANIZATION indexed; RECORD; CARRIAGE_CONTROL carriage_return; FORMAT variable; SIZE 10;" .
         "KEY 0; CHANGES no; DUPLICATES no;  SEG0_POSITION 0; SEG0_LENGTH 3; TYPE string;" .
         "KEY 1; CHANGES no; DUPLICATES yes; SEG0_POSITION 3; SEG0_LENGTH 2; SEG1_POSITION 0; SEG1_LENGTH 3; TYPE string;";

use VMS::IndexedFile;

($h = tie (%h, VMS::IndexedFile, $Dfile, 0, O_RDWR | O_TRUNC, $DBFDL)) || die "failed 1\n";
print "ok 1\n";

# put some data in
print ((($h{'ABC'}='ABC54321') eq 'ABC54321') ? "ok 2\n" : "not ok 2\n");
print ((($h{'DEF'}='DEF23456') eq 'DEF23456') ? "ok 3\n" : "not ok 3\n");
print ($h->store('GHI34567') ? "ok 4\n" : "not ok 4\n");
print ($h->store('abc12345') ? "ok 5\n" : "not ok 5\n");
print ($h->store('ABC54333') ? "ok 6\n" : "not ok 6\n");      # replace record 'ABC54321'
                                                              # - valid since key 1 doesn't change (see test #18)

# retrieve some data
print ($h{'ABC'} eq 'ABC54333' ? "ok 7\n" : "not ok 7\n");
print ($h{''}    eq 'DEF23456' ? "ok 8\n" : "not ok 8\n");
print ($h{'abc'} eq 'abc12345' ? "ok 9\n" : "not ok 9\n");
print ($h{'a'}   eq 'abc12345' ? "ok 10\n" : "not ok 10\n");
print ($h{''}    eq ''         ? "ok 11\n" : "not ok 11\n");


# these stores should all fail
print (((!$h->store('a'))               && ($!=~/^invalid record size/))    ? "ok 12\n" : "not ok 12\n");   # record too short
print ((($h{'a'} = 'a') ne 'a')                                             ? "ok 13\n" : "not ok 13\n");   # same as 12
print (((!$h->store('123456789012345')) && ($!=~/^invalid record size/))    ? "ok 14\n" : "not ok 14\n");   # record too long
print ($h->replace(0) == 1 ? "ok 15\n" : "not ok 15\n");
print (((!$h->store('ABC12345'))        && ($!=~/^duplicate key detected/)) ? "ok 16\n" : "not ok 16\n");   # duplicate key
print ($h->replace(1) == 0 ? "ok 17\n" : "not ok 17\n");
print (((!$h->store('ABC11111'))        && ($!=~/^invalid key change/))     ? "ok 18\n" : "not ok 18\n");   # no changes allowed
                                                                                                            # to key 1

# these fetches should all fail
print (((!$h{'123'})                    && ($!=~/^record not found/))       ? "ok 18\n" : "not ok 18\n");   # no such record
print (((!$h{'abcd'})                   && ($!=~/^invalid key size/))       ? "ok 19\n" : "not ok 19\n");   # key too long


# Do keys(), values(), and $# work?
@keys = keys(%h); 
@values = values(%h);
print ($#keys   == 3 ? "ok 20\n" : "not ok 20\n");
print ($#values == 3 ? "ok 21\n" : "not ok 21\n");

print (untie(%h) ? "ok 22\n" : "not ok 22\n");


# Check order and number of pairs returned using primary key
print (($h = tie (%h, VMS::IndexedFile, $Dfile)) ? "ok 23\n" : "not ok 23\n");
$i = 0;
while(($key,$value) = each(%h))
{
  if ($i == 0) {print ((($key eq "ABC") && ($value eq "ABC54333")) ? "ok 24\n" : "not ok 24\n"); }
  if ($i == 1) {print ((($key eq "DEF") && ($value eq "DEF23456")) ? "ok 25\n" : "not ok 25\n"); }
  if ($i == 2) {print ((($key eq "GHI") && ($value eq "GHI34567")) ? "ok 26\n" : "not ok 26\n"); }
  if ($i == 3) {print ((($key eq "abc") && ($value eq "abc12345")) ? "ok 27\n" : "not ok 27\n"); }
  $i++;
}
print ($i == 4 ? "ok 28\n" : "not ok 28\n");
print (untie(%h) ? "ok 29\n" : "not ok 29\n");


# Check order and number of pairs returned using first alternate key
print (($h = tie (%h, VMS::IndexedFile, $Dfile, 1)) ? "ok 30\n" : "not ok 30\n");
$i = 0;
while(($key,$value) = each(%h))
{
  if ($i == 0) {print ((($key eq "12abc") && ($value eq "abc12345")) ? "ok 31\n" : "not ok 31\n"); }
  if ($i == 1) {print ((($key eq "23DEF") && ($value eq "DEF23456")) ? "ok 32\n" : "not ok 32\n"); }
  if ($i == 2) {print ((($key eq "34GHI") && ($value eq "GHI34567")) ? "ok 33\n" : "not ok 33\n"); }
  if ($i == 3) {print ((($key eq "54ABC") && ($value eq "ABC54333")) ? "ok 34\n" : "not ok 34\n"); }
  $i++;
}
print ($i == 4 ? "ok 35\n" : "not ok 35\n");
print (untie(%h) ? "ok 36\n" : "not ok 36\n");


# Test concurrancy
print (($h = tie (%h, VMS::IndexedFile, $Dfile)) ? "ok 37\n" : "not ok 37\n");
print (($i = tie (%i, VMS::IndexedFile, $Dfile)) ? "ok 38\n" : "not ok 38\n");
print (($h{'ABC'} eq "ABC54333") ? "ok 39\n" : "not ok 39\n");
@keys = keys(%i);
@values = values(%i);
print ($#keys   == 3 ? "ok 40\n" : "not ok 40\n");
print ($#values == 3 ? "ok 41\n" : "not ok 41\n");
print (($h{''} eq "DEF23456") ? "ok 42\n" : "not ok 42\n");
print (untie(%h) ? "ok 43\n" : "not ok 43\n");
print (untie(%i) ? "ok 44\n" : "not ok 44\n");
undef($h);
undef($i);

# Try some unusual entries
print (($h = tie (%h, VMS::IndexedFile, $Dfile)) ? "ok 45\n" : "not ok 45\n");

@h{200..250} = (200..250);
@foo = @h{200..250};
print (join(':',200..250) eq join(':',@foo) ? "ok 46\n" : "not ok 46\n");

# Try replacing the hash - this should call clear()
@mmmm = ('Jan','January','Feb','February','Mar','March','Apr','April');
%h = @mmmm;
@aa = %h;
print ((join(':',@aa) eq "Apr:April:Feb:February:Jan:January:Mar:March") ? "ok 47\n" : "not ok 47\n");

# Other odds and ends
print ((exists($h{'Mar'})) ? "ok 48\n" : "not ok 48\n");
print ((defined($h{'Mar'})) ? "ok 49\n" : "not ok 49\n");
($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blokcs) = stat($Dfile);
print (($size>0) ? "ok 50\n" : "not ok 50\n");

print (untie(%h) ? "ok 51\n" : "not ok 51\n");

#
# Test tie() O_ flags
#

# O_CREAT and O_TRUNC must have an FDL specification.
print ((!tie(%h,VMS::IndexedFile,"test.dat",0,O_RDWR | O_CREAT) && ($!=~/^insufficient call arguments/)) ? "ok 52\n" : "not ok 52 - $!\n");
print ((!tie(%h,VMS::IndexedFile,"test.dat",0,O_RDWR | O_TRUNC) && ($!=~/^insufficient call arguments/)) ? "ok 53\n" : "not ok 53 - $!\n");

# O_CREAT with O_EXCL should produce an error if the file already exists.
print ((!tie(%h,VMS::IndexedFile,"test.dat",0,O_RDWR | O_CREAT | O_EXCL, "<test.fdl") && ($!=~/^file exists/)) ? "ok 54\n" : "not ok 54 - $!\n");

# tie() should produce an error if the file doesn't already exist and neither O_TRUNC nor O_CREAT is specified.
# This test will fail, of course, if "qwertyuiop.dat" exists.
print ((!tie(%h,VMS::IndexedFile,"qwertyuiop.dat",0,O_RDONLY) && ($!=~/^file not found/)) ? "ok 55\n" : "not ok 55 - $!\n");
print ((!tie(%h,VMS::IndexedFile,"qwertyuiop.dat",0,O_WRONLY) && ($!=~/^file not found/)) ? "ok 56\n" : "not ok 56 - $!\n");
print ((!tie(%h,VMS::IndexedFile,"qwertyuiop.dat",0,O_RDWR)   && ($!=~/^file not found/)) ? "ok 57\n" : "not ok 57 - $!\n");

# files open for read only should not be writable.
if (!($h=tie(%h,VMS::IndexedFile,"test.dat",0,O_RDONLY))) { print "not ok 58 - $!\n"; }
else {
  print ((!($h->store('abc')) && ($!=~/^record operation not permitted/)) ? "ok 58\n" : "not ok 58 - $!\n");
}
untie(%h);

# files open for write only should not be readable.
if (!($h=tie(%h,VMS::IndexedFile,"test.dat",0,O_WRONLY))) { print "not ok 59 - $!\n"; }
else {
  print ((!($h{'abc'}) && ($!=~/^record operation not permitted/)) ? "ok 59\n" : "not ok 59 - $!\n");
}
untie(%h);

# O_TRUNC should create a new file.
if (!($h=tie(%h,VMS::IndexedFile,"test.dat",0,O_RDWR | O_TRUNC,"<test.fdl"))) { print "not ok 60 - $!\n"; }
else {
  print (($h{''} eq "") ? "ok 60\n" : "not ok 60 - $!\n");
}
untie(%h);

# Perl won't actually call the destroy function until ALL references to the packages go out of scope.  Without these, Perl
# can't delete the files because the program still has them open.
undef($h);
undef($i);

# Cleanup the files we created.
# There is a bug in 5.002.01 and prior versions of Perl that will cause the following tests to fail.
# For some reason, DESTROY() never gets called until the program exits.  Therefore, we can't unlink
# the file that it has open.  This bug has been reported as a problem.
print ((unlink $Dfile) ? "ok 61\n" : "not ok 61\n");
print ((unlink $Dfile) ? "ok 62\n" : ($!=~/^file currently locked by another user/) ? 
  "not ok 62 - this is a known bug in Perl 5.002.01 and before\n" : "not ok 62 - $!\n");
