use Test::More tests => 35; 

$ENV{'lib::restrict-quiet'} = 1; 

my $skip = 33;
my $uuid = 99;
my @dirs = qw(
    lib_restrict_nouid       lib_restrict_root        
    lib_restrict_user        lib_restrict_array_ok_x  
    lib_restrict_array_ok_y  lib_restrict_array_bad_x 
    lib_restrict_array_bad_y lib_restrict_code_ref  
);
    
use_ok('lib::restrict', 'foo');

@lib::ORIG_INC = @lib::ORIG_INC; # to avoid warning..
is_deeply(\@lib::ORIG_INC, \@lib::restrict::ORIG_INC, 'name space ORIG_INC');

SKIP: { 
    skip q{lib::restrict's tests need to be run as root}, $skip if $> != 0;
    skip q{Couldn't find valid non-root uid for testing}, $skip if !getpwuid($uuid); 

    # setup
    mkdir $_ for @dirs;
    chown $uuid, $uuid, qw(lib_restrict_array_ok_y lib_restrict_array_bad_y lib_restrict_user);
    no warnings 'uninitialized'; # $INC{1} is uninit @ times below
        
    # start tests
    use_ok('lib::restrict', 'lib_restrict_nouid');
    ok($INC[0] eq 'lib_restrict_nouid', 'no uid given'); 

    use_ok('lib::restrict', qw(lib_restrict_root lib_restrict_user), 0);
    ok($INC[0] eq 'lib_restrict_root', 'one uid root valid');  
    ok($INC[1] ne 'lib_restrict_user', 'one uid root invalid');
 
    use_ok('lib::restrict', qw(lib_restrict_user lib_restrict_root), $uuid);
    ok($INC[0] eq 'lib_restrict_user', 'one uid user valid');  
    ok($INC[1] ne 'lib_restrict_root', 'one uid user invalid'); 
 
    use_ok('lib::restrict', 'lib_restrict_code_ref', sub { return 1 if shift eq 'lib_restrict_code_ref';return; });
    ok($INC[0] eq 'lib_restrict_code_ref', 'code ref'); 

    use_ok('lib::restrict', qw(lib_restrict_array_ok_x lib_restrict_array_ok_y), [0, $uuid]);
    ok($INC[0] eq 'lib_restrict_array_ok_x', 'array ref root and user - root');  
    ok($INC[1] eq 'lib_restrict_array_ok_y', 'array ref root and user - user'); 

    use_ok('lib::restrict', qw(lib_restrict_array_bad_x lib_restrict_array_bad_y), ['abc', 0, 'xyz', $uuid]); 
    ok($INC[0] eq 'lib_restrict_array_bad_x', 'array ref with invalid items - root'); 
    ok($INC[1] eq 'lib_restrict_array_bad_y', 'array ref with invalid items - user'); 
    
    eval q{ no lib::restrict 'lib_restrict_array_bad_x'; };
    ok($INC[0] eq 'lib_restrict_array_bad_y', 'no lib::restrict');
    
    BEGIN { $ENV{'lib::restrict-!-d_ok_in'} = ['lib_restrict_nouid']; }
    use_ok('lib::restrict', 'lib_restrict_nouid/foo');
    ok($INC[0] eq 'lib_restrict_nouid/foo', '!-d parent exists nouid');
    
    use_ok('lib::restrict', 'lib_restrict_nouid/bar', 0);
    ok($INC[0] eq 'lib_restrict_nouid/bar', '!-d parent exists uid');
    
    use_ok('lib::restrict', 'lib_restrict_nouid/baz', sub { return 1; });
    ok($INC[0] eq 'lib_restrict_nouid/baz', '!-d parent exists code ref true');
    
    use_ok('lib::restrict', 'lib_restrict_nouid/wop', sub { return 0; });
    ok($INC[0] eq 'lib_restrict_nouid/wop', '!-d parent exists code ref false');

    use_ok('lib::restrict', 'lib_restrict_no/foo');
    ok($INC[0] eq 'lib_restrict_no/foo', '!-d parent not exists nouid');
    
    use_ok('lib::restrict', 'lib_restrict_no/bar', 0);
    ok($INC[0] ne 'lib_restrict_no/bar', '!-d parent not exists uid');
    
    use_ok('lib::restrict', 'lib_restrict_no/baz', sub { return 1; });
    ok($INC[0] eq 'lib_restrict_no/baz', '!-d parent not exists code ref true');
    
    use_ok('lib::restrict', 'lib_restrict_no/wop', sub { return 0; });
    ok($INC[0] ne 'lib_restrict_no/wop', '!-d parent not exists code ref false');
}

END {
    # cleanup
    @INC = @lib::restrict::ORIG_INC; # just in case they need it :)
    rmdir $_ for @dirs;
}