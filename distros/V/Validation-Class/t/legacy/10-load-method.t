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

    package MyApp;

    use Validation::Class;

    load classes => 1;

    field name => {

        required => 1

    };

    package main;

    my $class = "MyApp";

    my $self = $class->new(name => "don johnson");

    ok $class eq ref $self, "$class instantiated";

    my $test = $self->class('test');

    ok "MyApp::Test" eq ref $test, ref($test) . " instantiated";

    # depreciated - $test = $self->class(-name => 'test');
    #ok "MyApp::Test" eq ref $test, ref($test) . " instantiated";

}

done_testing;
