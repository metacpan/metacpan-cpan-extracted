use Test::More tests => 23;
BEGIN { use_ok 'WWW::Yahoo::Groups' }

my $w = WWW::Yahoo::Groups->new();

isa_ok( $w => 'WWW::Yahoo::Groups' );

# Our special user, as usual
$w->login( 'perligain7ya5h00grrzogups' => 'redblacktrees' );

# Our special list
testlist( $w => 'www_yaho_t' );

# Get a supposedly valid RSS feed
{
    my $rsscontent = eval { $w->fetch_rss() };
    fetchtest($@);
    my @items = $rsscontent =~ /(<item>)/g;
    ok ( 2 == @items, "There are indeed only two items." );
}


# Try for a bad fetch
{
    # This list shouldn't exist
    testlist( $w => 'www_yaho_txmg' );
    # Fetch RSS
    my $rsscontent = eval { $w->fetch_rss() };
    if ($@ and ref $@ and $@->isa('X::WWW::Yahoo::Groups::UnexpectedPage')) {
	pass("RSS fetch failed ".$@->error);
    } elsif ($@) {
	fail("RSS fetch failed, for some reason.");
	diag $@;
    } else {
	fail("RSS fetch succeeded.");
    }
}

# Get another supposedly valid RSS feed
{
    testlist( $w => 'Jade_Pagoda' );
    {
	my $rsscontent = eval { $w->fetch_rss() };
	fetchtest($@);
	my @items = $rsscontent =~ /(<item>)/g;
	ok ( 30 == @items, "There should be 30 items by default." );
    }
    for my $wanted ( sort { $a <=> $b } qw( 1 29 31 99 100 ) )
    {
	my $rsscontent = eval { $w->fetch_rss( $wanted ) };
	fetchtest($@);
	my @items = $rsscontent =~ /(<item>)/g;
	ok ( $wanted == @items, "There should be $wanted items, like we asked. (".@items.")" );
    }


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

sub fetchtest
{
    my $error = shift;
    if ($error and ref $error and $error->isa('X::WWW::Yahoo::Groups')) {
	fail("RSS fetch failed ".$error->error);
    } elsif ($error) {
	fail("RSS fetch failed, for some reason.");
	diag $error;
    } else {
	pass("RSS fetch succeeded.");
    }
}
