use Test::More tests => 2;

require 't/compare.pl';

#--------------------------------------------------------------------
# Insert your test code below
#--------------------------------------------------------------------

# clear files
if (-f 'test1.fv') {
    unlink('test1.fv');
}

# now test the script
my $command = "$^X -I lib scripts/xml2fv t/good_test1.xml test1.fv";
$result = system($command);
ok($result == 0, 'xml2fv generated FieldVals data from t/good_test1.xml');

# compare the files
$result = compare('test1.fv', 't/test1.data');
ok($result, 'xml2fv: test1.fv matches good output exactly');

# clean up test1
if ($result) {
    unlink('test1.fv');
}

