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
    ok $node->can('id'),      "can not call 'id' method";
    ok $node->can('surface'), "can not call 'surface' method";
    ok $node->can('feature'), "can not call 'feature' method";
    ok $node->can('length'),  "can not call 'length' method";
    ok $node->can('rlength'), "can not call 'rlength' method";
    ok $node->can('lcattr'),  "can not call 'lcattr' method";
    ok $node->can('stat'),    "can not call 'stat' method";
    ok $node->can('isbest'),  "can not call 'isbest' method";
    ok $node->can('alpha'),   "can not call 'alpha' method";
    ok $node->can('beta'),    "can not call 'beta' method";
    ok $node->can('prob'),    "can not call 'prob' method";
    ok $node->can('wcost'),   "can not call 'wcost' method";
    ok $node->can('cost'),    "can not call 'cost' method";
};

subtest 'use Shirasu::Tree' => sub {
    SKIP: {
        local $@;
        eval { require Text::CaboCha };
        if ($@ || $Text::CaboCha::VERSION < "0.04") {
            skip "If you want to use some functions of Text::CaboCha, you need to install Text::CaboCha >= 0.04", 10;
        }
        my $ts = Text::Shirasu->new(cabocha => 1)->parse("昨日の晩御飯は，鮭のふりかけと「味噌汁」だけでしたか！？");
        my $tree = $ts->trees->[0];
        ok $tree->can('cid'),      "can not call 'cid' method";
        ok $tree->can('head_pos'), "can not call 'head_pos' method";
        ok $tree->can('func_pos'), "can not call 'func_pos' method";
        ok $tree->can('score'),    "can not call 'score' method";
        ok $tree->can('surface'),  "can not call 'surface' method";
        ok $tree->can('feature'),  "can not call 'feature' method";
        ok $tree->can('ne'),       "can not call 'ne' method";
    };
};

done_testing;
