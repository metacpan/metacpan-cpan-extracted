use warnings;
use strict;
use Test::More;
use Test::MockModule;

plan tests => 8;

use Text::MiniTmpl qw( render );

my $called = 0;

my $module = new Test::MockModule('Text::MiniTmpl');
$module->mock('tmpl2code', sub { $called++; $module->original('tmpl2code')->(@_) });

is render('t/tmpl/hello.txt'), 'Hello!',    'static file';
is $called, 1,  'tmpl2code was called';
is render('t/tmpl/hello.txt'), 'Hello!',    'static file';
is $called, 1,  'tmpl2code was not called';

is render('t/tmpl/hello_users.txt', users=>['powerman','anonymous']),
    "Hello, powerman!\nHello, anonymous!\n\n",'simple array + include';
is $called, 3,  'tmpl2code was called';
is render('t/tmpl/hello_users.txt', users=>['powerman','anonymous']),
    "Hello, powerman!\nHello, anonymous!\n\n",'simple array + include';
is $called, 3,  'tmpl2code was called';

