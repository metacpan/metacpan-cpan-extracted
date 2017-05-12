use Test::More 'tests' => 2;

BEGIN {

    #   Test 1 - Ensure that the Tie::MLDBM::Lock::Null module can be loaded

    require_ok( 'Tie::MLDBM::Lock::Null' );
}


#   Test 2 - Ensure that the loaded Tie::MLDBM::Lock::Null module has the
#   appropriate methods for a Tie::MLDBM::Lock::* module.

can_ok( 
    'Tie::MLDBM::Lock::Null',
        'lock_exclusive',
        'lock_shared',
        'unlock'
);


exit 0;
