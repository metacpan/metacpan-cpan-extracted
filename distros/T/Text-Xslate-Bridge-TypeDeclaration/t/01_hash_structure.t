use strict;
use warnings;
use lib '.';

use t::helper;
use Test::More;

use Text::Xslate::Bridge::TypeDeclaration;

*_hash_structure = \&Text::Xslate::Bridge::TypeDeclaration::_hash_structure;

sub validate {
    my ($structure, $data) = @_;
    return _hash_structure($structure)->check($data);
}

my $data = {
    a => 123,
    b => 'hoge',
    c => t::SomeModel->new,
    d => undef,
    e => { a => 'foo' },
};

my $structure = {
    a => 'Int',
    b => 'Str',
    c => 't::SomeModel',
    d => 'Undef',
    e => { a => 'Str' },
};

ok  validate($structure, $data);
ok !validate($structure, $structure);
ok !validate($data, $data);

ok !validate({ %$structure, a => 'ClassName' },    $data);
ok !validate({ %$structure, b => 'Int' },          $data);
ok !validate({ %$structure, c => 'Str' },          $data);
ok !validate({ %$structure, d => 'Defined' },      $data);
ok !validate({ %$structure, e => { a => 'Int' } }, $data);

subtest 'missing & extra' => sub {
    ok validate({
        a => 'Int',
        b => 'Str',
        c => 't::SomeModel',
        # missing d
        e => 'HashRef'
    }, $data);

    ok !validate({ %$structure, f => 'Str' }, $data);
    ok  validate({ %$structure, f => 'Undef' }, $data);
};

subtest 'acceptable types' => sub {
    ok validate({
        a => 'Num',
        b => 'Value',
        c => 'Ref',
        d => 'Maybe[Str]',
        e => 'HashRef[Str]',
    }, $data);
};

subtest 'nested' => sub {
    ok validate(
        { a => { b => { c => { d => 'Str' } } } },
        { a => { b => { c => { d => 'e'   } } } },
    );
};

subtest 'maybe' => sub {
    ok  validate({ key => 'Maybe[Int]' }, {});
    ok  validate({ key => 'Maybe[Int]' }, { key => 123 });
    ok  validate({ key => 'Maybe[Int]' }, { key => undef });
    ok !validate({ key => 'Maybe[Int]' }, { key => 'hoge' });

    ok !validate({ key1 => { key2 => 'Maybe[Str]' } }, {});
    ok  validate({ key1 => { key2 => 'Maybe[Str]' } }, { key1 => {} });
    ok !validate({ key1 => { key2 => 'Maybe[Str]' } }, { key1 => undef });
    ok  validate({ key1 => { key2 => 'Maybe[Str]' } }, { key1 => { key2 => 'hoge'} });
    ok  validate({ key1 => { key2 => 'Maybe[Str]' } }, { key1 => { key2 => undef } });
};

subtest 'empty' => sub {
    ok  validate({}, {});
    ok !validate({}, undef);
};

subtest 'recursive' => sub {
    my $part = {};
    $part->{key} = $part;
    ok !validate($part, { key => { key => { key => 'value' } } });
    undef $part;
};

done_testing;
