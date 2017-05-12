# chompp.t

use Test::Most;

use Text::Chompp qw/ chompp /;

my @tests = (
    {   name   => 'scalar',
        sub    => sub { chompp "hello\n" },
        result => "hello",
    },
    {   name => 'list',
        sub  => sub { [ chompp "hello\n", "there\n" ] },
        result => [ "hello", "there" ],
    },
    {   name => 'map',
        sub  => sub {
            [ map {chompp} "hello\n", "there\n" ];
        },
        result => [ "hello", "there" ],
    },
    {   name => 'map with $_',
        sub  => sub {
            [ map { chompp $_ } "hello\n", "there\n" ];
        },
        result => [ "hello", "there" ],
    },
    {   name => 'foreach',
        sub  => sub {
            my @chompped;
            push @chompped, chompp foreach ( "hello\n", "there\n" );
            return \@chompped;
        },
        result => [ "hello", "there" ],
    },

);

foreach my $test (@tests) {

    note $test->{name};

    is_deeply $test->{sub}->(), $test->{result}, "result ok";
}

note "testing input unchanged";

my $input = "hello\n";
ok my $output = chompp($input), "chompp";

is $input,  "hello\n", "input unchanged";
is $output, "hello",   "output chompped";

done_testing();

