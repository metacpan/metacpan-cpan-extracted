# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..11\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tie::Concurrent;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use GDBM_File;
use Storable;
use MLDBM qw(GDBM_File Storable);

my $file="test.gdbm";

my $n=2;
my %data;
tie %data, 'Tie::Concurrent', {
            READER=>['MLDBM', $file, GDBM_READER, 0660], 
            WRITER=>['MLDBM', $file, GDBM_WRCREAT, 0660]
        };
# 2
print "not " unless tied %data;
print "ok ", $n++, "\n";

# 3
print "not " if -f $file;
print "ok ", $n++, "\n";

# 4
my $now=$data{$$}=time;
print "ok ", $n++, "\n";

# 5
print "not " if not -f $file;
print "ok ", $n++, "\n";

# 6
$data{hello}='world';
print "ok ", $n++, "\n";

# 7
print "not " unless exists $data{$$};
print "ok ", $n++, "\n";

# 8
sleep 1;
print "not " unless $data{$$}==$now;
print "ok ", $n++, "\n";

# 9
print "not " unless $now == delete $data{$$};
print "ok ", $n++, "\n";

# 10
%data=();
print "not " if exists $data{$$};
print "ok ", $n++, "\n";

# 11
%data=(1=>3, 10=>42, 32=>4);
print "not " unless 3==keys %data;
print "ok ", $n++, "\n";

untie %data;

unlink $file;

