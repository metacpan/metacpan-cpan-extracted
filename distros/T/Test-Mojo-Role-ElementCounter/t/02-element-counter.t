#!perl

use Test::More;
use Test::Mojo;

use FindBin;
require "$FindBin::Bin/Test/MyApp.pm";

use Test::Mojo::WithRoles 'ElementCounter';
my $t = Test::Mojo::WithRoles->new;

{
  $t->get_ok('/')->status_is(200)
    ->element_count_is('#one', 1)
    ->element_count_is('div',  4)
    ->element_count_is('span', 2);

  $t->dive_in('#one ')
    ->element_count_is('div',  0)
    ->element_count_is('span', 1)
    ->dived_text_is('span', 'Mooo');

  $t->dive_reset
    ->element_count_is('#one', 1)
    ->element_count_is('div',  4)
    ->element_count_is('span', 2)
    ->element_count_is('div', '> 2')
    ->element_count_is('span', '< 4')
    ->element_count_is('span', '> 1');

  $t->dive_in('#two #three ')
    ->element_count_is('#one', 0)
    ->element_count_is('#three', 0)
    ->element_count_is('div',  1)
    ->element_count_is('span', 1)
    ->element_count_is('div', '< 2')
    ->element_count_is('span', '< 4')
    ->element_count_is('span', '> 0')
    ->dived_text_is('span', 'Hello!');

  $t->dive_up
    ->element_count_is('#one', 0)
    ->element_count_is('#three', 1)
    ->element_count_is('div',  2)
    ->element_count_is('span', 1)
    ->element_count_is('div', '< 3')
    ->element_count_is('span', '< 4')
    ->element_count_is('span', '> 0')
    ->dived_text_is('#four span', 'Hello!');

  $t->dive_in('#three ')
    ->dive_out('#three ')
    ->element_count_is('#one', 0)
    ->element_count_is('#three', 1)
    ->element_count_is('div',  2)
    ->element_count_is('span', 1)
    ->element_count_is('div', '< 3')
    ->element_count_is('span', '< 4')
    ->element_count_is('span', '> 0')
    ->dived_text_is('#four span', 'Hello!');

  $t->dive_in('#three ')
    ->dive_out(qr/.+/)
    ->element_count_is('#one', 1)
    ->element_count_is('div',  4)
    ->element_count_is('span', 2);

  $t->dive_reset->dive_in('#two ')
    ->element_count_is('div, span', 3);

  isnt eval { $t->element_count_is('div'); 42 }, 42,
    'we die when element count is undefined';
  like $@, qr/undefined element count/, 'message on death looks sane';
}

done_testing();