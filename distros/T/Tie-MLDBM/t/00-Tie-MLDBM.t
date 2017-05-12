use File::Temp;
use Test::More 'tests' => 2;

BEGIN {

    #   Test 1 - Ensure that the Tie::MLDBM module can be loaded

    use_ok( 'Tie::MLDBM' );
}

#   Test 2 - Ensure that the loaded Tie::MLDBM module has the appropriate 
#   methods for a tied-hash class - See perltie man page for details.
#
#   The EXISTS, FIRSTKEY and NEXTKEY methods are ignored as these are 
#   handled by AUTOLOAD subroutines and as such are not handled perfectly by
#   Test::More (or indeed UNIVERSAL::can) - See chromatic's Perl Testing 
#   Tutorial at http://wgz.org/chromatic/perl/IntroTestMore.pdf


#can_ok(
#    'Tie::MLDBM',
#        'TIEHASH',
#        'FETCH',
#        'STORE',
#        'DELETE',
#        'CLEAR',
#        'UNTIE',
#);


#   Generate a temporary filename for testing purposes

my ( $fh, $filename ) = File::Temp->tempfile( 'Tie-MLDBM-XXXX' );
$filename ||= 'Tie-MLDBM-Testfile';


#   Test 3 - Create a new object and confirm its inheritance as a Tie::MLDBM 
#   object

my $object = tie my %hash, 'Tie::MLDBM', {
    'Lock'          =>  'Null',
    'Serialise'     =>  'Storable',
    'Store'         =>  'DB_File'
}, $filename;

isa_ok( $object, 'Tie::MLDBM' );


exit 0;


END {
    unlink $filename if defined $filename and -e $filename and -w $filename;
}
