use strict;
use warnings;

use Yote;

use Data::Dumper;
use File::Temp qw/ :mktemp tempdir /;
use Test::More;
use Carp;
$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

BEGIN {
    use_ok( "Yote" ) || BAIL_OUT( "Unable to load 'Yote'" );
}

# -----------------------------------------------------
#               init
# -----------------------------------------------------

my $dir = tempdir( CLEANUP => 1 );
#test_suite();
my $store = Yote::open_store( $dir );
my $root_node = $store->fetch_root;

test_arry();
test_hash();
test_suite();
test_upgrade_db();
done_testing;

exit( 0 );

sub test_suite {
    $root_node->add_to_myList( { objy =>
        $store->newobj( {
            someval => 124.42,
            somename => 'Käse',
            someobj => $store->newobj( {
                binnerval => "`SPANXZ",
                linnerval => "SP`A`NXZ",
                zinnerval => "PANXZ`",
                innerval => "This is an \\ inner `val\\`\n with Käse \\\ essen ",
                                      } ),
                        } ),
                               } );

    is( $root_node->get_myList->[0]{objy}->get_somename, 'Käse', "utf 8 character defore stow" );

    $store->stow_all;

    is( $root_node->get_myList->[0]{objy}->get_somename, 'Käse', "utf 8 character after stow before load" );

    # objects created : root, myList, array block in mylist, a hash in myslist + its 1 inner list, a newobj
    #                   in the hash, a newobj in the obj
    # so 6 things

    my $dup_store = Yote::open_store( $dir );

    my $dup_root = $dup_store->fetch_root;

    is( $dup_root->[Yote::Obj::ID], $root_node->[Yote::Obj::ID] );
    is_deeply( $dup_root->[Yote::Obj::DATA], $root_node->[Yote::Obj::DATA] );

    is( $dup_root->get_myList->[0]{objy}->get_somename, 'Käse', "utf 8 character saved in yote object" );

    is( $dup_root->get_myList->[0]{objy}->get_someval, '124.42', "number saved in yote object" );

    is( $dup_root->get_myList->[0]{objy}->get_someobj->get_innerval,
        "This is an \\ inner `val\\`\n with Käse \\\ essen " );
    is( $dup_root->get_myList->[0]{objy}->get_someobj->get_binnerval, "`SPANXZ" );
    is( $dup_root->get_myList->[0]{objy}->get_someobj->get_linnerval, "SP`A`NXZ" );
    is( $dup_root->get_myList->[0]{objy}->get_someobj->get_zinnerval, "PANXZ`" );

    # filesize of $dir/1_OBJSTORE should be 360

    # purge test. This should eliminate the following :
    # the old myList, the hash first element of myList, the objy in the hash, the someobj of objy, so 4 items

    my $list_to_remove = $root_node->get_myList();

    $list_to_remove->[9] = "NINE";

    $store->stow_all;

    undef $list_to_remove;
    $list_to_remove = $root_node->get_myList();

    my $hash_in_list = $list_to_remove->[0];

    my $list_to_remove_id = $store->_get_id( $list_to_remove );
    my $hash_in_list_id   = $store->_get_id( $hash_in_list );

    my @bucket_in_hash_in_list;
    my $bucket_in_hash_in_list_id   = $store->_get_id( $hash_in_list );

    my $objy              = $hash_in_list->{objy};
    my $objy_id           = $store->_get_id( $objy );
    my $someobj_id        = $store->_get_id( $objy->get_someobj );
    undef $objy;


    $root_node->set_myList( [] );

    $store->stow_all;

    my $quickly_removed_obj = $store->newobj( { soon => 'gone', bigstuff => ('x'x10000) } );
    my $quickly_removed_id = $quickly_removed_obj->[Yote::Obj::ID];
    push @$list_to_remove, "SDLFKJSDFLKJSDFKJSDHFKJSDHFKJSHDFKJSHDF" x 3, $quickly_removed_obj;
    $list_to_remove->[87] = "EIGHTYSEVEN";

    $store->stow_all;
    
    $store->run_recycler;
    
    ok( $store->_fetch( $list_to_remove_id ), "removed list not yet removed" );    
    ok( $store->_fetch( $hash_in_list_id ), "removed hash id not yet removed" );
    
    ok( $store->_fetch( $objy_id ), "removed objy still removed" );
    ok( $store->_fetch( $someobj_id ), "removed someobj still removed" );

    undef $hash_in_list;
    undef $list_to_remove;
    undef $quickly_removed_obj;
    
    $store->run_recycler;
    
    ok( ! $store->_fetch( $list_to_remove_id ), "removed list still removed" );
    ok( ! $store->_fetch( $hash_in_list_id ), "removed hash id still removed" );
    ok( ! $store->_fetch( $objy_id ), "removed objy still removed" );
    ok( ! $store->_fetch( $someobj_id ), "removed someobj still removed" );

    undef $dup_root;

    undef $root_node;

    $Yote::Hash::SIZE = 7;

    my $thash = $store->fetch_root->set_test_hash({});
    # test for hashes large enough that subhashes are inside

    my( %confirm_hash );
    my( @alpha ) = ("A".."G");
    my $val = 1;
    for my $letter (@alpha) {
        $thash->{$letter} = $val;
        $confirm_hash{$letter} = $val;
        $val++;
    }

    $val = 1;
    for my $letter (@alpha) {
        is( $thash->{$letter}, $val++, "Hash value works" );
    }
    $thash->{A} = 100;
    is( $thash->{A}, 100, "overriding hash value works" );
    delete $thash->{A};
    delete $confirm_hash{A};
    ok( ! exists($thash->{A}), "deleting hash value works" );
    $thash->{G} = "GG";
    $confirm_hash{G} = "GG";

    is_deeply( [sort keys %$thash], ["B".."G"], "hash keys works for the simpler hashes" );

    # now stuff enough there so that the hashes must overflow
    ( @alpha ) = ("AA".."ZZ");
    for my $letter (@alpha) {
        $thash->{$letter} = $val;
        $confirm_hash{$letter} = $val;
        $val++;
    }
    $store->stow_all;
    undef $store;
    
    my $sup_store = Yote::open_store( $dir );
    $thash = $sup_store->fetch_root->get_test_hash;

    is_deeply( [sort keys %$thash], [sort ("B".."G","AA".."ZZ")], "hash keys works for the heftier hashes" );

    is_deeply( $thash, \%confirm_hash, "hash checks out keys and values" );

    # array tests
    # listy test because
    $Yote::Array::MAX_BLOCKS  = 4;

    $store = $sup_store;
    $root_node = $store->fetch_root;
    my $l = $root_node->get_listy( [] );

    push @$l, "ONE", "TWO";
    is_deeply( $l, ["ONE", "TWO"], "first push" );
    is( @$l, 2, "Size two" );
    is( $#$l, 1, "last index 1" );

    push @$l, "THREE", "FOUR", "FIVE";
    is_deeply( $l, ["ONE", "TWO", "THREE", "FOUR", "FIVE"], "push 1" );
    is( @$l, 5, "Size five" );
    is( $#$l, 4, "last index 1" );

    push @$l, "SIX", "SEVEN", "EIGHT", "NINE";

    is_deeply( $l, ["ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE"], "push 2" );
    is( @$l, 9, "Size nine" );

    push @$l, "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN";
    is_deeply( $l, ["ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN"], "push 3" );
    is( @$l, 16, "Size sixteen" );

    push @$l, "SEVENTEEN", "EIGHTTEEN";
    is_deeply( $l, ["ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTTEEN"], "push 4" );
    is( @$l, 18, "Size eighteen" );
    is_deeply( ["SIXTEEN","SEVENTEEN","EIGHTTEEN",undef],[@$l[15..18]], "nice is slice" );

    push @$l, "NINETEEN";
    is_deeply( $l, ["ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTTEEN", "NINETEEN"], "push 5" );
    is( @$l, 19, "Size nineteen" );
    is_deeply( ["SIXTEEN","SEVENTEEN","EIGHTTEEN","NINETEEN"],[@$l[15..18]], "nice is slice" );

    push @$l, "TWENTY","TWENTYONE";
    is_deeply( $l, ["ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTTEEN", "NINETEEN", "TWENTY","TWENTYONE"], "push 6" );
    is( @$l, 21, "Size twentyone" );
    my $v = shift @$l;
    is( $v, "ONE" );
    is_deeply( $l, ["TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTTEEN", "NINETEEN", "TWENTY","TWENTYONE"], "first shift" );
    is( @$l, 20, "Size twenty" );
    push @$l, $v;
    is_deeply( $l, ["TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTTEEN", "NINETEEN", "TWENTY","TWENTYONE", "ONE"], "push 7" );
    is( @$l, 21, "Size twentyone again" );
    unshift @$l, 'ZERO';

    is_deeply( $l, ["ZERO", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTTEEN", "NINETEEN", "TWENTY","TWENTYONE", "ONE"], "first unshift" );
    is( @$l, 22, "Size twentytwo again" );

    # test push, unshift, fetch, fetchsize, store, storesize, delete, exists, clear, pop, shift, splice

    my $pop = pop @$l;
    is( $pop, "ONE", "FIRST POP" );
    is( @$l, 21, "Size after pop" );

    is( $l->[2], "THREE", "fetch early" );
    is( $l->[10], "ELEVEN", "fetch middle" );
    is( $l->[20], "TWENTYONE", "fetch end" );



    my @spliced = splice @$l, 3, 5, "NEENER", "BOINK", "NEENER";

    is_deeply( \@spliced, ["FOUR","FIVE","SIX","SEVEN","EIGHT"], "splice return val" );
    is_deeply( $l, ["ZERO", "TWO", "THREE", "NEENER", "BOINK", "NEENER",
                    "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTTEEN", "NINETEEN", "TWENTY","TWENTYONE"], "first splice" );

    $l->[1] = "TWONE";
    is( $l->[1], "TWONE", "STORE" );

    delete $l->[1];

    is_deeply( $l, ["ZERO", undef, "THREE", "NEENER", "BOINK", "NEENER",
                    "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTTEEN", "NINETEEN", "TWENTY","TWENTYONE"], "first delete" );
    ok( exists( $l->[0] ), "exists" );
    ok( !exists( $l->[1] ), "undefined" );
    ok( !exists( $l->[$#$l+1] ), "doesnt exist beyond" );
    ok( exists( $l->[$#$l] ), "exists at end" );

    my $last = pop @$l;
    is( $last, "TWENTYONE", 'POP' );
    is_deeply( $l, ["ZERO", undef, "THREE", "NEENER", "BOINK", "NEENER",
                    "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTTEEN", "NINETEEN", "TWENTY"], "more pop" );
    is( scalar(@$l), 18, "pop size" );
    is( $#$l, 17, "pop end" );

    @{$l} = ();
    is( $#$l, -1, "last after clear" );
    is( scalar(@$l), 0, "size after clear" );

    $Yote::Array::MAX_BLOCKS  = 82;
    
    push @$l, 0..10000;
    $store->stow_all;
    my $other_store = Yote::open_store( $dir );
    $root_node = $store->fetch_root;
    my $ol = $root_node->get_listy( [] );

    is_deeply( $l, $ol, "lists compare" );

} #test suite

sub _cmpa {
    my( $title, @pairs ) = @_;
    while( @pairs ) {
        my $actual = shift @pairs;
        my $expected = shift @pairs;
        if( ref( $expected ) ) {
            is_deeply( $actual, $expected, $title );
            is( scalar( @$actual ), scalar( @$expected ), "$title size" );
            is( $#$actual, $#$expected, "$title index" );
        } else {
            is( $actual, $expected, $title );
        }
    }
}

sub _cmph {
    my( $title, @pairs ) = @_;
    while( @pairs ) {
        my $actual = shift @pairs;
        my $expected = shift @pairs;
        if( ref( $expected ) ) {
            is_deeply( $actual, $expected, $title );
            is_deeply( [sort keys( %$actual )], [sort  keys( %$expected ) ], "$title keys" );
            is( scalar( values( %$actual )), scalar(  values( %$expected ) ), "$title value counts" );
        } else {
            is( $actual, $expected, $title );
        }
    }
}


sub test_hash {
    for my $SZ (2..30) {
        $Yote::Hash::SIZE = $SZ;
        my $hash = $root_node->set_hash({});
        my $match = {};
        $hash->{FOO} = "BAR";
        $match->{FOO} = "BAR";

        _cmph( "FIRSTFROO", $hash, $match );
        $hash->{FOO} = "BAF";
        $match->{FOO} = "BAF";
        _cmph( "SecondFOO", $hash, $match );

        my( @keys ) = ("A".."Z");
        my( @vals ) = (1..26);
        while( @keys ) {
            my $k = shift @keys;
            my $v = shift @vals;
            $hash->{$k} = $v;
            $match->{$k} = $v;
        }
        _cmph( "alphawet buckets $SZ", $hash, $match );

    } #each size
}

sub test_arry {
#    for my $SZ (2..9) {
    for my $SZ (7..7) {
        $Yote::Array::MAX_BLOCKS  = $SZ;

        my $arry = $root_node->set_arry( [] );
        my $match = [];

        _cmpa( "empty start $SZ", $arry, $match );

        _cmpa( "fifth el $SZ", $arry->[4], $match->[4] );

        $arry->[8] = "EI";
        $match->[8] = "EI";
        _cmpa( "oneel $SZ", $arry, $match );

        _cmpa( "exists nothing $SZ", exists $arry->[9], exists $match->[9] );
        _cmpa( "exists yada $SZ", exists $arry->[8], exists $match->[8] );
        _cmpa( "exists bevore $SZ", exists $arry->[4], exists $match->[4] );

        $arry->[81] = "EI2";
        $match->[81] = "EI2";
        _cmpa( "oneel $SZ", $arry, $match );

        $store->stow_all;

        my $other_store = Yote::open_store( $dir );
        my $aloaded = $other_store->fetch_root->get_arry;

        _cmpa( "SAVED LOADED", $aloaded, $match );

        my $a = $arry->[82];
        my $m = $match->[82];

        _cmpa( "delnow1 $SZ", $arry, $match, $a, $m );

        $a = delete $arry->[81];
        $m = delete $match->[81];
        _cmpa( "delnow2 $SZ", $arry, $match, $a, $m );

        $a = delete $arry->[81];
        $m = delete $match->[81];
        _cmpa( "delnowagain $SZ", $arry, $match, $a, $m );

        $a = pop @$arry;
        $m = pop @$match;
        _cmpa( "pops $SZ", $arry, $match, $a, $m );

        @{$arry} = ();
        @{$match} = ();
        _cmpa( "clear $SZ", $arry, $match );

        $#$arry = 17;
        $#$match = 17;
        _cmpa( "setsize $SZ", $arry, $match );

        unshift @$arry, "HERE ARE SOME THINGS", "AND AGAIN";
        unshift @$match, "HERE ARE SOME THINGS", "AND AGAIN";
        _cmpa( "unshift $SZ", $arry, $match );

        $a = shift @$arry;
        $m = shift @$match;
        _cmpa( "shift $SZ", $arry, $match, $a, $m );

        unshift @$arry, 'A'..'L';
        unshift @$match, 'A'..'L';

        _cmpa( "unshift more $SZ", $arry, $match, $a, $m );

        $arry = $root_node->set_arry_more( [ 1 .. 19 ] );
        $match = [ 1 .. 19 ];
        is_deeply( $arry, $match, "INITIAL $SZ" );
        is( @$arry, 19, "19 items" );
        is( $#$arry, 18, "last idx is 18" );
        $a = shift @$arry;
        $m = shift @$match;
        is( $a, $m, "SHIFT $SZ" );
        is_deeply( $arry, $match, "AFTER SHIFT $SZ" );
        is( @$arry, 18, "18 items" );
        is( $#$arry, 17, "last idx is 17" );
        $a = pop @$arry;
        $m = pop @$match;
        is( $a, $m, "POP $SZ" );
        is_deeply( $arry, $match, "AFTER POP $SZ" );
        is( @$arry, 17, "17 items" );
        is( $#$arry, 16, "last idx is 16" );

        my( @a ) = splice @$arry, 3, 4, ("A".."N");
        my( @m ) = splice @$match, 3, 4, ("A".."N");

        is_deeply( $arry, $match, "AFTER SPLICE $SZ" );
        is_deeply( \@a, \@m, "SPLICE return $SZ" );

        my $a2 = $root_node->set_arry2([]);
        my $m2 = [];

        $a2->[55] = "Z";
        $m2->[55] = "Z";
        is( $#$a2, $#$m2, "Same last index $SZ" );
        is( @$a2, @$m2, "Same size $SZ" );
        is_deeply( $a2, $m2, "Same stuff $SZ" );

        my( @sa ) = splice @$a2, 3, 44;
        my( @sm ) = splice @$m2, 3, 44;
        is( $#$a2, $#$m2, "empty splice last idx $SZ" );
        is( @$a2, @$m2, "empty splice size $SZ" );
        is_deeply( $a2, $m2, "empty splice stuff $SZ" );


        print STDERR Data::Dumper->Dump(["NOW DO EDGE CASE for when each is called but not finished and the thing has a live WEAK ref but no trace to the root and make sure it gets removed when that WEAK ref died"]);
        
    } #each bucketsize
} #test_arry

sub test_upgrade_db {
    "get an old db and make sure it updates properly. go back versions
and create databases for those versions";

    
    
} #test_upgrade_db

__END__

perl -e '@l = (1,2,3); $l[1] = "A"; print join(",",@l)."\n"'
1,A,3
wolf@talisman:~/proj/Yote/YoteBase$ perl -e '@l = (1,2,3); $l[1] = "A"; print scalar(@l)."\n"'
3
wolf@talisman:~/proj/Yote/YoteBase$ perl -e '@l = (1,2,3); $l[10] = "A"; print scalar(@l)."\n"'
3
wolf@talisman:~/proj/Yote/YoteBase$ perl -e '@l = (1,2,3); $l[10] = "A"; print scalar(@l)."\n"'
11
wolf@talisman:~/proj/Yote/YoteBase$ perl -e '@l = (1,2,3); $l[10] = undef; print scalar(@l)."\n"'perl -e '@l = (1,2,3); $l[10] = undef; print scalar(@l)."\n"'
11
wolf@talisman:~/proj/Yote/YoteBase$ perl -e '@l = (1,2,3); $l[10] = undef; delete $l[10]; print scalar(@l)."\n"'
3
wolf@talisman:~/proj/Yote/YoteBase$ perl -e '@l = (1,2,3); $l[10] = undef; $l[9] = undef; delete $l[10]; print scalar(@l)."\n"'
10
wolf@talisman:~/proj/Yote/YoteBase$ perl -e '@l = (1,2,3); $l[10] = undef; $l[9] = undef; delete $l[10]; print scalar(@l)."\n"'
