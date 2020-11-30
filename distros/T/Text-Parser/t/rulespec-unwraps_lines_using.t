
use strict;
use warnings;

package MyParser;

use Text::Parser::RuleSpec;
extends 'Text::Parser';

unwraps_lines_using(
    is_wrapped => sub {
        my ( $self, $line ) = @_;
        $line =~ /^[~]/;
    },
    unwrap_routine => sub {
        my ( $self, $last, $line ) = @_;
        chomp $last;
        $last =~ s/\s*$//g;
        $line =~ s/^[~]\s*//g;
        "$last $line";
    },
);

package main;

use Test::More;    # last test to print
use Test::Exception;

lives_ok {
    my $parser = MyParser->new();
    isa_ok $parser, 'MyParser';
    isa_ok $parser, 'Text::Parser';
    is $parser->line_wrap_style, 'custom',
        'Custom line-wrapping style is default';
    is $parser->multiline_type, undef, 'multiline_type stays untouched';
    $parser->read('t/example-custom-line-wrap.txt');
    is_deeply [ $parser->get_records ],
        [
        "This is a long line that is wrapped around with a custom\n",
        "~ character - the tilde. It is unusual, but hey, we\'re\n",
        "~ showing an example.\n",
        ],
        'Line-unwrapping is not enabled unless multiline_type is set by the user';
}
'Everything works even if you dont set multiline_type';

lives_ok {
    my $parser = MyParser->new( multiline_type => 'join_last' );
    isa_ok $parser, 'MyParser';
    isa_ok $parser, 'Text::Parser';
    is $parser->line_wrap_style, 'custom',
        'Custom line-wrapping style is default';
    is $parser->multiline_type, 'join_last',
        'multiline_type initialized at construction';
    $parser->read('t/example-custom-line-wrap.txt');
    is_deeply [ $parser->get_records ],
        [
        "This is a long line that is wrapped around with a custom character - the tilde. It is unusual, but hey, we're showing an example.\n"
        ],
        'Custom unwrapping enabled because multiline_type is set by the user';
}
'Everything works when you set multiline_type';

BEGIN {
    use_ok('Text::Parser::RuleSpec');
}

throws_ok {
    unwraps_lines_using
        is_wrapped     => sub { 0; },
        unwrap_routine => sub { ''; };
}
'Text::Parser::Error', 'Main cannot call this function';

done_testing;
