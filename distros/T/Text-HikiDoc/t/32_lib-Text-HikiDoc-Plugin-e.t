# $Id: 32_lib-Text-HikiDoc-Plugin-e.t,v 1.3 2006/10/13 04:11:08 6-o Exp $
use Test::Base;
use Text::HikiDoc;

plan tests => 1 * blocks;
filters { outline => 'chomp' };

my $obj = Text::HikiDoc->new;
$obj->enable_plugin('e');
run {
    my $block = shift;
    is $obj->to_html($block->input), $block->output, $block->outline;
}

__END__

===
--- input
hogehoge{{e(9829)}}fugafuga
--- output
<p>hogehoge&#9829;fugafuga</p>
--- outline
{{e(9829)}}

===
--- input
hogehoge{{e('9829')}}fugafuga
--- output
<p>hogehoge&#9829;fugafuga</p>
--- outline
{{e('9829')}}

===
--- input
hogehoge{{e '9829'}}fugafuga
--- output
<p>hogehoge&#9829;fugafuga</p>
--- outline
{{e '9829'}}

===
--- input
hogehoge{{e('hearts')}}fugafuga
--- output
<p>hogehoge&hearts;fugafuga</p>
--- outline
{{e('hearts')}}

===
--- input
hogehoge{{e 'hearts'}}fugafuga
--- output
<p>hogehoge&hearts;fugafuga</p>
--- outline
{{e 'hearts'}}

===
--- input
hogehoge{{e}}fugafuga
--- output
<p>hogehoge&;fugafuga</p>
--- outline
{{e}}

===
--- input
hogehoge{{e
9289
}}fugafuga
--- output
<p>hogehoge&#9289;fugafuga</p>
--- outline
{{e\n9289}}
