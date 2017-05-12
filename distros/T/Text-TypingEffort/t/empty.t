# Is the 'text' option handled correctly?

use Test::More tests => 2;
use Text::TypingEffort qw( effort );

my $text = '';

# text parameter as a scalar
$effort = effort( text => $text );
is_deeply(
    $effort,
    {
        characters => 0,
        presses    => 0,
        distance   => 0,
        energy     => 0,
    },
    'empty string'
);

# text parameter as a scalarref
my $effort = effort( text => \$text );
is_deeply(
    $effort,
    {
        characters => 0,
        presses    => 0,
        distance   => 0,
        energy     => 0,
    },
    'reference to empty string'
);
