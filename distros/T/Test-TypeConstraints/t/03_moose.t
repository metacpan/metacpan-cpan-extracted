use strict;
use warnings;
use Test::Requires qw(Moose::Role Moose::Role Moose::Util::TypeConstraints);

package Fuga;
use Moose::Role;

package Hoge;
use Moose;

with "Fuga";

package main;
use strict;
use warnings;
use Test::More;
use Test::TypeConstraints qw(type_isa type_does);

my $hoge = Hoge->new;

my $subtype = subtype 'HogeClass' => as 'Object' => where { $_->isa("Hoge") } ;
isa_ok($subtype, "Moose::Meta::TypeConstraint");

type_isa($hoge, $subtype, "Moose TypeConstraint object ok");
type_does($hoge, $subtype, "Moose::Role ok");

done_testing();
