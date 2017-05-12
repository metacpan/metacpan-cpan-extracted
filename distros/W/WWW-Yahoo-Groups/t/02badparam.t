use Test::More tests => 32;
BEGIN { use_ok 'WWW::Yahoo::Groups' }

my $w = WWW::Yahoo::Groups->new();

isa_ok( $w => 'WWW::Yahoo::Groups' );

# Things to test. These are all meant to fail.

my %subs = (
    login_named_dash => sub {
	$w->login(
	    -user => 'fnurdle',
	    -pass => 'gibberty'
	);
    },
    login_named => sub {
	$w->login(
	    user => 'fnurdle',
	    pass => 'gibberty'
	);
    },
    login_insufficient => sub { $w->login( 'fnurdle' ) },
    login_toomany => sub { $w->login( 'fnurdle', 'knud', 'grue' ) },
    login_arrayref => sub { $w->login( [ 'fnurdle' ], [ 'gibberty' ] ) },

    autosleep_toomany => sub { $w->autosleep( 2, 3 ) },
    autosleep_string => sub { $w->autosleep( 'fnurdle' ) },
    autosleep_subzero => sub { $w->autosleep( -1 ) },
    autosleep_undef => sub { $w->autosleep( undef ) },
    autosleep_fractional => sub { $w->autosleep( 1.3 ) },

    fetch_message_toomany => sub { $w->fetch_message( 2, 3 ) },
    fetch_message_string => sub { $w->fetch_message( 'fnurdle' ) },
    fetch_message_zero => sub { $w->fetch_message( 0 ) },
    fetch_message_undef => sub { $w->fetch_message( undef ) },
    fetch_message_fractional => sub { $w->fetch_message( 1.3 ) },
    fetch_message_insufficient => sub { $w->fetch_message( ) },

    list_blank => sub { $w->list( '' ) },
    list_toomany => sub { $w->list('fred', 'bob') },
    list_badchars => sub { $w->list( 'fred::bob' ) },

    lists_toomany => sub { $w->lists( 5 ) },
    last_msg_id_toomany => sub { $w->last_msg_id( 5 ) },
    first_msg_id_toomany => sub { $w->first_msg_id( 5 ) },
    loggedin_toomany => sub { $w->loggedin( 5 ) },
    logout_toomany => sub { $w->logout( 5 ) },

    fetch_rss_toomany => sub { $w->fetch_rss( 2, 3 ) },
    fetch_rss_string => sub { $w->fetch_rss( 'fnurdle' ) },
    fetch_rss_zero => sub { $w->fetch_rss( 0 ) },
    fetch_rss_hundred_one => sub { $w->fetch_rss( 101 ) },
    fetch_rss_undef => sub { $w->fetch_rss( undef ) },
    fetch_rss_fractional => sub { $w->fetch_rss( 1.3 ) },
);

# Test that they all fail
# That is, it's a success if they fail and a failure if they succeeed.

foreach my $key (sort keys %subs)
{
    eval { $subs{$key}->() };
    if ($@ and ref $@ and $@->isa('X::WWW::Yahoo::Groups::BadParam')) {
	pass("$key: ".$@->error);
    } elsif ($@) {
	fail("$key: Failed, but not the right way.");
        diag $@;
    } else {
	fail("$key: Did not fail, but was meant to.");
    }
}
