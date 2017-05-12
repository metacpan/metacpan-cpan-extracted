BEGIN {

    use FindBin;
    use lib $FindBin::Bin . "/myapp/lib";

}

use utf8;
use Test::More;

{

    # testing the directive method
    # this method is designed to register field directives which V::C will make
    # available to all classes when instantiated

    package MyApp1;

    use Validation::Class;

    dir is_true => sub {1};
    fld name => {is_true => 1, required => 1,};

    package MyApp2;

    use Validation::Class;

    directive is_true => sub {1};
    field name => {is_true => 1, required => 1,};

    package MyApp3;

    use Validation::Class;

    fld name => {

        is_true  => 1,
        required => 1,

    };

    package main;

    my ($class, $self);

    $class = "MyApp1";
    $self = $class->new(name => "...");

    ok $class eq ref $self, "$class instantiated";

    $self = undef;

    $class = "MyApp2";
    $self = $class->new(name => "...");

    ok $class eq ref $self, "$class instantiated";

    $self = undef;

    $class = "MyApp3";
    eval { $self = $class->new(name => "...") };

    ok $@ =~ /directive.*not supported/,
      "$class NOT instantiated, bad directive";

}

done_testing;
