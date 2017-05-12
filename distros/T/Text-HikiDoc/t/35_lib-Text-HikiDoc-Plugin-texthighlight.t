# $Id: 35_lib-Text-HikiDoc-Plugin-texthighlight.t,v 1.4 2009/02/26 15:03:58 oneroad Exp $
use Test::Base;
use Text::HikiDoc;

eval 'require Text::Highlight;';
plan skip_all => 'Text::Highlight is not installed.' if $@;

plan tests => 1 * blocks;
filters { outline => 'chomp' };

my $obj = Text::HikiDoc->new();
my $block = next_block;
is $obj->to_html($block->input), $block->output, $block->outline;

$obj->enable_plugin('texthighlight');
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
<pre class="texthighlight">
<span class="key1">sub</span> dummy {
    $string = <span class="key2">shift</span>;

    $string =~ /$PLUGIN_RE/;
    <span class="key2">print</span> <span class="string">"s:$string\tm:$1\ta:$2\n"</span>;
    $a = $<span class="number">2</span>;
    $a =~ <span class="key3">s</span>/^\s*(.*)\s*$/$<span class="number">1</span>/;

    <span class="key1">if</span> ( $a =~ /($PLUGIN_RE)/ ) {
        &amp;hoge($a);
    }
    <span class="key1">return</span> $string;
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
<pre class="texthighlight">
<span class="key1">sub</span> dummy {
    $string = <span class="key2">shift</span>;

    $string =~ /$PLUGIN_RE/;
    <span class="key2">print</span> <span class="string">"s:$string\tm:$1\ta:$2\n"</span>;
    $a = $<span class="number">2</span>;
    $a =~ <span class="key3">s</span>/^\s*(.*)\s*$/$<span class="number">1</span>/;

    <span class="key1">if</span> ( $a =~ /($PLUGIN_RE)/ ) {
        &amp;hoge($a);
    }
    <span class="key1">return</span> $string;
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
