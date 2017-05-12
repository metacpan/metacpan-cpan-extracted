#!/usr/bin/perl

use XML::TMX::Reader;
use Test::More;

is_deeply(XML::TMX::Reader::_merge_notes(undef, "foo"), ["foo"]);
is_deeply(XML::TMX::Reader::_merge_notes(undef, ["foo"]), ["foo"]);
is_deeply(XML::TMX::Reader::_merge_notes([], ["foo"]), ["foo"]);
is_deeply(XML::TMX::Reader::_merge_notes("foo","foo"), ["foo"]);

is_deeply([ sort @{ XML::TMX::Reader::_merge_notes("foo", ["foo", "bar"]) }],
          [ sort (qw'foo bar') ]);

is_deeply([ sort @{ XML::TMX::Reader::_merge_notes([qw'a b c e'], [qw'c d e f']) }],
          [ sort (qw'a b c d e f') ]);

is_deeply(XML::TMX::Reader::_merge_props(undef, {foo => 'bar'}), {foo=>['bar']});

is_deeply(XML::TMX::Reader::_merge_props({foo => 'bar'}, {foo => 'bar'}),
          {foo=>['bar']});

my $m = XML::TMX::Reader::_merge_props({foo => 'ugh'}, {foo => 'bar'});
ok exists $m->{foo};
is_deeply [ sort @{$m->{foo}} ], [sort(qw'bar ugh')];

is_deeply(XML::TMX::Reader::_merge_props({foz => 'bar'}, {foo => 'bar'}),
          {foz=>'bar', foo=>['bar']});

$m = XML::TMX::Reader::_merge_props({foz => 'bar'}, {foz => 'baz', foo => 'bar'});
ok exists $m->{foo};
ok exists $m->{foz};
is_deeply [ sort @{$m->{foz}} ], [sort(qw'bar baz')];
is_deeply $m->{foo}, ['bar'];


done_testing();
