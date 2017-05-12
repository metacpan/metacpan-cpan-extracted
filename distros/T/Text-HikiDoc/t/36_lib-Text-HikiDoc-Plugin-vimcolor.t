# $Id: 36_lib-Text-HikiDoc-Plugin-vimcolor.t,v 1.5 2009/02/26 15:04:25 oneroad Exp $
use Test::Base;
use Text::HikiDoc;

eval 'require Text::VimColor;';
plan skip_all => 'Text::VimColor is not installed.' if $@;

plan tests => 1 * blocks;
filters { outline => 'chomp' };

my $obj = Text::HikiDoc->new();
my $block = next_block;
is $obj->to_html($block->input), $block->output, $block->outline;

$obj->enable_plugin('vimcolor');
while ( my $block = next_block ) {
    is $obj->to_html($block->input), $block->output, $block->outline;
}

__END__


===
Unplugged
--- input
<<< Perl
sub dummy {
    $string = shift;

    $string =~ /$PLUGIN_RE/;
    print "s:$string\tm:$1\ta:$2\n";
    $a = $2;
    $a =~ s/^\s*(.*)\s*$/$1/;

    if ( $a =~ /($PLUGIN_RE)/ ) {
        &hoge($a);
    }
    return $string;
}
>>>
--- output
<pre>
sub dummy {
    $string = shift;

    $string =~ /$PLUGIN_RE/;
    print "s:$string\tm:$1\ta:$2\n";
    $a = $2;
    $a =~ s/^\s*(.*)\s*$/$1/;

    if ( $a =~ /($PLUGIN_RE)/ ) {
        &amp;hoge($a);
    }
    return $string;
}
</pre>
--- outline
<<< Perl (unplugged)

===
Plugged
--- input
<<< Perl
sub dummy {
    $string = shift;

    $string =~ /$PLUGIN_RE/;
    print "s:$string\tm:$1\ta:$2\n";
    $a = $2;
    $a =~ s/^\s*(.*)\s*$/$1/;

    if ( $a =~ /($PLUGIN_RE)/ ) {
        &hoge($a);
    }
    return $string;
}
>>>
--- output
<pre class="vimcolor">
<span class="synStatement">sub </span><span class="synIdentifier">dummy </span>{
    <span class="synIdentifier">$string</span> = <span class="synStatement">shift</span>;

    <span class="synIdentifier">$string</span> =~ <span class="synStatement">/</span><span class="synIdentifier">$PLUGIN_RE</span><span class="synStatement">/</span>;
    <span class="synStatement">print</span> <span class="synConstant">&quot;s:</span><span class="synIdentifier">$string</span><span class="synSpecial">\t</span><span class="synConstant">m:</span><span class="synIdentifier">$1</span><span class="synSpecial">\t</span><span class="synConstant">a:</span><span class="synIdentifier">$2</span><span class="synSpecial">\n</span><span class="synConstant">&quot;</span>;
    <span class="synIdentifier">$a</span> = <span class="synIdentifier">$2</span>;
    <span class="synIdentifier">$a</span> =~ <span class="synStatement">s/</span><span class="synConstant">^</span><span class="synSpecial">\s*(.*)\s*</span><span class="synConstant">$</span><span class="synStatement">/</span><span class="synIdentifier">$1</span><span class="synStatement">/</span>;

    <span class="synStatement">if</span> ( <span class="synIdentifier">$a</span> =~ <span class="synStatement">/</span><span class="synSpecial">(</span><span class="synIdentifier">$PLUGIN_RE</span><span class="synSpecial">)</span><span class="synStatement">/</span> ) {
        <span class="synIdentifier">&amp;hoge</span>(<span class="synIdentifier">$a</span>);
    }
    <span class="synStatement">return</span> <span class="synIdentifier">$string</span>;
}
</pre>
--- outline
<<< Perl

===
--- input
<<< perl
sub dummy {
    $string = shift;

    $string =~ /$PLUGIN_RE/;
    print "s:$string\tm:$1\ta:$2\n";
    $a = $2;
    $a =~ s/^\s*(.*)\s*$/$1/;

    if ( $a =~ /($PLUGIN_RE)/ ) {
        &hoge($a);
    }
    return $string;
}
>>>
--- output
<pre class="vimcolor">
<span class="synStatement">sub </span><span class="synIdentifier">dummy </span>{
    <span class="synIdentifier">$string</span> = <span class="synStatement">shift</span>;

    <span class="synIdentifier">$string</span> =~ <span class="synStatement">/</span><span class="synIdentifier">$PLUGIN_RE</span><span class="synStatement">/</span>;
    <span class="synStatement">print</span> <span class="synConstant">&quot;s:</span><span class="synIdentifier">$string</span><span class="synSpecial">\t</span><span class="synConstant">m:</span><span class="synIdentifier">$1</span><span class="synSpecial">\t</span><span class="synConstant">a:</span><span class="synIdentifier">$2</span><span class="synSpecial">\n</span><span class="synConstant">&quot;</span>;
    <span class="synIdentifier">$a</span> = <span class="synIdentifier">$2</span>;
    <span class="synIdentifier">$a</span> =~ <span class="synStatement">s/</span><span class="synConstant">^</span><span class="synSpecial">\s*(.*)\s*</span><span class="synConstant">$</span><span class="synStatement">/</span><span class="synIdentifier">$1</span><span class="synStatement">/</span>;

    <span class="synStatement">if</span> ( <span class="synIdentifier">$a</span> =~ <span class="synStatement">/</span><span class="synSpecial">(</span><span class="synIdentifier">$PLUGIN_RE</span><span class="synSpecial">)</span><span class="synStatement">/</span> ) {
        <span class="synIdentifier">&amp;hoge</span>(<span class="synIdentifier">$a</span>);
    }
    <span class="synStatement">return</span> <span class="synIdentifier">$string</span>;
}
</pre>
--- outline
<<< perl

===
--- input
<<<
sub dummy {
    $string = shift;

    $string =~ /$PLUGIN_RE/;
    print "s:$string\tm:$1\ta:$2\n";
    $a = $2;
    $a =~ s/^\s*(.*)\s*$/$1/;

    if ( $a =~ /($PLUGIN_RE)/ ) {
        &hoge($a);
    }
    return $string;
}
>>>
--- output
<pre>
sub dummy {
    $string = shift;

    $string =~ /$PLUGIN_RE/;
    print "s:$string\tm:$1\ta:$2\n";
    $a = $2;
    $a =~ s/^\s*(.*)\s*$/$1/;

    if ( $a =~ /($PLUGIN_RE)/ ) {
        &amp;hoge($a);
    }
    return $string;
}
</pre>
--- outline
<<<

===
--- input
<<< aa
             (__)
            (oo)
     /-------\/
    / |     ||
   *  ||----||
      ~~    ~~
>>>
--- output
<pre class="ascii-art">
             (__)
            (oo)
     /-------\/
    / |     ||
   *  ||----||
      ~~    ~~
</pre>
--- outline
<<< aa

===
--- input
<<< raw
<strong>hoge</strong>
>>>
--- output
<strong>hoge</strong>
--- outline
<<< raw
