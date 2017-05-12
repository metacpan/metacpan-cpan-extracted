#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Text::Hogan::Compiler;

{
    my $template = Text::Hogan::Compiler->new->compile("Hello, {{name}}!");

    for (qw(Fred Wilma Barney Betty)) {
        is
            $template->render({ name => $_ }),
            "Hello, $_!",
            "Text::Hogan::Template synopsis works - $_";
    }
}

{ my $template = Text::Hogan::Compiler->new->compile("{{>hello}}");

    is
        $template->render({ name => "Dino" }, { hello => "Hello, {{name}}!" }),
        "Hello, Dino!",
        "Text::Hogan::Template synopsis works - Dino (partial)";
}

{
    my $template = Text::Hogan::Compiler->new->compile("Hello, {{name}}!", {'numeric_string_as_string' => 1});

    for (qw(01234)) {
        is
            $template->render({ name => $_ }),
            "Hello, $_!",
            "Text::Hogan::Template synopsis works - $_ (numeric_string_as_string)";
    }
}


done_testing();
