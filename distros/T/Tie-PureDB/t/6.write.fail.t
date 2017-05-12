
use strict;
use Test::Simple tests => 40;
use Tie::PureDB;
require Errno;
my $final = 'fina.db';
for(1..5){
    my @rand = ( rand, rand, $final);
    ok(
        Tie::PureDB::Write->new(@rand),
        "creating object(and intermediary files)"
    );

    ok(
        ! -e $rand[0]
     && ! -e $rand[1] ,
        "intermediate files have been deleted"
    );

    ok(
        unlink( $rand[2] ),
        "deleting final file"
    );
}


for(1..5){
    my %db;
    my @rand = ( rand, rand, $final );
    tie %db, 'Tie::PureDB::Write', @rand;
    ok( tied %db, "\%db is tied");
    ok( untie %db, "\%db is untied");
    ok(
        unlink($rand[2]),
        "deleting final file"
    );
}

## you can't really test for failure, now can you ;(
## 30-40
#ok( ! Tie::PureDB::Write->new(('') x 3) ) for 1..10;
for(1..5){
    eval {
        Tie::PureDB::Write->new(1,'',2);
    };
    ok( $@ );
}
for(1..5){
    eval {
        tie my%db, 'Tie::PureDB::Write', 1,'',2;
    };
    ok( $@ );
}
