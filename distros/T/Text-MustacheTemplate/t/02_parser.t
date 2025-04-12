use strict;
use warnings;

use Test::More 0.98;
use Test::Base::Less;
use B ();

use Text::MustacheTemplate::Lexer;
use Text::MustacheTemplate::Parser qw/:syntaxes :variables :boxes :references/;

filters {
    input => [qw/eval/],
    expected => [qw/eval/],
};

subtest 'parse' => sub {
    for my $block (blocks) {
        my @tokens = @{ $block->input };
        my $ast = Text::MustacheTemplate::Parser->parse(@tokens);
        is_deeply $ast, $block->expected, $block->name
            or diag dump_ast($ast, 0);
    }
};

subtest 'error reporting' => sub {
    subtest 'with source' => sub {
        local $Text::MustacheTemplate::Parser::SOURCE = '{{#cond}}';
        eval {
            Text::MustacheTemplate::Parser->parse(
                [Text::MustacheTemplate::Lexer::TOKEN_DELIMITER,0,undef,"{{","}}"],
                [Text::MustacheTemplate::Lexer::TOKEN_TAG,0,"#","cond"],
            );
        };
        note $@;
        like $@, qr/line:1/, 'should found line info';
    };

    subtest 'without source' => sub {
        eval {
            Text::MustacheTemplate::Parser->parse(
                [Text::MustacheTemplate::Lexer::TOKEN_DELIMITER,0,undef,"{{","}}"],
                [Text::MustacheTemplate::Lexer::TOKEN_TAG,0,"#","cond"],
            );
        };
        note $@;
        unlike $@, qr/line:/, 'should not found line info';
    };
};

sub dump_ast {
    my ($ast, $indent) = @_;
    my $padding = ' ' x $indent;
    my $body = $padding."[\n";
    for my $syntax (@$ast) {
        my ($type) = @$syntax;
        my $name = [qw/SYNTAX_RAW_TEXT SYNTAX_VARIABLE SYNTAX_BOX SYNTAX_COMMENT SYNTAX_PARTIAL SYNTAX_DELIMITER/]->[$type];
        $body .= $padding."    [\n";
        $body .= $padding."        Text::MustacheTemplate::Parser::$name,\n";
        if ($type == SYNTAX_RAW_TEXT || $type == SYNTAX_COMMENT) {
            my (undef, $text) = @$syntax;
            $text = B::perlstring($text);
            $body .= $padding."        $text,\n";
        } elsif ($type == SYNTAX_VARIABLE) {
            my (undef, $variable, $name) = @$syntax;
            my $type = [qw/VARIABLE_HTML_ESCAPE VARIABLE_RAW/]->[$variable];
            $name = B::perlstring($name);
            $body .= $padding."        Text::MustacheTemplate::Parser::$type,\n";
            $body .= $padding."        $name,\n";
        } elsif ($type == SYNTAX_BOX) {
            my (undef, $box) = @$syntax;
            my $type = [qw/BOX_SECTION BOX_INVERTED_SECTION BOX_BLOCK BOX_PARENT/]->[$box];
            $body .= $padding."        Text::MustacheTemplate::Parser::$type,\n";
            if ($box == BOX_SECTION) {
                my (undef, undef, $name, $inner_template, $children) = @$syntax;
                $name = B::perlstring($name);
                $inner_template = B::perlstring($inner_template);
                $body .= $padding."        $name,\n";
                $body .= $padding."        $inner_template,\n";
                $body .= dump_ast($children, $indent+8);
            } elsif($box == BOX_INVERTED_SECTION || $box == BOX_BLOCK) {
                my (undef, undef, $name, $children) = @$syntax;
                $name = B::perlstring($name);
                $body .= $padding."        $name,\n";
                $body .= dump_ast($children, $indent+8);
            } elsif ($box == BOX_PARENT) {
                my (undef, undef, $reference, $name, $children) = @$syntax;
                my $type = [qw/REFERENCE_STATIC REFERENCE_DYNAMIC/]->[$reference];
                $name = B::perlstring($name);
                $body .= $padding."        Text::MustacheTemplate::Parser::$type,\n";
                $body .= $padding."        $name,\n";
                $body .= dump_ast($children, $indent+8);
            } else {
                die "Unknown box: $type";
            }
        } elsif ($type == SYNTAX_PARTIAL) {
            my (undef, $reference, $name, $pad) = @$syntax;
            my $type = [qw/REFERENCE_STATIC REFERENCE_DYNAMIC/]->[$reference];
            $name = B::perlstring($name);
            $pad = B::perlstring($pad) if defined $pad;
            $body .= $padding."        Text::MustacheTemplate::Parser::$type,\n";
            $body .= $padding."        $name,\n";
            $body .= $padding."        $pad,\n" if defined $pad;
            $body .= $padding."        undef,\n" unless defined $pad;
        } elsif ($type == SYNTAX_DELIMITER) {
            my (undef, @delimiters) = @$syntax;
            $body .= $padding."        $_,\n" for map B::perlstring($_), @delimiters;
        } else {
            die "Unknown syntax: $type";
        }
        $body .= $padding."    ],\n";
    }
    $body .= $indent == 0 ? "]\n" : $padding."],\n";
    return $body;
}

done_testing;
__DATA__

=== Variables
--- input
[
    [Text::MustacheTemplate::Lexer::TOKEN_DELIMITER,0,undef,"{{","}}"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,0,"* "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,2,"name"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,10,"\n* "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,13,"age"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,20,"\n* "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,23,"company"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,34,"\n* "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,37,"{","company"],
]
--- expected
[
    [
        Text::MustacheTemplate::Parser::SYNTAX_DELIMITER,
        "{{",
        "}}",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
        "* ",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_VARIABLE,
        Text::MustacheTemplate::Parser::VARIABLE_HTML_ESCAPE,
        "name",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
        "\n* ",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_VARIABLE,
        Text::MustacheTemplate::Parser::VARIABLE_HTML_ESCAPE,
        "age",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
        "\n* ",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_VARIABLE,
        Text::MustacheTemplate::Parser::VARIABLE_HTML_ESCAPE,
        "company",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
        "\n* ",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_VARIABLE,
        Text::MustacheTemplate::Parser::VARIABLE_RAW,
        "company",
    ],
]

=== Dotted Names
--- input
[
    [Text::MustacheTemplate::Lexer::TOKEN_DELIMITER,0,undef,"{{","}}"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,0,"* "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,2,"client.name"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,17,"\n* "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,20,"age"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,27,"\n* "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,30,"client.company.name"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,53,"\n* "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,56,"{","company.name"],
]
--- expected
[
    [
        Text::MustacheTemplate::Parser::SYNTAX_DELIMITER,
        "{{",
        "}}",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
        "* ",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_VARIABLE,
        Text::MustacheTemplate::Parser::VARIABLE_HTML_ESCAPE,
        "client.name",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
        "\n* ",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_VARIABLE,
        Text::MustacheTemplate::Parser::VARIABLE_HTML_ESCAPE,
        "age",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
        "\n* ",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_VARIABLE,
        Text::MustacheTemplate::Parser::VARIABLE_HTML_ESCAPE,
        "client.company.name",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
        "\n* ",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_VARIABLE,
        Text::MustacheTemplate::Parser::VARIABLE_RAW,
        "company.name",
    ],
]

=== Implicit Iterator
--- input
[
    [Text::MustacheTemplate::Lexer::TOKEN_DELIMITER,0,undef,"{{","}}"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,0,"."],
]
--- expected
[
    [
        Text::MustacheTemplate::Parser::SYNTAX_DELIMITER,
        "{{",
        "}}",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_VARIABLE,
        Text::MustacheTemplate::Parser::VARIABLE_HTML_ESCAPE,
        ".",
    ],
]

=== Sections
--- input
[
    [Text::MustacheTemplate::Lexer::TOKEN_DELIMITER,0,undef,"{{","}}"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,0,"Shown.\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,7,"#","person"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,18,"\n  Never shown!\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,34,"/","person"],
]
--- expected
[
    [
        Text::MustacheTemplate::Parser::SYNTAX_DELIMITER,
        "{{",
        "}}",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
        "Shown.\n",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_BOX,
        Text::MustacheTemplate::Parser::BOX_SECTION,
        "person",
        "\n  Never shown!\n",
        [
            [
                Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
                "  Never shown!\n",
            ],
        ],
    ],
]

=== Inverted Sections
--- input
[
    [Text::MustacheTemplate::Lexer::TOKEN_DELIMITER,0,undef,"{{","}}"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,0,"#","repo"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,9,"\n  <b>"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,15,"name"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,23,"</b>\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,28,"/","repo"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,37,"\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,38,"^","repo"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,47,"\n  No repos :(\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,62,"/","repo"],
]
--- expected
[
    [
        Text::MustacheTemplate::Parser::SYNTAX_DELIMITER,
        "{{",
        "}}",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_BOX,
        Text::MustacheTemplate::Parser::BOX_SECTION,
        "repo",
        "\n  <b>{{name}}</b>\n",
        [
            [
                Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
                "  <b>",
            ],
            [
                Text::MustacheTemplate::Parser::SYNTAX_VARIABLE,
                Text::MustacheTemplate::Parser::VARIABLE_HTML_ESCAPE,
                "name",
            ],
            [
                Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
                "</b>\n",
            ],
        ],
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_BOX,
        Text::MustacheTemplate::Parser::BOX_INVERTED_SECTION,
        "repo",
        [
            [
                Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
                "  No repos :(\n",
            ],
        ],
    ],
]

=== Comments
--- input
[
    [Text::MustacheTemplate::Lexer::TOKEN_DELIMITER,0,undef,"{{","}}"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,0,"<h1>Today"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,9,"!"," ignore me "],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,25,".</h1>"],
]
--- expected
[
    [
        Text::MustacheTemplate::Parser::SYNTAX_DELIMITER,
        "{{",
        "}}",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
        "<h1>Today",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_COMMENT,
        " ignore me ",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
        ".</h1>",
    ],
]

=== Partials
--- input
[
    [Text::MustacheTemplate::Lexer::TOKEN_DELIMITER,0,undef,"{{","}}"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,0,"<h2>Names</h2>\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,15,"#","names"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,25,"\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_PADDING,26,"  "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,28,">"," user"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,38,"\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,39,"/","names"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,49,"\n\nHello "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,57,">","*dynamic"],
]
--- expected
[
    [
        Text::MustacheTemplate::Parser::SYNTAX_DELIMITER,
        "{{",
        "}}",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
        "<h2>Names</h2>\n",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_BOX,
        Text::MustacheTemplate::Parser::BOX_SECTION,
        "names",
        "\n  {{> user}}\n",
        [
            [
                Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
                "  ",
            ],
            [
                Text::MustacheTemplate::Parser::SYNTAX_PARTIAL,
                Text::MustacheTemplate::Parser::REFERENCE_STATIC,
                "user",
                "  ",
            ],
        ],
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
        "\nHello ",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_PARTIAL,
        Text::MustacheTemplate::Parser::REFERENCE_DYNAMIC,
        "dynamic",
        undef,
    ],
]

=== Blocks
--- input
[
    [Text::MustacheTemplate::Lexer::TOKEN_DELIMITER,0,undef,"{{","}}"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,0,"<h1>"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,4,"\$","title"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,14,"The News of Today"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,31,"/","title"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,41,"</h1>\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,47,"\$","body"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,56,"\n<p>Nothing special happened.</p>\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,90,"/","body"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,99,"\n\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,101,"<","article"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,113,"\n  Never shown\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_PADDING,128,"  "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,130,"\$","body"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,139,"\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_PADDING,140,"    "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,144,"#","headlines"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,158,"\n    <p>"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,166,"."],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,171,"</p>\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_PADDING,176,"    "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,180,"/","headlines"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,194,"\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_PADDING,195,"  "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,197,"/","body"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,206,"\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,207,"/","article"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,219,"\n\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,221,"<","article"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,233,"\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_PADDING,234,"  "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,236,"\$","title"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,246,"Yesterday"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,255,"/","title"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,265,"\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,266,"/","article"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,278,"\n\nHello "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,286,">","*dynamic"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,299,"\n\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,301,"!","normal.mustache"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,321,"\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,322,"\$","text"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,331,"Here goes nothing."],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,349,"/","text"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,358,"\n\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,360,"!","bold.mustache"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,378,"\n<b>"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,382,"\$","text"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,391,"Here also goes nothing but it's bold."],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,428,"/","text"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,437,"</b>\n\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,443,"!","dynamic.mustache"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,464,"\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,465,"<","*dynamic"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,478,"\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_PADDING,479,"  "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,481,"\$","text"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,490,"Hello World!"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,502,"/","text"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,511,"\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,512,"/","*dynamic"],
]
--- expected
[
    [
        Text::MustacheTemplate::Parser::SYNTAX_DELIMITER,
        "{{",
        "}}",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
        "<h1>",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_BOX,
        Text::MustacheTemplate::Parser::BOX_BLOCK,
        "title",
        [
            [
                Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
                "The News of Today",
            ],
        ],
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
        "</h1>\n",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_BOX,
        Text::MustacheTemplate::Parser::BOX_BLOCK,
        "body",
        [
            [
                Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
                "<p>Nothing special happened.</p>\n",
            ],
        ],
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
        "\n",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_BOX,
        Text::MustacheTemplate::Parser::BOX_PARENT,
        Text::MustacheTemplate::Parser::REFERENCE_STATIC,
        "article",
        [
            [
                Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
                "  Never shown\n",
            ],
            [
                Text::MustacheTemplate::Parser::SYNTAX_BOX,
                Text::MustacheTemplate::Parser::BOX_BLOCK,
                "body",
                [
                    [
                        Text::MustacheTemplate::Parser::SYNTAX_BOX,
                        Text::MustacheTemplate::Parser::BOX_SECTION,
                        "headlines",
                        "\n    <p>{{.}}</p>\n    ",
                        [
                            [
                                Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
                                "    <p>",
                            ],
                            [
                                Text::MustacheTemplate::Parser::SYNTAX_VARIABLE,
                                Text::MustacheTemplate::Parser::VARIABLE_HTML_ESCAPE,
                                ".",
                            ],
                            [
                                Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
                                "</p>\n",
                            ],
                        ],
                    ],
                ],
            ],
        ],
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
        "\n",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_BOX,
        Text::MustacheTemplate::Parser::BOX_PARENT,
        Text::MustacheTemplate::Parser::REFERENCE_STATIC,
        "article",
        [
            [
                Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
                "  ",
            ],
            [
                Text::MustacheTemplate::Parser::SYNTAX_BOX,
                Text::MustacheTemplate::Parser::BOX_BLOCK,
                "title",
                [
                    [
                        Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
                        "Yesterday",
                    ],
                ],
            ],
            [
                Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
                "\n",
            ],
        ],
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
        "\nHello ",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_PARTIAL,
        Text::MustacheTemplate::Parser::REFERENCE_DYNAMIC,
        "dynamic",
        undef,
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
        "\n\n",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_COMMENT,
        "normal.mustache",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_BOX,
        Text::MustacheTemplate::Parser::BOX_BLOCK,
        "text",
        [
            [
                Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
                "Here goes nothing.",
            ],
        ],
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
        "\n\n",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_COMMENT,
        "bold.mustache",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
        "<b>",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_BOX,
        Text::MustacheTemplate::Parser::BOX_BLOCK,
        "text",
        [
            [
                Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
                "Here also goes nothing but it's bold.",
            ],
        ],
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
        "</b>\n\n",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_COMMENT,
        "dynamic.mustache",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_BOX,
        Text::MustacheTemplate::Parser::BOX_PARENT,
        Text::MustacheTemplate::Parser::REFERENCE_DYNAMIC,
        "dynamic",
        [
            [
                Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
                "  ",
            ],
            [
                Text::MustacheTemplate::Parser::SYNTAX_BOX,
                Text::MustacheTemplate::Parser::BOX_BLOCK,
                "text",
                [
                    [
                        Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
                        "Hello World!",
                    ],
                ],
            ],
            [
                Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
                "\n",
            ],
        ],
    ],
]

=== Set Delimiter
--- input
[
    [Text::MustacheTemplate::Lexer::TOKEN_DELIMITER,0,undef,"{{","}}"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,0,"* "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,2,"default_tags"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,18,"\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_DELIMITER,19,"<% %>","<%","%>"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,30,"\n* "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,33," erb_style_tags "],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,53,"\n"],
    [Text::MustacheTemplate::Lexer::TOKEN_DELIMITER,54,"{{ }}","{{","}}"],
    [Text::MustacheTemplate::Lexer::TOKEN_RAW_TEXT,65,"\n* "],
    [Text::MustacheTemplate::Lexer::TOKEN_TAG,68," default_tags_again "],
]
--- expected
[
    [
        Text::MustacheTemplate::Parser::SYNTAX_DELIMITER,
        "{{",
        "}}",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
        "* ",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_VARIABLE,
        Text::MustacheTemplate::Parser::VARIABLE_HTML_ESCAPE,
        "default_tags",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
        "\n",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_DELIMITER,
        "<%",
        "%>",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
        "* ",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_VARIABLE,
        Text::MustacheTemplate::Parser::VARIABLE_HTML_ESCAPE,
        "erb_style_tags",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
        "\n",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_DELIMITER,
        "{{",
        "}}",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_RAW_TEXT,
        "* ",
    ],
    [
        Text::MustacheTemplate::Parser::SYNTAX_VARIABLE,
        Text::MustacheTemplate::Parser::VARIABLE_HTML_ESCAPE,
        "default_tags_again",
    ],
]