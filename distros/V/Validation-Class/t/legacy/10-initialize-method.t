BEGIN {

    use FindBin;
    use lib $FindBin::Bin . "/myapp/lib";

}

use utf8;
use Test::More;

{

 # testing the initialize method
 # this method is designed to allow the Validation::Class framework to wrap
 # an existing class configuration, most useful with OO systems like Moose, etc

    package MyApp;

    sub new {

        my ($class) = @_;

        my $self = bless {}, $class;

        return $self;

    }

    use Validation::Class 'field';

    field name => {

        required => 1

    };

    package main;

    my $class = "MyApp";

    my $self = $class->new(name => "...");

    ok $class eq ref $self, "$class instantiated";

    eval { $self->name };

    ok !$@, "$class has a name field";

    eval { $self->initialize_validator };

    ok !$@, "$class has initialized with no errors";

}

{

    # testing initialization and parameter handling

    package MyApp::A;

    use Validation::Class;

    field numbers => {

        required => 1,
        filters  => ['numeric']

    };

    package main;

    my $class = "MyApp::A";

    my $self = $class->new(params => {numbers => [2, 1]});

    ok "ARRAY" eq ref $self->numbers, "numbers method has an arrayref";

    ok $self->numbers->[0] == 2, "numbers array #0 is correct";
    ok $self->numbers->[1] == 1, "numbers array #1 is correct";

}

{

    # testing initialization and parameter handling

    package MyApp::B;

    use Validation::Class;

    field numbers => {

        required => 1

    };

    package main;

    my $class = "MyApp::A";

    my $self = $class->new(numbers => 12345);

    ok 12345 == $self->numbers, "numbers method has 12345 as expected";

}

done_testing;
