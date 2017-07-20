use strict;
use warnings;
use lib '.';

use t::helper;
use Test::More;

use Text::Xslate::Bridge::TypeDeclaration;
use Text::Xslate::Bridge::TypeDeclaration::Registry;

*_type = \&Text::Xslate::Bridge::TypeDeclaration::_type;

sub validate {
    my ($structure, $data) = @_;
    my $reg = Text::Xslate::Bridge::TypeDeclaration::Registry->new;
    return _type($structure, $reg)->check($data);
}

subtest 'returns Type::Tiny' => sub {
    ok _type('Str')->isa('Type::Tiny');
    ok _type('Maybe[Str]')->isa('Type::Tiny');
    ok _type([ 'Int', 'Str' ])->isa('Type::Tiny');
    ok _type({ key => 'Str' })->isa('Type::Tiny');
    ok _type(undef)->isa('Type::Tiny');
    ok _type(\'Hoge')->isa('Type::Tiny');
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

subtest 'invaid' => sub {
    ok !validate('', undef);
    ok !validate(undef, undef);

    my $type = Text::Xslate::Bridge::TypeDeclaration::_get_invalid_type('InvalidTypeName');
    ok !$type->check('');
    is $type->get_message(''), '"InvalidTypeName" is not a known type';
};

done_testing;
