use strict;
use Test::More;
use utf8;
use Encode 'encode_utf8';

use Text::Shirasu;

subtest 'use Shirasu' => sub {
    # parse
    my $ts = Text::Shirasu->new->parse("昨日の晩御飯は，鮭のふりかけと「味噌汁」だけでしたか！？");
    is $ts->join_surface, encode_utf8("昨日の晩御飯は，鮭のふりかけと「味噌汁」だけでしたか！？"), "Could the text parse";
    
    # filter
    my $filter = $ts->filter(type => [qw/名詞 助動詞 記号/], 記号 => [qw/括弧開 括弧閉/])->join_surface;
    is $filter, encode_utf8("昨日晩御飯鮭「味噌汁」でした"), "Filtering done correctly";
};

subtest 'use Shirasu::Node' => sub {
    my $ts = Text::Shirasu->new->parse("昨日の晩御飯は，鮭のふりかけと「味噌汁」だけでしたか！？");
    my $node = $ts->nodes->[0];
    ok $node->can('id'),      "can call 'id' method";
    ok $node->can('surface'), "can call 'surface' method";
    ok $node->can('feature'), "can call 'feature' method";
    ok $node->can('length'),  "can call 'length' method";
    ok $node->can('rlength'), "can call 'rlength' method";
    ok $node->can('lcattr'),  "can call 'lcattr' method";
    ok $node->can('stat'),    "can call 'stat' method";
    ok $node->can('isbest'),  "can call 'isbest' method";
    ok $node->can('alpha'),   "can call 'alpha' method";
    ok $node->can('beta'),    "can call 'beta' method";
    ok $node->can('prob'),    "can call 'prob' method";
    ok $node->can('wcost'),   "can call 'wcost' method";
    ok $node->can('cost'),    "can call 'cost' method";
};

done_testing;