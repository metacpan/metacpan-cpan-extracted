use Test::Base qw(no_plan);
use Text::Livedoor::Wiki;
use Data::Dumper;

my $text = Text::Livedoor::Wiki->new( {  opts => { storage => 'http://static.wiki.livedoor.jp/formatter-storage' } });

run {
    my $block = shift;
    my $res = $text->parse( $block->wiki , { want_pos => 1 } );
    is_deep( $res , $block->position , 'pos' );
}

__DATA__

=== with copy and paste
--- wiki
line
* hoge
=||
hoge
* hoge
hoge
||=
* hoge
hoge
--- position eval
{
    'content_1' => 2,
    'content_2' => 8,
};
=== with toggle
--- wiki
line
* hoge
[+]hoge
* hoge
hoge
[END]
* hoge
hoge
--- position eval
{
    'content_1' => 2,
    'content_2' => 7,
};
=== basic
--- wiki
line1
* line2 
line3
line4
line5
line6
* line7 
line8
*line9
*line10
--- position eval
{
    'content_1' => 2,
    'content_2' => 7,
    'content_3' => 9,
    'content_4' => 10,
}
