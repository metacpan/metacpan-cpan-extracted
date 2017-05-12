use utf8;
use Test::More;
use Data::Dumper;
use FindBin;

{

    package TestClass::FieldsAccess;

    use Validation::Class;

    fld name => {required => 1};

    package main;

    my $class = "TestClass::FieldsAccess";
    my $self = $class->new(name => undef);

    my $proto = $self->proto;
    my $name  = $proto->fields->name;

    ok "Validation::Class::Field" eq ref $name,
      "$class has field name which is a V::C::Field object";

    eval { $proto->fields->something };

    ok $@, "error occurred trying to execute a method named something, which doesn't exist, as expected";

    ok $name->has('name'),  "name field has name method";
    ok $name->has('value'), "name field has value method";

}

done_testing;
