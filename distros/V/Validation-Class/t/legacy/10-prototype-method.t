BEGIN {

    use FindBin;
    use lib $FindBin::Bin . "/myapp/lib";

}

use utf8;
use Test::More;

{

    # testing the prototype method
    # this method is designed to ....

    package MyApp;

    use Validation::Class;

    fld name => {

        required => 1

    };

    package main;

    my $class = "MyApp";
    my $self = $class->new(name => "...");

    ok $class eq ref $self, "$class instantiated";

}

done_testing;
