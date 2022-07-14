use 5.008001;
use strict;
use warnings;

use builtins::compat ();

BEGIN {
	builtins::compat::LEGACY_PERL
		or 'warnings'->unimport('experimental::builtin');
};

use Test::More;

plan tests => 15;

ok builtin::is_bool(builtin::true)    => 'is_bool(true)';
ok builtin::is_bool(builtin::false)   => 'is_bool(false)';
ok builtin::true()                    => 'true()';
ok !builtin::false()                  => '!false()';

my @list = (1..3);
is_deeply
	[builtin::indexed @list],
	[0=>1,1=>2,2=>3]   => 'indexed()';

my $strong = [];
my $weak   = $strong;
builtin::weaken($weak);

ok builtin::is_weak($weak)            => 'is_weak()';
builtin::unweaken($weak);
ok !builtin::is_weak($weak)           => '!is_weak()';

my $obj = bless {}, 'main';
ok builtin::blessed($obj),            => 'blessed()';
is builtin::refaddr($obj), 0+$obj     => 'refaddr()';
is builtin::reftype($obj), 'HASH'     => 'reftype()';

my $str = "\tspacy!";
my $PI =  3.1415926 ;
ok builtin::created_as_string($str)    =>   'created_as_string()';
ok builtin::created_as_number($PI)     =>   'created_as_number()';

is builtin::floor($PI), 3              =>   'floor()';
is builtin::ceil($PI),  4              =>   'ceil()';

is builtin::trim($str), 'spacy!'       => 'trim()';


done_testing();
