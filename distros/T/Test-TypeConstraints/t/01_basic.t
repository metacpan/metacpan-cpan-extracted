package Fuga;
use Mouse::Role;

package Hoge;
use Mouse;
with "Fuga";

package main;
use strict;
use warnings;
use Test::TypeConstraints qw(type_isa type_does);
use Test::More;
use Mouse::Util::TypeConstraints qw(subtype as where coerce from via );

subtest "Mouse TypeConstraints name str ok" => sub {
    subtest "success" => sub {
        type_isa([1, 2, 3], "ArrayRef[Int]", "Mouse TypeConstraints name str ok");
    };
};

my $hoge = Hoge->new;

type_isa($hoge, "Hoge", "class name ok");
type_does($hoge, "Fuga", "role name ok");

my $subtype = subtype 'HogeClass' => as 'Object' => where { $_->isa("Hoge") } ;
type_isa($hoge, $subtype, "Mouse TypeConstraints object ok");

coerce 'HogeClass'
    => from 'Str'
        => via { Hoge->new };

type_isa("hoge", "HogeClass", "coerce Str ok", coerce => 1);

done_testing();
