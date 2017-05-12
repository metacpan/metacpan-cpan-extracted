# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl XML-Flow.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
use Data::Dumper;
use strict;
BEGIN { use_ok('XML::Flow') };

ok( (my $flow = new XML::Flow:: \*DATA),"new flow for test");
my @items;
my %handlers = (
    item=>sub { shift ; push @items, {@_} },
    title=>sub { shift; my ($str) = @_ ; title=>$str},
    desc=>sub { shift; my ($str) = @_ ; desc=>$str},
    );
$flow->read(\%handlers);
$flow->close;
is_deeply(\@items, [
          {
            'desc' => '2',
            'title' => '1'
          },
          {
            'desc' => '3',
            'title' => '2'
          }
        ],"test xml items");
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

__DATA__
<?xml version="1.0" encoding="UTF-8"?>
<root>
<item>
<title>1</title>
<desc>2</desc>
</item>
<item>
<title>2</title>
<desc>3</desc>
</item>
</root>
