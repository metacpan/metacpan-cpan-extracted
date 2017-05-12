use strict;

use lib qw(./lib ./t/lib);

my $err;
use UtilExporter
  -hello => [hello_name  => {-as => 'hello_rename'},
             hey => {-as => 'hey_japan', in => 'japan'},
             hey => {-as => 'hey_osaka', in => 'japan', at => 'osaka'}],
 'askme';


use strict;
use Test::More qw/no_plan/;

ok(defined &hello_rename, 'defined hello_rename');
ok(defined &hey_japan,  'defined hello_japan');
ok(defined &askme,  'defined askme');

is(hello_rename()    , 'hello, ', 'hello_rename');
is(hey_japan()       , 'hey, japan', 'hey_japan');
is(hey_japan("Osaka"), 'hey, Osaka in japan', 'hey_japan("Osaka")');
is(hey_osaka()       , 'hey, osaka in japan', 'hey_osaka');
is(hey_osaka("Osaka"), 'hey, Osaka in japan', 'hey_osaka("Osaka")');
