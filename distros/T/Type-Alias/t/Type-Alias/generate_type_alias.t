use strict;
use warnings;
use Test::More;

use Type::Alias ();
use Types::Standard -types;

subtest 'If type constraint object is passed, return type alias coderef.' => sub {
    my $type_alias = Type::Alias::generate_type_alias(Int);
    is $type_alias->(), Int;
    is prototype($type_alias), '';
};

subtest 'If arrayref is passed, return Tuple type alias coderef.' => sub {
    my $type_alias = Type::Alias::generate_type_alias([Int, Str]);
    is $type_alias->(), Tuple[Int, Str];
    is prototype($type_alias), '';
};

subtest 'If hashref is passed, return Dict type alias coderef.' => sub {
    my $type_alias = Type::Alias::generate_type_alias({ id => Int, name => Str });
    is $type_alias->(), Dict[id => Int, name => Str];
    is prototype($type_alias), '';
};

subtest 'If coderef is passed, return type function coderef.' => sub {
    my $coderef = sub {
        my ($R) = @_;
        $R ? ArrayRef[$R] : ArrayRef;
    };

    my $type_alias = Type::Alias::generate_type_alias($coderef);
    is $type_alias->([Int]), ArrayRef[Int];
    is $type_alias->([]), ArrayRef;
    is $type_alias->(), ArrayRef;
    is prototype($type_alias), ';$';
};

done_testing;
