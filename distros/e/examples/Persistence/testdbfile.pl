
#-----------------------------------------------------------------
# Testing DB_File
#
use DB_File;
use  Fcntl;
$file = 'test';
tie (%h, 'DB_File', $file, O_RDWR|O_CREAT, 0666, $DB_BTREE);
$DB_BTREE->{'compare'} = \&sort_ignorecase;
sub sort_ignorecase {
    my ($key1, $key2) = @_;
    $key1 =~ s/\s*//g;          # Get rid of white space
    $key2 =~ s/\s*//g;    
    lc($key1) cmp lc($key2);    # Ignore case when comparing
}

$h{abc} = "ABC";
$h{def} = "DEF";
$h{ghi} = "GHI";
untie (%h);

tie (%g, 'DB_File', $file, O_RDWR|O_CREAT, 0640, $DB_BTREE);

print "Retrieving individual elements...\n\t";
print $g{abc}," ", $g{def}, " ", $g{ghi}, "\n";

print "Retrieving keys...\n\t";
$, = " ";
print keys(%g);
untie(%g);
