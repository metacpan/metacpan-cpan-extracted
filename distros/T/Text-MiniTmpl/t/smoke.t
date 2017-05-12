use warnings;
use strict;
use Test::More;

plan tests => 6;

use Cwd;
use Text::MiniTmpl qw( render );

is render('t/tmpl/hello.txt'), 'Hello!',    'static file';
is render('t/tmpl/hello_user.txt', user=>'powerman'),
    "Hello, powerman!\n",                   'simple scalar';
is render('t/tmpl/hello_users.txt', users=>['powerman','anonymous']),
    "Hello, powerman!\nHello, anonymous!\n\n",'simple array + include';
is render('t/tmpl/hello_users_abs.txt', users=>['powerman','anonymous']),
    "Hello, powerman!\nHello, anonymous!\n\n",'simple array + include';
is render('./t/tmpl/hello_users.txt', users=>['powerman','anonymous']),
    "Hello, powerman!\nHello, anonymous!\n\n",'simple array + include';
is render(getcwd().'/t/tmpl/hello_users.txt', users=>['powerman','anonymous']),
    "Hello, powerman!\nHello, anonymous!\n\n",'simple array + include';

