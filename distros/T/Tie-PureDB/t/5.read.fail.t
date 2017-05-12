
use strict;

use Test::Simple tests => 15;
use Tie::PureDB;
require Errno;

for(1..5){
    my $p = Tie::PureDB::Read->new('bo.'.$_.rand().[].'.no.EXIST')
        or
            ok( $! =~ /No such file/
                && &Errno::ENOENT == $!, "api: can't read non-existent file" );
}


for(1..5){
    my %db;
    my $p = tie %db, 'Tie::PureDB::Read', 'bo.'.$_.rand().[].'.no.EXIST'
        or
            ok( $! =~ /No such file/
                && &Errno::ENOENT == $!, "tie: can't read non-existent file" );
    ok( ! tied(%db), "\%db is not tied");
}
