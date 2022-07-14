# https://fastapi.metacpan.org/source/DCONWAY/builtins-0.000003/t/testall.t
use 5.008001;
use strict;
use warnings;

use builtins::compat;

use Test::More;

plan tests => 15;

ok is_bool(true)             => 'is_bool(true)';
ok is_bool(false)            => 'is_bool(false)';
ok true()                    => 'true()';
ok !false()                  => '!false()';

my @list = (1..3);
is_deeply
	[indexed @list],
	[0=>1,1=>2,2=>3]   => 'indexed()';

my $strong = [];
my $weak   = $strong;
weaken($weak);

ok is_weak($weak)            => 'is_weak()';
unweaken($weak);
ok !is_weak($weak)           => '!is_weak()';

my $obj = bless {}, 'main';
ok blessed($obj),            => 'blessed()';
is refaddr($obj), 0+$obj     => 'refaddr()';
is reftype($obj), 'HASH'     => 'reftype()';

my $str = "\tspacy!";
my $PI =  3.1415926 ;
ok created_as_string($str)    =>   'created_as_string()';
ok created_as_number($PI)     =>   'created_as_number()';

is floor($PI), 3              =>   'floor()';
is ceil($PI),  4              =>   'ceil()';

is trim($str), 'spacy!'       => 'trim()';


done_testing();
