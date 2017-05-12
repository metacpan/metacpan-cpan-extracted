use strict;
use warnings;

use Test::More;
use Text::Ux;
use File::Temp;
use File::Spec;

my $ux = new_ok 'Text::Ux';
$ux->build([qw(foo bar baz footprint 123)]);
ok $ux->alloc_size;
is $ux->size, 5;
ok $ux->alloc_stat(1);
ok $ux->stat;

my $res = $ux->prefix_search('foop');
is $res, 'foo';

$res = $ux->prefix_search(1234);
is $res, 123;

my @res = $ux->common_prefix_search('footprint');
is_deeply \@res, ['foo', 'footprint'];

@res = $ux->predictive_search('fo');
is_deeply \@res, ['foo', 'footprint'];

$res = $ux->gsub('foop bard bazzar', sub { "<$_[0]>" });
is $res, '<foo>p <bar>d <baz>zar';

my $i;
for ($i = 0; $i < $ux->size; $i++) {
    ok $ux->decode_key($i);
}
is $i, 5;
ok !$ux->decode_key($i);

my $dir = File::Temp->newdir;
my $file = File::Spec->catfile($dir, 'test.ux');
$ux->save($file);
ok -f $file;

my $ux2 = Text::Ux->new;
$ux2->load($file);
is $ux->size, 5;

$ux2->clear;
is $ux2->size, 0;

done_testing;
