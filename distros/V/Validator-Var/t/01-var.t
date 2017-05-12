#!perl -T
use Validator::Var;
use Validator::Checker::MostWanted qw(Type Can Base Ref Min Max Between Regexp Length);
use Test::More; # tests=>9;
use strict;

package Foo;
sub new
{
    my $class = shift;
    return bless {}, $class;
}

package Bar;
use base 'Foo';

sub new
{
    my $class = shift;
    return bless {}, $class;
}

sub func
{
    return 1;
}

package main;

#$validator->format('');
#$validator->entry('id0')->default(119)->checker(Max, 124)->checker(Min, 32)->checker(Between, 32, 124);
#$validator->entry('FooType')->checker(Type, 'Foo');
#$validator->entry('BarType')->checker(Type, 'Bar');
#$validator->entry('FooBaseBar')->checker(Base, 'Foo');
#$validator->entry('Object')->checker(Ref, qw(Foo Bar));

local $| = 1;

my $vv;

$vv = Validator::Var->new;
ok $vv->is_empty, 'var validator is empty';
$vv->checker(Length, 10);
ok ! $vv->is_empty, 'var validator is not empty';

$vv = Validator::Var->new->checker(Between, 32, 124);
ok $vv->is_valid(119),  '119 is between 32 and 124';
ok $vv->is_valid(32),   '32 is a low bound of [32..124] range';
ok $vv->is_valid(124),  '124 is a high bound of [32..124] range';
ok !$vv->is_valid(125), '125 is out of bounds of [32..124] range';
ok !$vv->is_valid(31),  '31 is out of bounds of [32..124] range';

$vv = Validator::Var->new->checker(Regexp, '^\w\d+$');
my $v = 'w123';
ok( $vv->is_valid($v),  "'$v' match regexp '^\\w\\d+\$'" );
$v = '123w';
ok( !$vv->is_valid($v),  "'$v' does not match regexp '^\\w\\d+\$'" );

my $foo = Foo->new;
my $bar = Bar->new;
my $refToFoo = \$foo;
my $refToHash = {};

my @estimated_refs = qw(REF Foo Bar);
$vv = Validator::Var->new->checker(Ref, @estimated_refs);
ok $vv->is_valid($refToFoo),
   sprintf( q($refToFoo is reference to one of %s), join(',', @estimated_refs));
ok $vv->is_valid($bar),
   sprintf( q($bar is reference to one of %s), join(',', @estimated_refs));
ok !$vv->is_valid($refToHash),
   sprintf( q($refToHash is reference to HASH and is not one of %s), join(',', @estimated_refs));

print q(Let's add HASH ref to checker 'Ref', set entry's at_least_one to true and will see what will be...), "\n";
$vv->checker(Ref, 'HASH')->at_least_one(1);
ok $vv->is_valid($refToHash), q($refToHash passed modified checker);
ok $vv->is_valid($refToHash, 1), q($refToHash passed modified checker with trace info);
$vv->print_trace;

$vv = Validator::Var->new->checker(Can, 'func');
ok $vv->is_valid($bar), '$bar is blessed and has \'func\' method';

$vv = Validator::Var->new->checker(Can, 'func', 'new');
ok $vv->is_valid($bar), '$bar is blessed and has \'new \' and \'func\' methods';

$vv = Validator::Var->new->checker(Can, 'func')->checker(Can, 'new'); # is equivalent to above
ok $vv->is_valid($bar), '$bar is blessed and has \'new \' and \'func\' methods';

$vv = Validator::Var->new->checker(Can, 'func')->checker(Ref, 'ARRAY')->checker(Length, 100)->checker(Min, 0);
ok !$vv->is_valid(undef, 1), 'print_trace testing for undefined variable';
$vv->print_trace;

ok !$vv->is_valid(-1, 1), 'print_trace testing for full invalid variable';
#$vv->print_trace;

#ok !$validator->entry('CanFunc')->is_valid($ref), '$ref is reference and has not funcs \'new \' and \'func\' methods';

#ok($validator->entry('FooType')->is_valid($foo), '$foo is type of Foo');
#ok($validator->entry('FooType')->is_valid($foo), '$foo is type of Foo');
#ok($validator->entry('BarType')->is_valid($bar), '$bar is type of Bar');

#ok( $validator->entry('id0')->is_valid(567), '' )

#printf qq(res = %i\n), $validator->entry('id0')->is_valid(567);
#my $not_passed = $validator->entry('id0')->checkers_not_passed;
#foreach my $err (@{$not_passed}) {
#    warn sprintf qq(Warn: check with %s[%s] failed\n), $err->[0], $err->[1];
#}

#printf qq(res = %i\n), $validator->entry('id1')->is_valid('23w');
#printf qq(res = %i\n), $validator->entry('id1')->is_valid('w23');


done_testing();

0;
