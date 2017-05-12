use FindBin;
use Test::More;

use utf8;
use strict;
use warnings;

use Data::Dumper;

{

    package TestClass::CheckParameters;
    use Validation::Class;

    fld name => {required => 1};

    package main;

    my $class = "TestClass::CheckParameters";
    my $self  = $class->new;

    ok $class eq ref $self, "$class instantiated";

    my @vals = qw(
      Kathy
      Joe
      John
      O
      1
      234
      Ricky
      ~
      '
      Lady
      §§
      ♠♣♥♦♠♣♥♦♠♣♥♦
    );

    for my $v (@vals) {

        ok $v eq $self->name($v),
          "$class name accessor set to `$v` with expected return value"

    }

    for my $v (@vals) {

        my $name_param = $self->name($v);

        ok $self->params->{name} eq $name_param,
          "$class name parameter set to `$v` using the name accessor"

    }

}

{

    package TestClass::ArrayParameters;
    use Validation::Class;

    bld sub {
        shift->name([1 .. 5]);
    };

    fld name => {required => 1};

    package main;

    my $class = "TestClass::ArrayParameters";
    my $self  = $class->new;

    ok $class eq ref $self, "$class instantiated";

    ok "ARRAY" eq ref $self->name, "$class name accessor returns an array";

    ok !ref $self->name(''), "$class name accessor returns nothing";

    ok !eval { $self->name({1 .. 4}) }, "$class name accessor cant set a hash";

    ok "ARRAY" eq ref $self->name([1 .. 5]),
      "$class name accessor returns an array";

    ok "ARRAY" eq ref $self->params->{name}, "$class name param is an array";

    ok "ARRAY" eq ref $self->name, "$class name accessor returns the array";

}

{

    package TestClass::FieldAccessors;
    use Validation::Class;

    fld 'name.first' => {required => 1};

    fld 'name.last' => {required => 1};

    fld 'name.phone:0' => {required => 0};

    fld 'name.phone:1' => {required => 0};

    fld 'name.phone:2' => {required => 0};

    package main;

    my $class = "TestClass::FieldAccessors";
    my $self  = $class->new;

    ok $class eq ref $self, "$class instantiated";

    my @accessors = ();

    {

        no strict 'refs';

        @accessors =
          sort grep { defined &{"$class\::$_"} && $_ =~ /^name/ }
          %{"$class\::"};

        ok 5 == @accessors, "$class has 5 name* accessors";

    }

    ok $accessors[0] eq 'name_first',   "$class has the name_first accessor";
    ok $accessors[1] eq 'name_last',    "$class has the name_last accessor";
    ok $accessors[2] eq 'name_phone_0', "$class has the name_phone_0 accessor";
    ok $accessors[3] eq 'name_phone_1', "$class has the name_phone_1 accessor";
    ok $accessors[4] eq 'name_phone_2', "$class has the name_phone_2 accessor";

}

{

    package TestClass::FieldAppend::Role;
    use Validation::Class;

    fld 'title'   => {length => 1};
    fld 'surname' => {min_length => 1};

    package TestClass::FieldAppend;
    use Validation::Class;
    set role => 'TestClass::FieldAppend::Role';

    fld '+title'    => {required => 0, min_length => 1};
    fld '++surname' => {max_length => 1};

    package main;

    my $class   = "TestClass::FieldAppend";
    my $self    = $class->new;
    my $title   = $self->fields->get('title');
    my $surname = $self->fields->get('surname');

    ok $class eq ref $self, "$class instantiated";

    ok(((!defined $title->{length} && defined $title->{required} && defined $title->{min_length}) and ($title->{required} == 0 && $title->{min_length} == 1)), "$class title field was overriden");
    ok(((defined $surname->{min_length} && defined $surname->{max_length}) and ($surname->{min_length} == 1 && $surname->{max_length} == 1)), "$class surname field was appended");

}

done_testing;
