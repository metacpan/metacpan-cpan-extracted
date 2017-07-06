use strict;
use warnings;
use lib '.';

use t::helper;
use Test::More;

use Text::Xslate::Bridge::TypeDeclaration;

*_array_structure = \&Text::Xslate::Bridge::TypeDeclaration::_array_structure;

sub validate {
    my ($structure, $data) = @_;
    return _array_structure($structure)->check($data);
}

my $data      = [ 123, 'hoge', t::SomeModel->new, undef, { a => 'foo' } ];
my $structure = [ 'Int', 'Str', 't::SomeModel', 'Undef', { a => 'Str' } ];

ok  validate($structure, $data);
ok !validate($structure, $structure);
ok !validate($data, $data);

my $t;
ok !validate(do { ($t = [ @$structure ])->[0] = 'ClassName';    $t }, $data);
ok !validate(do { ($t = [ @$structure ])->[1] = 'Int';          $t }, $data);
ok !validate(do { ($t = [ @$structure ])->[2] = 'Str';          $t }, $data);
ok !validate(do { ($t = [ @$structure ])->[3] = 'Defined';      $t }, $data);
ok !validate(do { ($t = [ @$structure ])->[4] = { a => 'Int' }; $t }, $data);

subtest 'missing & extra' => sub {
    ok !validate([ @$structure[1..4]], $data);     # missing first
    ok !validate([ @$structure[0..3]], $data);     # missing last
    ok !validate([ 'Maybe', @$structure ], $data); # extra first
    ok !validate([ @$structure, 'Maybe' ], $data); # extra last
};

subtest 'acceptable types' => sub {
    ok validate([ 'Num', 'Value', 'Ref', 'Item', 'HashRef[Str]' ], $data);
    ok validate([ 'Str', 'Defined', 'Object', 'Any', 'HashRef' ], $data);
};

subtest 'nested' => sub {
    ok validate(
        [ 'Int', [ 'Str', [ 'Int', [ 'Num', [ 'Int' ] ] ] ] ],
        [ 1, [ 'two', [ 3, [ 4.1, [ 5 ] ] ] ] ],
    );

    ok validate(
        [ 'Int', [ 'Str', [ 'Int', [ 'Num', 'ArrayRef[Int]' ] ] ] ],
        [ 1, [ 'two', [ 3, [ 4.1, [ 5 ] ] ] ] ],
    );
};

subtest 'maybe' => sub {
    ok  validate([ 'Maybe[Str]' ], [ undef ]);
    ok !validate([ 'Maybe[Str]' ], []);
};

subtest 'empty' => sub {
    ok  validate([], []);
    ok !validate([], [ undef ]);
};

subtest 'recursive' => sub {
    my $part = [ 'Int' ];
    push @$part, $part;
    ok !validate($part, [ 1, [ 2 ] ]);
    undef $part;
};

done_testing;
