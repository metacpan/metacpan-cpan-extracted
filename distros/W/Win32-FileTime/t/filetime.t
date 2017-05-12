use File::Temp;
use IO::File;
use Test::More 'tests' => 8;


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
#   Return a successful test result if this test file can be created and record 
#   the date and time at which this file was created - This will be used to 
#   roughly approximate the value returned by the Win32::FileTime->Create 
#   function.

my @date = localtime( time );
my ( $fh, $filename ) = File::Temp->tempfile( 'Win32-FileTime-XXXX' );
ok( defined $filename );
close $fh;


@date = (
    $date[1],
    $date[2],
    $date[3],
    $date[4] + 1,
    $date[5] + 1900
);


my ( @create, @access, @modify );
my $obj = Win32::FileTime->new( $filename );
ok(
    @create = $obj->Create(
        'minute',
        'hour',
        'day',
        'month',
        'year'
    )
);
ok ( eq_array( \@date, \@create ) );

ok( 
    @access = $obj->Access(
        'minute',
        'hour',
        'day',
        'month',
        'year'
    )
);
ok ( eq_array( \@date, \@access ) );

ok( 
    @modify = $obj->Modify(
        'minute',
        'hour',
        'day',
        'month',
        'year'
    )
);
ok ( eq_array( \@date, \@modify ) );


exit 0;


END {

    #   Remove the test file if this exists and is writable under the effective 
    #   user uid/gid

    unlink $filename if defined $filename and -e $filename and -w $filename;
}
