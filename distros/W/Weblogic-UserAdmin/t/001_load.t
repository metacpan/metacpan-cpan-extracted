# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Weblogic::UserAdmin' ); }

my $object = Weblogic::UserAdmin->new ({username=>'test',password=>'test'});
isa_ok ($object, 'Weblogic::UserAdmin');


