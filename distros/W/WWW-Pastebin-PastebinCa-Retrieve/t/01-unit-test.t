#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::RequiresInternet ('pastebin.ca' => 80);
use Test::Deep;
use WWW::Pastebin::PastebinCa::Retrieve;

my $ID = '931145';
my $PASTE_DUMP  = {
    "language"  => "Perl Source",
    "desc"      => "perl stuff",
    "content"   => "{\r\n\ttrue => sub { 1 },\r\n\tfalse => sub { 0 },\r\n\ttime  => scalar localtime(),\r\n}",
    "post_date" => re('Thursday, March 6th, 2008 at \d{1,2}:\d{2}:\d{2}(pm)? [A-Z]{2,4}'),
    "name"      => "Zoffix"
};

my $paster = WWW::Pastebin::PastebinCa::Retrieve->new(timeout => 10);

my $ret1 = $paster->retrieve($ID);
my $ret2 = $paster->retrieve("http://pastebin.ca/$ID");
cmp_deeply($ret1, $ret2, 'calls with ID and URI must return the same');

is($paster->content, $ret1->{content}, 'content() method');
is("$paster", $ret1->{content}, 'content() overloads');
cmp_deeply($ret1, $PASTE_DUMP, q|dump from Dumper must match ->retrieve()'s response|);

for (qw(language content post_date name)) {
    ok(exists $ret1->{$_}, "$_ key must exist in the return");
}
cmp_deeply($ret1, $paster->results, '->results() must now return whatever ->retrieve() returned');

is($paster->id, $ID, 'paste ID must match the return from ->id()');
isa_ok($paster->uri, 'URI::http', '->uri() method');
is($paster->uri, "http://pastebin.ca/$ID", 'uri() must contain a URI to the paste');
isa_ok($paster->ua, 'LWP::UserAgent', '->ua() method');

done_testing();
