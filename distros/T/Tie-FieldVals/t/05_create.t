use strict;
use Test::More tests => 9;

use Tie::FieldVals;
use Tie::FieldVals::Row;
use Fcntl;

my @fields = qw(Author AuthorEmail AuthorURL Comment);
my $datafile = 'test_create.data';
if (-f $datafile) # remove an old existing file
{
    unlink($datafile);
}
# create the data file
my @all_recs = ();
my $df = tie @all_recs, 'Tie::FieldVals',
   datafile=>$datafile,
   fields=>\@fields,
   mode=>(O_RDWR|O_CREAT);

ok($df, "Tie::FieldVals object made");
ok(-e $datafile, "$datafile exists");

my $count = @all_recs;
my $expected_count = 0;
is($count, $expected_count, "Has $expected_count records");

# look at the file, check that the fields match
ok(open(FILE, $datafile), "opened $datafile");
my $still_ok = 1;
my $result = 0;
my $ln = 0;
while(<FILE>)
{
    if ($ln < @fields)
    {
	my $field = $fields[$ln];
	$result = (/^${field}:/);
	ok($result, "line $ln matches $field");
	$still_ok = (!$result ? $result : $still_ok);
    }
    else
    {
	$result = /^=/;
	ok($result, "line $ln matches record separator");
	$still_ok = (!$result ? $result : $still_ok);
    }
    $ln++;
}

# remove the file if everything is still ok
if ($still_ok)
{
    unlink($datafile);
}
# vim: ts=8 sts=4 sw=4
