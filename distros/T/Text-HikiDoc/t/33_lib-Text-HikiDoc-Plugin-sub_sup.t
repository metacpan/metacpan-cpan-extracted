# $Id: 33_lib-Text-HikiDoc-Plugin-sub_sup.t,v 1.3 2006/10/13 04:11:52 6-o Exp $
use Test::Base;
use Text::HikiDoc;

plan tests => 1 * blocks;
filters { outline => 'chomp'};

my $obj = Text::HikiDoc->new;
$obj->enable_plugin('sub', 'sup');
run {
    my $block = shift;
    is $obj->to_html($block->input), $block->output, $block->outline;
}

__END__

===
--- input
Water is H{{sub(2)}}O.
--- output
<p>Water is H<sub>2</sub>O.</p>
--- outline
{{sub(2)}}

===
--- input
Water is H{{sub('2')}}O.
--- output
<p>Water is H<sub>2</sub>O.</p>
--- outline
{{sub('2')}}

===
--- input
Water is H{{sub '2'}}O.
--- output
<p>Water is H<sub>2</sub>O.</p>
--- outline
{{sub '2'}}

===
--- input
2{{sup(3)}} = 8
--- output
<p>2<sup>3</sup> = 8</p>
--- outline
{{sup(3)}}

===
--- input
2{{sup('3')}} = 8
--- output
<p>2<sup>3</sup> = 8</p>
--- outline
{{sup('3')}}

===
--- input
2{{sup '3'}} = 8
--- output
<p>2<sup>3</sup> = 8</p>
--- outline
{{sup '3'}}

===
--- input
Water is H{{sub
2
}}O.
--- output
<p>Water is H<sub>2</sub>O.</p>
--- outline
{{sub\n2}}
