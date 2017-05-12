use Test::More tests => 3;
use Win32::OLE::Variant;

BEGIN { use_ok('Win32::SqlServer::DTS::DateTime') }

my $date_variant = Variant( VT_DATE, "April 1 99" );
my $date;
ok($date = Win32::SqlServer::DTS::DateTime->new($date_variant),'can create an instance with VT_DATE variant') or diag(explain($date_variant));
isa_ok( $date, 'DateTime' );
