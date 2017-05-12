use Test::Simple tests => 5;

use XML::RSS::FOXSports;

my $fsp = XML::RSS::FOXSports->new();
ok( defined($fsp) && ref $fsp eq 'XML::RSS::FOXSports',     'new() works'  );
ok( $fsp->_na eq 'not available',         '_na() notice works'            );
ok( defined($fsp->http_timeout),          'http_timeout() get works'      );
ok( defined($fsp->get_available_leagues), 'get_available_leagues() works' );
ok( $fsp->debug == 0,                     'debug() get works'             );

