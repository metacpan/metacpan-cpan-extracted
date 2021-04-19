use Test2::V0;
plan tests => 1;

use self;

sub p {
    is $self, "ok";
}

p("ok");
diag( "Testing self $self::VERSION" );
