use strict;
use warnings;
use utf8;

use Test::More;

use Text::APL;

is render(''), '';

is render('text'), 'text';

is render('<%= $foo %>', vars => {foo => 1}), '1';

is render(
    '<%= foo() %>',
    helpers => {
        foo => sub {'bar'}
    }
  ),
  'bar';

is render('<%= "hello" %>'), 'hello';

is render('%= "hello"'), 'hello';

is render(<<'EOF'), "123";
% my $foo = '123';
%= $foo;
EOF

is render('<% my $foo = "bar"; %><%= $foo %>'), 'bar';

is render(<<'EOF', vars => {name => 'vti'}), "Hello, vti!\n";
Hello, <%= $name %>!
EOF

is render(<<'EOF'), "12345";
% for (1 .. 5) {
    %= $_
% }
EOF

is render('<%= $foo %>', vars => {foo => '<xml>'}), '&lt;xml&gt;';

is render('<%== $foo %>', vars => {foo => '<xml>'}), '<xml>';

is render('%= $foo;', vars => {foo => '<xml>'}), '&lt;xml&gt;';

is render('%== $foo;', vars => {foo => '<xml>'}), '<xml>';

is render('%== var("foo");', vars => {foo => 'here'}), 'here';
is render('%== var("bar");', vars => {}), '';

eval { render('% foo'); };
ok $@;

sub render {
    my ($input, %params) = @_;
    my $template = Text::APL->new;
    return $template->render(input => \$input, %params);
}

done_testing;
