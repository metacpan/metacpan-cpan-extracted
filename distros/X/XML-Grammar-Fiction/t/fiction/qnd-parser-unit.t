use strict;
use warnings;

use Test::More tests => 3;

use XML::Grammar::Fiction::FromProto::Parser::QnD;

{
    my $text = <<"EOF";
Hello <s id="top">

<s id="a-better-scene">
</s>

</s>
EOF

    my $parser = XML::Grammar::Fiction::FromProto::Parser::QnD->new();

    $parser->setup_text($text);

    my $ret = $parser->consume(qr{[^<]});

    # TEST
    is ($ret, "Hello ", "consume works for first line");
}

{
    my $text = <<"EOF";
Hello
voila the row kala:
<s id="top">

<s id="a-better-scene">
</s>

</s>
EOF

    my $parser = XML::Grammar::Fiction::FromProto::Parser::QnD->new();

    $parser->setup_text($text);

    my $ret = $parser->consume(qr{[^<]});

    # TEST
    is ($ret, "Hello\nvoila the row kala:\n",
        "consume works for several lines");
}

{
    my $text = <<"EOF";
<s id="top">

<s id="a-better-scene">
</s>

</s>
EOF

    my $parser = XML::Grammar::Fiction::FromProto::Parser::QnD->new();

    $parser->setup_text($text);

    my $ret = $parser->_parse_opening_tag();

    # TEST
    is_deeply ($ret,
        {
            name => "s",
            is_standalone => 0,
            line => 1,
            attrs => [ { key => "id", value => "top"}],
        },
        "Checking _parse_opening_tag() - #1",
    );
}

