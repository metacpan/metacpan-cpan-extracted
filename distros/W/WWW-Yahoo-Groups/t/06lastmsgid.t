use strict;
use Test::More tests => 16;
BEGIN { use_ok 'WWW::Yahoo::Groups' }

my $w = WWW::Yahoo::Groups->new();

isa_ok( $w => 'WWW::Yahoo::Groups' );

# Our special user
$w->login( 'perligain7ya5h00grrzogups' => 'redblacktrees' );
ok( $w->loggedin, "We are logged in" );

# First, we've no list
my $last = eval { $w->last_msg_id() };
if ($@ and ref $@ and $@->isa( 'X::WWW::Yahoo::Groups::NoListSet' )) {
    pass $@->error;
} elsif ($@) {
    fail "No list set: unexpected error $@";
} else {
    fail "No list set: received no error";
}

{
    testlist( $w => 'www_yaho_t' );
    my $first = eval { $w->first_msg_id() };
    if ($@ and ref $@ and $@->isa( 'X::WWW::Yahoo::Groups' ) ) {
	fail "first_msg_id(): ".$@->error;
    } elsif ($@) {
	fail "first_msg_id(): $@";
    } else {
	pass "first_msg_id(): Fetched a response";
    }

    is ($first => 1, "Message count is accurate ($first)");
}

{
    testlist( $w => 'www_yaho_t' );
    my $last = eval { $w->last_msg_id() };
    if ($@ and ref $@ and $@->isa( 'X::WWW::Yahoo::Groups' ) ) {
	fail "last_msg_id(): ".$@->error;
    } elsif ($@) {
	fail "last_msg_id(): $@";
    } else {
	pass "last_msg_id(): Fetched a response";
    }

    is ($last => 2, "Message count is accurate ($last)");
}

{
    testlist( $w => 'Jade_Pagoda' );
    my $last = eval { $w->last_msg_id() };
    if ($@ and ref $@ and $@->isa( 'X::WWW::Yahoo::Groups' ) ) {
	fail "last_msg_id(): ".$@->error;
    } elsif ($@) {
	fail "last_msg_id(): $@";
    } else {
	pass "last_msg_id(): Fetch a response";
    }

    ok ($last >= 53440, "Message count is probably accurate ($last)");
}

sub testlist
{
    my ($self, $list) = @_;
    $list = eval {
	$w->list( $list );
	return $w->list();
    };
    if ($@ and ref $@ and $@->isa('X::WWW::Yahoo::Groups')) {
	fail("Failed setting/getting list: ".$@->error);
    } elsif ($@) {
	fail("Failed setting/getting list");;
    } else {
	pass("Did not fail setting list.");
    }
    is($list => $list => 'List set correctly.');
}
