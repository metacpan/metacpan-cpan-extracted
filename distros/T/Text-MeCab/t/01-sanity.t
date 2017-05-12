#!perl
use strict;
use Test::More;

BEGIN
{
    use_ok("Text::MeCab", ':all');
}

my $version = Text::MeCab::version();
diag $version;

is $version, Text::MeCab::MECAB_VERSION(), "version ok";

if ($version >= 0.90 && $version <= 0.996) {
    ok(eval { defined MECAB_NOR_NODE } && !$@, "MECAB_NOR_NODE ok");
    ok(eval { defined MECAB_UNK_NODE } && !$@, "MECAB_UNK_NODE ok");
    ok(eval { defined MECAB_BOS_NODE } && !$@, "MECAB_BOS_NODE ok");
    ok(eval { defined MECAB_EOS_NODE } && !$@, "MECAB_EOS_NODE ok");
}

if ($version >= 0.98 && $version <= 0.996) {
    ok(eval { defined MECAB_EON_NODE } && !$@, "MECAB_EON_NODE ok");
}

if ($version >= 0.94 && $version <= 0.996) {
    ok(eval { defined MECAB_SYS_DIC } && !$@, "MECAB_SYS_DIC ok");
    ok(eval { defined MECAB_USR_DIC } && !$@, "MECAB_USR_DIC ok");
    ok(eval { defined MECAB_UNK_DIC } && !$@, "MECAB_UNK_DIC ok");
}

if ($version >= 0.99 && $version <= 0.996) {
    ok(eval { defined MECAB_ONE_BEST      } && !$@, "MECAB_ONE_BEST ok");
    ok(eval { defined MECAB_NBEST         } && !$@, "MECAB_NBEST ok");
    ok(eval { defined MECAB_PARTIAL       } && !$@, "MECAB_PARTIAL ok");
    ok(eval { defined MECAB_MARGINAL_PROB } && !$@, "MECAB_MARGINAL_PROB ok");
    ok(eval { defined MECAB_ALTERNATIVE   } && !$@, "MECAB_ALTERNATIVE ok");
    ok(eval { defined MECAB_ALL_MORPHS    } && !$@, "MECAB_ALL_MORPHS ok");
    ok(eval { defined MECAB_ALLOCATE_SENTENCE } && !$@, "MECAB_ALLOCATE_SENTENCE ok");
}

can_ok("Text::MeCab", qw(new parse));

# Make sure that what Text::MeCab::Node can, Text::MeCab::Node::Cloned
# also can do.
my @methods = (
    qw(id surface feature length prev next stat cost),
    qw(rlength rcattr lcattr posid char_type isbest alpha beta prob wcost)
);
foreach my $method (@methods) {
    # test one by one to make it easier to read
    can_ok("Text::MeCab::Node", $method);
    can_ok("Text::MeCab::Node::Cloned", $method);
}

done_testing;
