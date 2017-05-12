use Test::More 'tests' => 2;

BEGIN {

    #   Test 1 - Ensure that the Tie::MLDBM::Lock::File module can be loaded

    require_ok( 'Tie::MLDBM::Lock::File' );
}


#   Test 2 - Ensure that the loaded Tie::MLDBM::Lock::File module has the
#   appropriate methods for a Tie::MLDBM::Lock::* module.

can_ok( 
    'Tie::MLDBM::Lock::File',
        'lock_exclusive',
        'lock_shared',
        'unlock'
);


exit 0;
