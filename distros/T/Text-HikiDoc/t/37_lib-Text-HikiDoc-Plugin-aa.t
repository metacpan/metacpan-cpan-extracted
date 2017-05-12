# $Id: 37_lib-Text-HikiDoc-Plugin-aa.t,v 1.1 2006/11/15 10:06:15 6-o Exp $
use Test::Base;
use Text::HikiDoc;

plan tests => 1 * blocks;
filters { outline => 'chomp' };

my $obj = Text::HikiDoc->new;
$obj->enable_plugin('aa');
run {
    my $block = shift;
    is $obj->to_html($block->input), $block->output, $block->outline;
}

__END__

===
--- input
hogehoge{{aa('
             (__)
            (oo)
     /-------\/
    / |     ||
   *  ||----||
      ~~    ~~
')}}fugafuga
--- output
<p>hogehoge<pre class="ascii-art">
             (__)
            (oo)
     /-------\/
    / |     ||
   *  ||----||
      ~~    ~~
</pre>fugafuga</p>
--- outline
{{aa('')}}

===
--- input
hogehoge{{aa '
             (__)
            (oo)
     /-------\/
    / |     ||
   *  ||----||
      ~~    ~~
'}}fugafuga
--- output
<p>hogehoge<pre class="ascii-art">
             (__)
            (oo)
     /-------\/
    / |     ||
   *  ||----||
      ~~    ~~
</pre>fugafuga</p>
--- outline
{{aa ''}}
