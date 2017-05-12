# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl XML-Flow.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
use Data::Dumper;
BEGIN { use_ok('XML::Flow') }

my $rd   = new XML::Flow:: \*DATA;
my $test_ref ;
my %tags = (
    Root => undef,
    Obj  => sub {shift;$test_ref = [@_]; },
    Also => sub {
        shift;    #reference to hash of attributes
        return @_;
    },
);
$rd->read( \%tags );
$rd->close;
is_deeply($test_ref,[\'3',{1=>undef}],"test embed");

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
__DATA__
<?xml version="1.0" encoding="UTF-8"?>
 <Root>
  <Obj>
    <Also>
      <flow_data_struct>
        <value type="scalarref">
          <key name="scalar">3</key>
        </value>
      </flow_data_struct>
      <flow_data_struct>
        <value type="hashref">
          <key name="1" value="undef"></key>
        </value>
      </flow_data_struct>
    </Also>
  </Obj>
 </Root>

