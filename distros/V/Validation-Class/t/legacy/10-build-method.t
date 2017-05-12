BEGIN {

    use FindBin;
    use lib $FindBin::Bin . "/myapp/lib";

}

use utf8;
use Test::More;

{

    # testing the build method
    # this method is designed to hook into the class instantiation processs

    package MyApp;

    use Validation::Class;

    has number => 0;

    my $incrementer = sub {

        my ($self) = @_;

        $self->number($self->number + 1);

    };

    build $incrementer;

    __PACKAGE__->bld($incrementer);

    package main;

    my $class = "MyApp";
    my $self  = $class->new();

    ok $class eq ref $self, "$class instantiated";

    ok 2 == $self->number, 'the number attribute has been incremented on init';

}

done_testing;
