use strict;
use warnings;

use Test::More;

use Text::APL;

my $template = Text::APL->new(cache => 1);

is render('<%= $foo %>', name => 'foo', vars => {foo => 'hello'}), 'hello';
is render('<%= $foo %>', name => 'foo', vars => {foo => 'hello there'}), 'hello there';
is render('<%= $foo %>', name => 'foo', vars => {foo => 'hello', bar => 'hello'}), 'hello';

sub render {
    my ($input, %params) = @_;
    return $template->render(input => \$input, %params);
}

done_testing;
