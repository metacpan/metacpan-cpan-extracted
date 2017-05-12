# $Id: 21_lib-Text-HikiDoc_options.t,v 1.3 2006/11/13 10:48:54 6-o Exp $
use Test::Base;
use Text::HikiDoc;

plan tests => 1 * blocks;
filters { outline => 'chomp'};

my $obj = Text::HikiDoc->new({level => 2});
run {
    my $block = shift;
    is $obj->to_html($block->input), $block->output, $block->outline;
}

__END__


===
# test change level
--- input
!hoge
--- output
<h2>hoge</h2>
--- outline
to_html with string

===
--- input eval
{string => '!hogehoge', level => 3}
--- output
<h3>hogehoge</h3>
--- outline
change string and level

===
--- input
!fuga
--- output
<h3>fuga</h3>
--- outline
change string and keep level
