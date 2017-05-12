use Test::More 'tests' => 2;

BEGIN {

    #   Test 1 - Ensure that the Tie::MLDBM::Serialise::Storable module can be loaded

    require_ok( 'Tie::MLDBM::Serialise::Storable' );
}


#   Test 2 - Ensure that the loaded Tie::MLDBM::Serialise::Storable module has 
#   the appropriate methods for a Tie::MLDBM::Serialise::* module.

can_ok( 
    'Tie::MLDBM::Serialise::Storable',
        'deserialise',
        'serialise'
);


exit 0;
