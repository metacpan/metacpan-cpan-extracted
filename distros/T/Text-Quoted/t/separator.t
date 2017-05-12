
use Test::More tests => 3;
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

