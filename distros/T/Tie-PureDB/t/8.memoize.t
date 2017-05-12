
use strict;
use Test::Simple;

BEGIN {
    eval { require Memoize; 1 };
    Test::Simple->import( skip_all => "Memoize is not installed, can't test" ) if $@;
}

#use Test::Simple 'no_plan';
use Test::Simple tests => 34;
use Tie::PureDB;

my $final = 'fina.db';

my @rand = ( rand, rand, $final);
my $t = Tie::PureDB::Write->new(@rand);

ok(
    $t,
    "creating object(and intermediary files)"
);

for(1..10){
    ok( $t->add("k$_" => "v$_" ) );
}
undef $t;

ok(
    ! -e $rand[0]
 && ! -e $rand[1] ,
    "intermediate files have been deleted"
);




    use Tie::PureDB;
    BEGIN{
        package Tie::PureDB::Read;
        use Memoize();
        Memoize::memoize('puredb_read','puredb_find','FETCH');
        no strict 'refs';
        *read = *puredb_read;
        *find = *puredb_find;
        package main;
    }
    ## ... rest of your code follows


$t = Tie::PureDB::Read->new($final);

# put'em in memoize cache
for(1..10){
    ok( $t->FETCH("k$_") eq "v$_" , qq[FETCH-ing k$_ (memoization in progress)] );
}

# pull'em from memoize cache
for(1..10){
    ok( $t->FETCH("k$_") eq "v$_" , qq[FETCH-ing k$_ (now memoized)] );
}

undef $t;

ok( not defined $t );

ok( unlink( $rand[2] ), "deleting final file");

