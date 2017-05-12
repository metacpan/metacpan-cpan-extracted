use strict ;

use Test::More tests => 7 ;
BEGIN { use_ok('autodynaload') } 

use autodynaload ;
use MIME::Base64 ;
BEGIN {ok(1) ;}

ok(autodynaload->is_loaded('Base64')) ;
ok(! autodynaload->is_loaded('some_module_not_loaded')) ;

my $so = autodynaload->is_installed('Base64') ;
ok($so) ;
ok(! autodynaload->is_installed('some_module_not_installed')) ;

isa_ok(autodynaload->is_installed('Base64', open => 1), 'IO::Handle') ;

# is(scalar(autodynaload->get_unresolved_deps($so)), 0) ;


