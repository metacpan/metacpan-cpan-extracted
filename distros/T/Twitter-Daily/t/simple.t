
## ARGV[0] : FTP server
## ARGV[1] : base folder
## ARGV[2] : user
## ARGV[3] : password
use strict;
use warnings;

use Test::More tests => 17;

my $fname;

sub makeStory() {
	use File::MkTemp;
	
	$fname = mktemp( 'simpleTXXXXXX', '.');
	ok( $fname ne '', "Filename not empty : '$fname'");
	my $fh;
	ok( open ($fh, "> $fname"), "Creating temp file");
	print $fh "Simple test\n".'Really <b>SIMPLE</b> one'. "\n";
	close($fh);
}
require_ok( 'Blosxom::Publish' );

my $blosxom = Blosxom::Publish->new();
ok( ! defined($blosxom), "No server parameter");

SKIP: {
    
    skip "FTP server, base folder, user or password not passed as parameter", 15
       if $#ARGV < 4;
        
    $blosxom = Blosxom::Publish->new( server => $ARGV[0], base=> $ARGV[1] );
	ok( defined($blosxom), "Now has server parameter");
        
    diag("Login on...");
    ok( ! $blosxom->login(), "Login with neither user nor password is forbidden");
    ok( $blosxom->errNumber() == 1, "Error number test" );
    ok( ! $blosxom->login( user => 'xxxxx'), "Login with no password is forbidden");
    ok( $blosxom->errNumber() == 1, "Error number test"  );
    ok( ! $blosxom->login( password => 'yyyyy'), "Login with no user is forbidden");
    ok( $blosxom->errNumber() == 1, "Error number test"  );
    
    ok( $blosxom->login( user => $ARGV[2], password => $ARGV[3]), "User and pass supplied" );
    is( $blosxom->errNumber(), 0, "The error message should be blank but is '" . $blosxom->errMsg() . "'" );
    
    diag ("Publishing...");
    makeStory();
    diag("Filename : $fname");
    ok( $blosxom->publish('test.txt', '/test', $fname), "Publishing" );
    is( $blosxom->errNumber(), 0, "The error message should be blank but is '" . $blosxom->errMsg() . "'" );
    
    diag("Quitting...");
    $blosxom->quit();
    is( $blosxom->errNumber(), 0, "The error message should be blank but is '" . $blosxom->errMsg() . "'" );
    
    diag("Cleanup...");
    ok( unlink($fname) == 1, "Deleting story file" )
}


