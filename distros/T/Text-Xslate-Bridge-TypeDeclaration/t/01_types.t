use strict;
use warnings;
use lib '.';

use t::helper;
use Test::More;

use Text::Xslate::Bridge::TypeDeclaration;

*_type = \&Text::Xslate::Bridge::TypeDeclaration::_type;

sub validate {
    my ($structure, $data) = @_;
    return _type($structure)->check($data);
}

subtest 'returns Mouse::Meta::TypeConstraint' => sub {
    ok _type('Str')->isa('Mouse::Meta::TypeConstraint');
    ok _type('Maybe[Str]')->isa('Mouse::Meta::TypeConstraint');
    ok _type([ 'Int', 'Str' ])->isa('Mouse::Meta::TypeConstraint');
    ok _type({ key => 'Str' })->isa('Mouse::Meta::TypeConstraint');
    ok _type(undef)->isa('Mouse::Meta::TypeConstraint');
    ok _type(\'Hoge')->isa('Mouse::Meta::TypeConstraint');
};

subtest 'union' => sub {
    ok  validate('Int|HashRef', 123);
    ok  validate('Int|HashRef', {});
    ok !validate('Int|HashRef', 'hoge');

    ok  validate('t::SomeModel', t::SomeModel->new);
    ok  validate('Int|t::SomeModel', 123);
    ok  validate('Int|t::SomeModel', t::SomeModel->new);
    ok !validate('Int|t::SomeModel', 'hoge');
};

subtest 'other Ref' => sub {
    ok !validate(\'Int', 1);
    ok !validate('Int', \1);
    ok !validate(\{ a => 'Str' }, { a => 'hoge' });
    ok !validate({ a => 'Str' }, \{ a => 'hoge' });
};

subtest 'undef' => sub {
    ok  validate('Undef', undef);
    ok !validate(undef, undef);
};

done_testing;
