use Test::More tests => 4;
BEGIN { use_ok 'WWW::Yahoo::Groups' }

my $w = WWW::Yahoo::Groups->new();

isa_ok( $w => 'WWW::Yahoo::Groups' );

eval {
    $w->login('fnurdle' => 'gibberty');
};
if ($@ and ref $@ and $@->isa('X::WWW::Yahoo::Groups')) {
    pass("Login failed: ".$@->error);
} elsif ( $@ ) {
    fail("Unexpected error.");
    diag $@;
} else {
    fail("Login succeeded, despite being meant to fail.");
}

eval {
    $w->fetch_message( 1 );
};
if ($@ and ref $@ and $@->isa('X::WWW::Yahoo::Groups::NoListSet')) {
    pass("Fetch failed: ".$@->error);
} else {
    fail("Fetch succeeded, despite being meant to fail.");
}
