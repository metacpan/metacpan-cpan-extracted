use Test::More tests => 3;
BEGIN { use_ok 'WWW::Yahoo::Groups' }

my $w = WWW::Yahoo::Groups->new();

isa_ok( $w => 'WWW::Yahoo::Groups' );

my $rv =  $w->get( "http://dellah.org/doesnotexist") ;
#diag sprintf("rv <$rv> [%s] {%s}", ref($rv), ((ref $rv and $rv->can('fatal')) ? $rv->fatal : 'na'));
if ($rv and ref $rv and $rv->isa('X::WWW::Yahoo::Groups::BadFetch') ) {
    pass("Correctly given a fatal BadFetch.");
} elsif ($rv) {
    fail("badfetch: unexpected error");
    diag $rv;
} else {
    fail("badfetch: Expected error, did not receive one.");
}
