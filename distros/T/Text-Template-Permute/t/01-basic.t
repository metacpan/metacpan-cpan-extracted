#!perl

use 5.010001;
use strict;
use warnings;

use Text::Template::Permute;
use Test::More 0.98;

subtest "comment" => sub {
    my $ttp = Text::Template::Permute->new;
    $ttp->template("{{comment: foo}}Hello, world!{{comment: bar}}");
    is_deeply([ $ttp->process ], [
        "Hello, world!",
    ]);

};

subtest "permute" => sub {
    my $ttp = Text::Template::Permute->new;
    $ttp->template("{{comment: foo}}Hello, {{permute: world|you}}. Good {{permute: morning|afternoon}}!");
    is_deeply([ $ttp->process ], [
        "Hello, world. Good morning!",
        "Hello, world. Good afternoon!",
        "Hello, you. Good morning!",
        "Hello, you. Good afternoon!",
    ]);

    # comment in arg
    $ttp->template("Hello, {{permute: world/* some comment */|you}}. Good {{permute: morning|/* another comment*/afternoon}}!");
    is_deeply([ $ttp->process ], [
        "Hello, world. Good morning!",
        "Hello, world. Good afternoon!",
        "Hello, you. Good morning!",
        "Hello, you. Good afternoon!",
    ]);
};

# TODO: test command: pick
# TODO: test command: pick once

done_testing;
