#!/usr/bin/perl -Iblib/lib/
#
#  Test we can merge duplicate records correctly.
#
# Steve
# --
#

use strict;
use warnings;


use Test::More qw! no_plan !;

BEGIN {use_ok("TinyDNS::Reader::Merged")}
require_ok("TinyDNS::Reader::Merged");



#
#  Parse the given text and return the records.
#
sub getObj
{
    my ($txt) = (@_);

    # create
    my $o = TinyDNS::Reader::Merged->new( text => $txt );
    isa_ok( $o, "TinyDNS::Reader::Merged" );

    # parse
    my $out = $o->parse();
    ok( $out, "Parsing resulted in a non-empty value" );
    is( ref($out), "ARRAY", "Which has the right type" );

    my @ret = @$out;
    return (@ret);
}



##
##  NOTE:  Unlinke using L<TinyDNS::Reader> we expect the value to be an array.
##


#
##
## Basic testing, as before
##
#


#
# Traditional MX..
#
my @all = getObj("\@edinburgh.io:mail.steve.org.uk:15");
is( scalar(@all),         1,                      "One record" );
is( $all[0]->{ 'type' },  "MX",                   "Got the right type" );
is( $all[0]->{ 'name' },  "edinburgh.io",         "Got the right name" );
is( $all[0]->{ 'value' }, "15 mail.steve.org.uk", "Got the right value" );

#
#  MX without the odd missing record
#
@all = getObj("\@edinburgh.io:mail.steve.org.uk:15");
is( scalar(@all),         1,                      "One record" );
is( $all[0]->{ 'type' },  "MX",                   "Got the right type" );
is( $all[0]->{ 'name' },  "edinburgh.io",         "Got the right name" );
is( $all[0]->{ 'value' }, "15 mail.steve.org.uk", "Got the right value" );


#
#  TXT
#
@all = getObj("Tedinburgh.io:\"v=spf1 mx a ptr ip4:1.2.3.4 ?all\":300\n");
is( scalar(@all), 1, "One record" );

is( $all[0]->{ 'type' }, "TXT",          "Got the right type" );
is( $all[0]->{ 'name' }, "edinburgh.io", "Got the right name" );
is( $all[0]->{ 'value' },
    "\"v=spf1 mx a ptr ip4:1.2.3.4 ?all\"",
    "Got the right value" );


#
##
## Test the merging records.
##
#


#
#  NOTE As per the previous comment we now get an array as the value
# because we've merged records.
#
@all = getObj("+foo.example.com:1.2.3.4:300\n+foo.example.com:1.2.3.5:300\n");
is( scalar(@all),        1,                 "One record" );
is( $all[0]->{ 'type' }, "A",               "Got the right type" );
is( $all[0]->{ 'name' }, "foo.example.com", "Got the right name" );

#
# Test we got an array
#
my $val = $all[0]->{ 'value' };
is( ref $val,      "ARRAY", "We got an array" );
is( scalar(@$val), 2,       "We found two values" );

#
# Test the array has the correct types.
#
$val = $all[0]->{ 'value' };
is( $val->[0], "1.2.3.4", "Got the right value" );
is( $val->[1], "1.2.3.5", "Got the right value" );


