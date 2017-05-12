# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl XML-Flow.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 13;
use Data::Dumper;
use strict;
BEGIN { use_ok('XML::Flow') };

sub is_deeply_xml {
    my $xml = shift;
    my $ref  = shift;
    my $text = shift;
    ok( my $flow = (new XML::Flow:: ref($xml)? $xml:\$xml ),"new flow for test: $text");
    my $test_ref;
    ok( $flow->read({root=>sub { shift; $test_ref =  shift }}), "run parser");
    is_deeply($test_ref,$ref,"$text")
}

my @tests_rec=(
[ {1=>2,2=>undef},"use ref to GLOB", \*DATA ],
[ {1=>3,2=>undef},"ref to hash",
<<'TEST1'
<?xml version="1.0" encoding="UTF-8"?>
<root>
<flow_data_struct>
  <value type="hashref">
    <key name="1">3</key>
    <key name="2" value="undef"></key>
  </value>
</flow_data_struct>
</root>
TEST1
],
[{1=>2,2=>undef,errer=>[1,2,undef,2,[1,2]]}, "array of arrays",
<<TEST2
<?xml version="1.0" encoding="UTF-8"?>
<root>
<flow_data_struct>
  <value type="hashref">
    <key name="1">2</key>
    <key name="2" value="undef"></key>
    <key name="errer">
      <value type="arrayref">
        <key name="4">
          <value type="arrayref">
            <key name="1">2</key>
            <key name="0">1</key>
          </value>
        </key>
        <key name="1">2</key>
        <key name="3">2</key>
        <key name="0">1</key>
        <key name="2" value="undef"></key>
      </value>
    </key>
  </value>
</flow_data_struct>
</root>
TEST2
],
[ [1,0,undef,'',{1=>2,2=>undef,errer=>[1,2,undef,2,[1,2]]}], " 0, undef, ''",
<<'TEST3'
<?xml version="1.0" encoding="UTF-8"?>
<root>
<flow_data_struct>
  <value type="arrayref">
    <key name="4">
      <value type="hashref">
        <key name="1">2</key>
        <key name="2" value="undef"></key>
        <key name="errer">
          <value type="arrayref">
            <key name="4">
              <value type="arrayref">
                <key name="1">2</key>
                <key name="0">1</key>
              </value>
            </key>
            <key name="1">2</key>
            <key name="3">2</key>
            <key name="0">1</key>
            <key name="2" value="undef"></key>
          </value>
        </key>
      </value>
    </key>
    <key name="1">0</key>
    <key name="3"></key>
    <key name="0">1</key>
    <key name="2" value="undef"></key>
  </value>
</flow_data_struct>
</root>
TEST3
]

);
foreach my $rec (@tests_rec) {
    is_deeply_xml($rec->[2], $rec->[0], $rec->[1] );
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

__DATA__
<?xml version="1.0" encoding="UTF-8"?>
<root>
<flow_data_struct>
  <value type="hashref">
    <key name="1">2</key>
    <key name="2" value="undef"></key>
  </value>
</flow_data_struct>
</root>


