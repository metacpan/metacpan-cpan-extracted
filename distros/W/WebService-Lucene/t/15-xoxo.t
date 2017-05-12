use Test::More tests => 10;

use strict;
use warnings;

use_ok( 'WebService::Lucene::XOXOParser' );

my $parser = WebService::Lucene::XOXOParser->new;

isa_ok( $parser, 'WebService::Lucene::XOXOParser' );

{
    my $data = <<'';
<dl class="xoxo"><dt class="1">a</dt><dd>b</dd><dt class="2">c</dt><dd>d</dd></dl>

    my $expected = [
        {   name  => 'a',
            value => 'b',
            class => '1',
        },
        {   name  => 'c',
            value => 'd',
            class => '2',
        },
    ];

    my $result = [ $parser->parse( $data ) ];
    is_deeply( $result, $expected, "parse" );
}

{
    my $expected = <<'';
<dl class="xoxo"><dt class="1">a</dt><dd>b</dd><dt class="2">c</dt><dd>d</dd></dl>

    my $data = [
        {   name  => 'a',
            value => 'b',
            class => '1',
        },
        {   name  => 'c',
            value => 'd',
            class => '2',
        },
    ];

    my $result = $parser->construct( @$data );

    chomp( $expected );
    chomp( $result );

    is( $result, $expected, "contruct" );
}

{
    my %table = (
        '&' => '&amp;',
        '<' => '&lt;',
        '>' => '&gt;',
        '"' => '&quot;',
        "'" => '&apos;',
    );

    for my $value ( keys %table ) {
        is( $parser->encode_entities( $value ),
            $table{ $value },
            "encode: $value"
        );
    }
}

{
    my $expected = <<'';
<dl class="xoxo"><dt class="x">&amp;&lt;&gt;&quot;&apos;</dt><dd>&amp;&lt;&gt;&quot;&apos;</dd></dl>

    my $data = [
        {   name  => q(&<>"'),
            value => q(&<>"'),
            class => 'x',
        },
    ];

    my $result = $parser->construct( @$data );

    chomp( $expected );
    chomp( $result );

    is( $result, $expected, "construct & encode" );
}

