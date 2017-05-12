# Does register_layout() perform correctly?

use Test::More tests => 4;
use Text::TypingEffort qw( effort layout register_layout );

my $layout = [ ('a', 'A')x47 ];
register_layout('testing', $layout);

is_deeply(
    $Text::TypingEffort::layouts{testing},
    $layout,
    'internal hash',
);

is_deeply(
    layout('testing'),
    $layout,
    'layout() validates it',
);

is_deeply(
    layout('TeSTING'),
    $layout,
    'case insensitive',
);

my $e = effort(
    text => 'text-without-the-forbidden-letter',
    layout => 'testing',
);
is_deeply(
    $e,
    {
        characters => 0,
        presses    => 0,
        distance   => 0,
        energy     => 0,
    },
    'effort() after register_layout()',
);
