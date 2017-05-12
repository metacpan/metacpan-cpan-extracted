use Test::Simple 'no_plan';
use strict;


ok( system('perl -c bin/wordpress-upload-post') ==0 );
ok( system('perl -c bin/wordpress-upload-media') ==0 );
ok( system('perl -c bin/wordpress-info') ==0 );

ok(1);

