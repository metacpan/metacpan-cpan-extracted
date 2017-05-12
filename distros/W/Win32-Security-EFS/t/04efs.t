use Test::More tests => 7;

use_ok('Win32::Security::EFS');

SKIP: {
    skip "EFS not supported by your file system.", 6
      unless Win32::Security::EFS->supported();

    ok(Win32::Security::EFS::supported);

    my $testfile = 'test_win32_security_efs.tmp';
    open(TMP, "> $testfile");
    print TMP "Test";
    close TMP;

    ok(Win32::Security::EFS->encryption_status($testfile) == &Win32::Security::EFS::FILE_ENCRYPTABLE, 'encryption_status test 1');
    ok(Win32::Security::EFS->encrypt($testfile), 'encrypt test');
    ok(Win32::Security::EFS->encryption_status($testfile) == &Win32::Security::EFS::FILE_IS_ENCRYPTED, 'encryption_status test 2');

    # my $users;
    # Win32::Security::EFS->__QueryUsersOnEncryptedFile( $testfile, \$users );


    ok(Win32::Security::EFS->decrypt($testfile), 'decrypt test');
    ok(Win32::Security::EFS->encryption_status($testfile) == &Win32::Security::EFS::FILE_ENCRYPTABLE, 'encryption_status test 3');

    unlink $testfile;
}