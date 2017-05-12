# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl XML-Flow.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
use Data::Dumper;
use strict;
BEGIN { use_ok('XML::Flow') };

ok( (my $flow = new XML::Flow:: \*DATA),"new flow for test");
my $items;
my %handlers = (
    root=>sub { shift ;  $items = join "",@_},
    para=>sub { shift; return join "",@_},
    link=>sub { shift ; return join "",@_}
    );
$flow->read(\%handlers);
$flow->close;
is( $items, 'text1linktest continue2 linktest continue3', "test text and emeded tags")
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

__DATA__
<?xml version="1.0" encoding="UTF-8"?>
<root>
<para>text1<link>linktest</link> continue2 <link>linktest</link> continue3</para>
</root>
