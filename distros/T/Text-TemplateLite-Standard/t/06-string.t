#!perl -T

use Test::More tests => 27;

use Text::TemplateLite;
use Text::TemplateLite::Standard;

my $tpl = Text::TemplateLite->new;
my $rnd = $tpl->new_renderer;

Text::TemplateLite::Standard::register($tpl, qw/:misc :string/);

# $; join $;; join4 len $/ split $- substr trim

## $; / join

$tpl->set(q{<<$;('+','a')>>});
is($rnd->render->result, 'a', '$; 1');

$tpl->set(q{<<join('+','a')>>});
is($rnd->render->result, 'a', 'join 1');

$tpl->set(q{<<$;('+','a','b')>>});
is($rnd->render->result, 'a+b', '$; 2');

$tpl->set(q{<<join('+','a','b')>>});
is($rnd->render->result, 'a+b', 'join 2');

# Tests: 4

## $;; / join4

$tpl->set(q{<<$;;('2','1','+','.','a')>>});
is($rnd->render->result, 'a', '$;; 1');

$tpl->set(q{<<join4('2','1','+','.','a')>>});
is($rnd->render->result, 'a', 'join4 1');

$tpl->set(q{<<$;;('2','1','+','.','a','b')>>});
is($rnd->render->result, 'a2b', '$;; 2');

$tpl->set(q{<<join4('2','1','+','.','a','b')>>});
is($rnd->render->result, 'a2b', 'join4 2');

$tpl->set(q{<<$;;('2','1','+','.','a','b','c')>>});
is($rnd->render->result, 'a1b.c', '$;; 3');

$tpl->set(q{<<join4('2','1','+','.','a','b','c')>>});
is($rnd->render->result, 'a1b.c', 'join4 3');

$tpl->set(q{<<$;;('2','1','+','.','a','b','c','d')>>});
is($rnd->render->result, 'a1b+c.d', '$;; 4');

$tpl->set(q{<<join4('2','1','+','.','a','b','c','d')>>});
is($rnd->render->result, 'a1b+c.d', 'join4 4');

# Tests: 8

## len

$tpl->set(q{<<'a'len'b'len()'c'len($a)'d'len('')'e'len('xyz')'f'>>});
is($rnd->render->result, 'a0b0c0d0e3f', 'len');

# Tests: 1

## $/ / split

$tpl->set(q{<<$;('+',$/('-','a-b-c-d'))>>});
is($rnd->render->result, 'a+b+c+d', '$/ + $;');

$tpl->set(q{<<join('+',split('-','a-b-c-d'))>>});
is($rnd->render->result, 'a+b+c+d', 'split + join');

$tpl->set(q{<<$/('-','a-b-c-d',2)>>});
is($rnd->render->result, 'c', '$/[2]');

# Tests: 3

## $- / substr

$tpl->set(q{<<$=('a','abcd')1$-($a)2$-($a,1)3$-($a,2)4>>});
is($rnd->render->result, '1abcd2bcd3cd4', '$- from offset');

$tpl->set(q{<<$=('a','abcd')1$-($a,0,1)2$-($a,1,1)3$-($a,2,1)4>>});
is($rnd->render->result, '1a2b3c4', '$- len 1, from offset');

$tpl->set(q{<<$=('a','abcd')substr($a,-3,-1)>>});
is($rnd->render->result, 'bc', 'substr(-3,-1)');

# Tests: 3

$tpl->set(q{<<$;(',',trim(' 1 ',' two ',' ',' 4 '))>>});
is($rnd->render->result, '1,two,,4', 'trim()');

# Tests: 1

# cmp, eq, ge, gt, le, lt, ne

$tpl->set(q{<<cmp('a','b')'.'cmp('b','b')'.'cmp('b','a')>>});
is($rnd->render->result, '-1.0.1', 'cmp a,b b,b b,a');

$tpl->set(q{<<eq('a','b')'.'eq('b','b')'.'eq('b','a')>>});
is($rnd->render->result, '.1.', 'eq a,b b,b b,a');

$tpl->set(q{<<ge('a','b')'.'ge('b','b')'.'ge('b','a')>>});
is($rnd->render->result, '.1.1', 'ge a,b b,b b,a');

$tpl->set(q{<<gt('a','b')'.'gt('b','b')'.'gt('b','a')>>});
is($rnd->render->result, '..1', 'gt a,b b,b b,a');

$tpl->set(q{<<le('a','b')'.'le('b','b')'.'le('b','a')>>});
is($rnd->render->result, '1.1.', 'le a,b b,b b,a');

$tpl->set(q{<<lt('a','b')'.'lt('b','b')'.'lt('b','a')>>});
is($rnd->render->result, '1..', 'lt a,b b,b b,a');

$tpl->set(q{<<ne('a','b')'.'ne('b','b')'.'ne('b','a')>>});
is($rnd->render->result, '1..1', 'ne a,b b,b b,a');
