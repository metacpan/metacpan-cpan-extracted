use strict;
use warnings;

use Test::More;
use Variable::Declaration;

use Type::Nano qw(Int);

subtest 'simple case' => sub {
    let $foo = 123;

    let $info = Variable::Declaration::info \$foo;
    isa_ok $info, 'Variable::Declaration::Info';
    is $info->declaration, 'let';
    is $info->attributes, undef;
    is $info->type, undef;
};

subtest 'declare type' => sub {
    let Int $foo = 123;

    let $info = Variable::Declaration::info \$foo;
    isa_ok $info, 'Variable::Declaration::Info';
    is $info->declaration, 'let';
    is $info->attributes, undef;
    is $info->type, Int;
};

subtest 'declare attributes' => sub {
    let $foo:lvalue = 123;

    let $info = Variable::Declaration::info \$foo;
    isa_ok $info, 'Variable::Declaration::Info';
    is $info->declaration, 'let';
    is $info->attributes, ':lvalue';
    is $info->type, undef;
};

subtest 'declare type and attributes' => sub {
    let Int $foo:lvalue = 123;

    let $info = Variable::Declaration::info \$foo;
    isa_ok $info, 'Variable::Declaration::Info';
    is $info->declaration, 'let';
    is $info->attributes, ':lvalue';
    is $info->type, Int;
};

subtest 'declare by const' => sub {
    const $foo = 123;

    let $info = Variable::Declaration::info \$foo;
    isa_ok $info, 'Variable::Declaration::Info';
    is $info->declaration, 'const';
    is $info->attributes, undef;
    is $info->type, undef;
};

done_testing;
