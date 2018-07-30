
use Test::More tests => 5;
BEGIN { use_ok('Text::Quoted') };

use Data::Dumper;

my $text = <<EOF;
foo
============
bar
============
baz
EOF

is_deeply(extract($text), [
        {text => 'foo', quoter => '', raw => 'foo'},
        {text => '============', quoter => '', raw => '============', separator => 1 },
        {text => 'bar', quoter => '', raw => 'bar'},
        {text => '============', quoter => '', raw => '============', separator => 1 },
        {text => 'baz', quoter => '', raw => 'baz'},
    ],
    "Sample text is organized properly"
) or diag Dumper(extract($text));

is_deeply(extract($text, { no_separators => 1 }), [
        {text => "foo\n============\nbar\n============\nbaz", quoter => '', raw => "foo\n============\nbar\n============\nbaz"},
    ],
    "Sample text is organized properly (no separators)"
) or diag Dumper(extract($text, { no_separators => 1 }));

$text = <<EOF;
foo
> bar
> ============
> baz
> ============
EOF

is_deeply(extract($text), [
        {text => 'foo', quoter => '', raw => 'foo'},
        [
            {text => 'bar', quoter => '>', raw => '> bar'},
            {text => '============', quoter => '>', raw => '> ============', separator => 1 },
            {text => 'baz', quoter => '>', raw => '> baz'},
            {text => '============', quoter => '>', raw => '> ============', separator => 1 },
        ],
    ],
    "Sample text is organized properly"
) or diag Dumper(extract($text));

is_deeply(extract($text, { no_separators => 1 }), [
        {text => 'foo', quoter => '', raw => 'foo'},
        [
            {text => "bar\n============\nbaz\n============", quoter => '>', raw => "> bar\n> ============\n> baz\n> ============"},
        ],
    ],
    "Sample text is organized properly (no separators)"
) or diag Dumper(extract($text, { no_separators => 1 }));

