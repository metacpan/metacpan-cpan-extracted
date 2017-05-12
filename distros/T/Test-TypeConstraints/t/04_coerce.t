#!/usr/bin/perl

use strict;
use warnings;

use Test::TypeConstraints;
use Test::More;

use Mouse::Util::TypeConstraints;

{
    package Some::Class;
    use Mouse;

    has value =>
      is  => 'ro',
      isa => 'Str';
}

coerce "Some::Class" =>
  from "Str",
  via { Some::Class->new({ value => $_ }) };

{
    my $value = "something";
    type_isa $value, "Some::Class", "coerce to Some::Class", coerce => sub {
        isa_ok $_[0], "Some::Class";
        is $_[0]->value, $value;
    };
}

done_testing;
