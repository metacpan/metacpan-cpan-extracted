BEGIN {

    use FindBin;
    use lib $FindBin::Bin . "/myapp/lib";

}

use utf8;
use Test::More;

{

    # github issue 20
    # https://github.com/alnewkirk/Validation-Class/issues/20
    # test that the Validation::Class::Field object has the desired accessors

    package TestClass::FieldObjectTest;
    use Validation::Class;

    fld name => {required => 1};

    package main;

    my $class = "TestClass::FieldObjectTest";
    my $self = $class->new(name => "don johnson");

    $self->validate;    # assures we have a value in our field obj

    ok $class eq ref $self, "$class instantiated";

    my $proto = $self->proto;
    my $name  = $proto->fields->get('name');

    ok "Validation::Class::Field" eq ref $name,
      "$class has field name which is a V::C::Field object";

    ok $name->name,  "name field has name method";
    ok $name->value, "name field has value method";

}

done_testing;
