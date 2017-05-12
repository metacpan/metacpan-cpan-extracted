use Test::More tests => 7;
BEGIN { use_ok 'WWW::Yahoo::Groups' }

{
    my $w = WWW::Yahoo::Groups->new();

    isa_ok( $w => 'WWW::Yahoo::Groups' );

    ok ( !$w->loggedin, "We are not logged in");

    # First, we're not logged in
    eval { $w->lists() };
    if ($@ and ref $@ and $@->isa( 'X::WWW::Yahoo::Groups::NotLoggedIn' )) {
	pass "One cannot fetch lists while not logged in.";
    } elsif ($@) {
	fail "Not logged in: unexpected error $@";
    } else {
	fail "Not logged in: received no error";
    }
}

# Our special user, as usual
test_lists( 'perligain7ya5h00grrzogups' => 'redblacktrees' => 3 );

sub test_lists
{
    my ($user, $pass, $intended) = @_;
    my $w = WWW::Yahoo::Groups->new();
    $w->login( $user => $pass );

    ok ( $w->loggedin, "We are logged in");

    my @lists = eval { $w->lists() };
    if ($@ and ref $@ and $@->isa( 'X::WWW::Yahoo::Group' )) {
	fail "Should have received list of groups: ".$@->error
    } elsif ($@) {
	fail "Should have received list of groups: unexpected error $@";
    } else {
	pass "Received list of groups";
    }

    diag "[ @lists ]";

    ok (@lists == $intended, "List count is accurate (".@lists.")");
}
