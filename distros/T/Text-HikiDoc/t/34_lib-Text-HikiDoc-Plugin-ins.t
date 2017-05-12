# $Id: 34_lib-Text-HikiDoc-Plugin-ins.t,v 1.3 2006/10/13 04:14:33 6-o Exp $
use Test::Base;
use Text::HikiDoc;

plan tests => 1 * blocks;
filters { outline => 'chomp'};

my $obj = Text::HikiDoc->new;
$obj->enable_plugin('ins');
run {
    my $block = shift;
    is $obj->to_html($block->input), $block->output, $block->outline;
}

__END__

===
--- input
hogehoge. {{ins('insert part.')}} fugafuga.
--- output
<p>hogehoge. <ins>insert part.</ins> fugafuga.</p>
--- outline
{{ins('str')}}

===
--- input
hogehoge. {{ins 'insert part.'}} fugafuga.
--- output
<p>hogehoge. <ins>insert part.</ins> fugafuga.</p>
--- outline
{{ins 'str'}}

===
--- input
hogehoge. {{ins "insert part1.
insert part2."}} fugafuga.
--- output
<p>hogehoge. <ins>insert part1.
insert part2.</ins> fugafuga.</p>
--- outline
{{ins\n"str"}}

===
--- input eval
{ string => "hogehoge. {{ins 'insert part1.\ninsert part2.'}} fugafuga.", br_mode => 'true' }
--- output
<p>hogehoge. <ins>insert part1.<br />
insert part2.</ins> fugafuga.</p>
--- outline
{{ins\nstr}} with br_mode

===
--- input eval
{ string => "hogehoge. {{ins 'insert part1.\ninsert part2.'}} fugafuga.", br_mode => 'true', empty_element_suffix => '>' }
--- output
<p>hogehoge. <ins>insert part1.<br>
insert part2.</ins> fugafuga.</p>
--- outline
{{ins\nstr}} with br_mode and empty_element_suffix
