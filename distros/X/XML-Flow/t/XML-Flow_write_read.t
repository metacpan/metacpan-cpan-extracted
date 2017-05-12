# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl XML-Flow.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 23;
use Data::Dumper;
use strict;
BEGIN { use_ok('XML::Flow',qw/ xml2ref ref2xml/) };
sub ref_xml {
    my $ref = shift;
    my $result;
    ok( my $flow = (new XML::Flow:: \$result ),"new flow for test");
    $flow->startTag("XML-FLow-Data");
    $flow->write($ref);
    $flow->endTag("XML-FLow-Data");
    return $result;
}
sub xml_ref {
    my $xml = shift;
    my $result;
    ok( my $flow = (new XML::Flow:: ref($xml)? $xml :\$xml ),"new flow for test");
    $flow->read({'XML-FLow-Data'=>sub { shift;($result)=@_}});
    return $result;
}

my $test1 = {1=>2};
ok( my $str = ref_xml($test1), "create str");
my $ref = xml_ref($str);
is_deeply({1=>2}, $ref, "test");
is_deeply({1=>2,2=>undef}, xml_ref(\*DATA), 'test *DATA');
my @tests = (
    {1=>undef,test=>[0,'',undef,2,\4]},
    \"1",
    [0,undef,1],
    [[],{},{}]);
my $i;
foreach my $rec (@tests) {
    $i++;
    ok( my $xml = ref2xml($rec), "$i : create xml");
    ok( my $ref = xml2ref($xml), "$i : create ref");
    ok( ref($ref) eq ref($rec), "$i : test ref type");
    is_deeply($rec, $ref, "$i : test restored");
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

__DATA__
<?xml version="1.0" encoding="UTF-8"?>
<XML-FLow-Data>
<flow_data_struct>
  <value type="hashref">
    <key name="1">2</key>
    <key name="2" value="undef"></key>
  </value>
</flow_data_struct>
</XML-FLow-Data>


