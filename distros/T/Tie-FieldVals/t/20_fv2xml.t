use Test::More tests => 2;

require 't/compare.pl';

#--------------------------------------------------------------------
# Insert your test code below
#--------------------------------------------------------------------

# clear files
if (-f 'test1.xml') {
    unlink('test1.xml');
}

# now test the script
my $command = "$^X -I lib scripts/fv2xml t/test1.data test1.xml";
$result = system($command);
ok($result == 0, 'fv2xml generated XML from test1.data');

# compare the files
$result = compare('test1.xml', 't/good_test1.xml');
ok($result, 'fv2xml: test1.xml matches good output exactly');

# clean up test1
if ($result) {
    unlink('test1.xml');
}

