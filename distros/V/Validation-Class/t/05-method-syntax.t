use FindBin;
use Test::More;

use utf8;
use strict;
use warnings;

{

    package TestClass::MethodCalling;
    use Validation::Class;

    field constraint => {required => 1};

    method check_a => {input => ['constraint']};
    sub _check_a {'check_a OK'}

    method a_check => {input => ['constraint']};
    sub _process_a_check {'check_a OK'}

    package main;

    my $class = "TestClass::MethodCalling";
    my $self  = $class->new;

    ok $class eq ref $self, "$class instantiated";

    $self->constraint('h@ck');

    ok 'check_a OK' eq $self->check_a,
      "$class check_a method spec'd and validated";

    for (1..5) {
        ok 'check_a OK' eq $self->a_check,
          "$_: $class a_check method spec'd and validated";
        ok 1 == $self->validate_method('a_check'),
          "$_: $class a_check method validated but NOT executed";
        ok 'check_a OK' eq $self->a_check,
          "$_: $class a_check method spec'd and validated (again)";
    }

    $self->constraint(undef);

    ok !defined  $self->a_check,
      "$class a_check method failed to validate";
    
    $self->constraint('stuff');

    ok 'check_a OK' eq $self->a_check,
        "$class a_check method spec'd and validated";

    $self->constraint(undef);

    ok 0 == $self->validate_method('a_check'),
      "$class a_check method does NOT validate and is NOT executed";

    $self->constraint('stuff');

    ok 'check_a OK' eq $self->a_check,
      "$class a_check method spec'd and validated (again)";

}

done_testing;
