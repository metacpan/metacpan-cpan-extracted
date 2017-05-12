use strict;
use warnings;

use Test::More;

use Text::APL;
use Test::Memory::Usage;

my $template = Text::APL->new(cache => 1);

memory_usage_start;

for (1 .. 1000) {
    $template->render(
        input => \'<%= 1 + 1 %>',
        name  => 'foo',
        vars  => {foo => 'hello'}
    );
}

memory_usage_ok;

done_testing;
