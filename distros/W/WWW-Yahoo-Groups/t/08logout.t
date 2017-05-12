use Test::More tests => 11;
BEGIN { use_ok 'WWW::Yahoo::Groups' }

my $w = WWW::Yahoo::Groups->new();

isa_ok( $w => 'WWW::Yahoo::Groups' );

my $rv = eval { $w->logout() };
if ($rv and ref $rv and $rv->isa('X::WWW::Yahoo::Groups::NotLoggedIn') ) {
    pass("Can not log out if not logged in.");
} elsif ($rv) {
    fail("logout(): unexpected error: $rv");
} else {
    fail("logout(): Expected error, did not receive one.");
}

for (1..2)
{
    eval { $w->login( 'perligain7ya5h00grrzogups' => 'redblacktrees' ) };
    ok (!$@, "Logged in");
    ok ($w->loggedin, "Am logged in");

    eval { $w->logout( ) };
    ok (!$@, "Logged out");
    diag $@ if $@;
    ok (!$w->loggedin, "Am logged out");
}
