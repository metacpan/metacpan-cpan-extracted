BEGIN {

    use FindBin;
    use lib $FindBin::Bin . "/myapp/lib";

}

use utf8;
use Test::More;

{

    # testing the attribute method
    # this method is designed to add accessors to the calling class
    # this method can also be referred to as has()

    package MyApp;

    use Validation::Class;

    attribute name => 'Thomas';
    attribute sex  => 'M';

    has age => 23;

    attribute type => sub {
        my ($self) = @_;
        if ($self->age > 21) {
            if ($self->sex eq 'M') {
                return 'Man';
            }
            if ($self->sex eq 'M') {
                return 'Woman';
            }
        }
        else {
            if ($self->sex eq 'M') {
                return 'Boy';
            }
            if ($self->sex eq 'M') {
                return 'Girl';
            }
        }
    };

    has slang_type => sub {
        my ($self) = @_;
        if ($self->age > 21) {
            if ($self->sex eq 'M') {
                return 'Oldhead';
            }
            if ($self->sex eq 'M') {
                return 'Oldjawn';
            }
        }
        else {
            if ($self->sex eq 'M') {
                return 'Youngbawl';
            }
            if ($self->sex eq 'M') {
                return 'Youngjawn';
            }
        }
    };

    __PACKAGE__->attribute(class => 'upper')
      ;    # override the existing class method

    package main;

    my $class = "MyApp";
    my $self  = $class->new;

    ok $class eq ref $self, "$class instantiated";

    ok 'Thomas' eq $self->name, 'The name attribute has the correct value';
    ok 'M'      eq $self->sex,  'The sex attribute has the correct value';
    ok 23       eq $self->age,  'The age attribute has the correct value';
    ok 'Man'    eq $self->type, 'The type attribute has the correct value';
    ok 'Oldhead' eq $self->slang_type,
      'The slang_type attribute has the correct value';
    ok 'upper' eq $self->class, 'The class attribute has the correct value';

}

done_testing;
