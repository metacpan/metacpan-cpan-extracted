use Test::Base;
use Text::HikiDoc;

plan tests => 1 * blocks;
filters { outline => 'chomp' };

my $obj = Text::HikiDoc->new();
my $block = next_block;
is $obj->to_html($block->input), $block->output, $block->outline;

$obj->enable_plugin('syntaxhighlighter');
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
<pre class="brush: perl">
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
<pre class="brush: perl">
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
