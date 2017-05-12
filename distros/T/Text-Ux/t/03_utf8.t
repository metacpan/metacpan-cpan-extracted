use strict;
use warnings;

use Test::More;
use Text::Ux;
use Encode;

my $ux = Text::Ux->new;
$ux->build([qw(foo bar baz)]);

subtest 'prefix_search', sub {
    my $key = $ux->prefix_search(decode_utf8('foo'));
    is $key, 'foo';
    ok utf8::is_utf8($key);
    $key = $ux->prefix_search('foo');
    is $key, 'foo';
    ok !utf8::is_utf8($key);
};

subtest 'common_prefix_search', sub {
    my @keys = $ux->common_prefix_search(decode_utf8('foo'));
    is scalar(@keys), 1;
    is $keys[0], 'foo';
    ok utf8::is_utf8($keys[0]);

    @keys = $ux->common_prefix_search('foo');
    is scalar(@keys), 1;
    is $keys[0], 'foo';
    ok !utf8::is_utf8($keys[0]);
};

subtest 'predictive_search', sub {
    my @keys = $ux->predictive_search(decode_utf8('foo'));
    is scalar(@keys), 1;
    is $keys[0], 'foo';
    ok utf8::is_utf8($keys[0]);

    @keys = $ux->common_prefix_search('foo');
    is scalar(@keys), 1;
    is $keys[0], 'foo';
    ok !utf8::is_utf8($keys[0]);
};

subtest 'gsub', sub {
    my $text = $ux->gsub(decode_utf8('foo'), sub { "<$_[0]>" });
    is $text, '<foo>';
    ok utf8::is_utf8($text);
    $text = $ux->gsub('foo', sub { "<$_[0]>" });
    is $text, '<foo>';
    ok !utf8::is_utf8($text);
};

done_testing;
