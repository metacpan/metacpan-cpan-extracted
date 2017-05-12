package FakeDancerApp;

sub new {
   my $class = shift;
   bless {}, 'FakeDancerApp';
}

my $app = sub {
    my $env = shift;
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ "Hello from Dancer" ] ],
};

sub dance {
    sub { my $res = $app->(shift); sub { shift->($res); } }
}

1;
