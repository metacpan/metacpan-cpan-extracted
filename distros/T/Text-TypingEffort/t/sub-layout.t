# Does layout() perform correctly?

use Test::More tests => 3;
use Text::TypingEffort qw( effort layout );

my $qwerty = $Text::TypingEffort::layouts{qwerty};

is_deeply(
    layout('qwerty'),
    $qwerty,
    'qwerty explicitly specified'
);

is_deeply(
    layout,
    $qwerty,
    'qwerty implicitly specified'
);

ok(
    !defined layout('not a keyboard layout'),
    'non-existent layout'
);
