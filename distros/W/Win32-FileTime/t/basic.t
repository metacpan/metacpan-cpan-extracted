use File::Temp;
use Test::More 'tests' => 6;


BEGIN { 

    #   Test 1 - Ensure that the Win32::FileTime module can be loaded - This is 
    #   performed within a BEGIN block so that functions are exported at 
    #   compile-time and prototypes are properly honoured.

    use_ok( 'Win32::FileTime' ); 
}


#   Test 2 - The variable $filename holds the name of a test file which will be 
#   created as part of the testing process - This test file is created by the 
#   tempfile function of the File::Temp module.
#
#   Return a successful test result if this test file can be created.

my ( $fh, $filename ) = File::Temp->tempfile( 'Win32-FileTime-XXXX' );
ok( defined $filename );
close $fh;


#   Test 3 - Create a new Win32::FileTime object and ensure that the returned 
#   object type is Win32::FileTime

my $obj = Win32::FileTime->new( $filename );
isa_ok( $obj, 'Win32::FileTime' );


#   Test 4,5,6 - Verify the publically accessible methods of the created 
#   Win32::FileTime object

ok( UNIVERSAL::can( $obj, 'Access' ) );
ok( UNIVERSAL::can( $obj, 'Create' ) );
ok( UNIVERSAL::can( $obj, 'Modify' ) );


exit 0;


END {

    #   Remove the test file if this exists and is writable under the effective 
    #   user uid/gid

    unlink $filename if defined $filename and -e $filename and -w $filename;
}