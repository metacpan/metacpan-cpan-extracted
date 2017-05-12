use Test::More tests => 2;

require 't/compare.pl';

#--------------------------------------------------------------------
# Insert your test code below
#--------------------------------------------------------------------

# clear files
if (-f 'test_hash.fv') {
    unlink('test_hash.fv');
}

# now test the script
my $command = "$^X -I lib scripts/hash2fv t/test_ARCHIVE_DB.pl test_hash.fv";
$result = system($command);
ok($result == 0, 'hash2fv generated FieldVals data from t/test_ARCHIVE_DB.pl');

# compare the files
$result = compare('test_hash.fv', 't/good_test_hash.data');
ok($result, 'hash2fv: test_hash.fv matches good output exactly');

# clean up
if ($result) {
    unlink('test_hash.fv');
}

