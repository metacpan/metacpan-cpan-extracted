use Test::More tests => 4;

BEGIN {
    use_ok( 'Variable::Strongly::Typed' );
}

diag( "Testing Variable::Strongly::Typed $Variable::Strongly::Typed::VERSION" );

my $only_44 :TYPE(\&only_44);

sub only_44 {
    my($val) = shift;
    diag("Valid sub got $val");

    $val == 44;
}

eval {
    $only_44 = 33;
};
ok($@, "Can only be 44!!");

$only_44 = 44;
is(44, $only_44);

# taking a reference to defeat won't work!!!
my $r44 = \$only_44;

eval {
$$r44 = 9999;
};
ok($@, "Changing a reference won't work!!");

diag("only_44 is now $only_44\n");
