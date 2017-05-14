use Test::More tests => 3;

BEGIN { use_ok( 'Win32::Filenames' ); }

BEGIN { use_ok( 'Win32::Filenames',qw(sanitize validate $ERR_CHAR ) ); }

require_ok( 'Win32::Filenames' );


