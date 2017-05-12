#!perl -T

use Test::More tests => 6;

BEGIN {
    use_ok( 'WWW::Namecheap::API' );
    use_ok( 'WWW::Namecheap::Domain' );
    use_ok( 'WWW::Namecheap::DNS' );
    use_ok( 'WWW::Namecheap::NS' );
    use_ok( 'WWW::Namecheap::SSL' );
    use_ok( 'WWW::Namecheap::User' );
}

diag( "Testing WWW::Namecheap::API $WWW::Namecheap::API::VERSION, Perl $], $^X" );
