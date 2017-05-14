package DUMPVAR;
sub dumpvar {
    ($packageName) = @_;
    $rPackage = \%{"${packageName}::"};  # Get a reference to the appropriate symbol table hash.
    $, = " "	;
    while (($varName, $globValue) = each %$rPackage) {
	print "$varName ============================= \n";
	*var = $globValue;
	if (defined ($var)) {
	    print "\t \$$varName $var \n";
	} 
	if (defined (@var)) {
	    print "\t \@$varName @var \n";
	} 
	if (defined (%var)) {
	    print "\t \%$varName ",%var," \n";
	}
    }
}


package Test;
$x = 10;
@y = (1,3,4);
%z = (1,2,3,4, 5, 6);
$z = 300;
DUMPVAR::dumpvar("Test");
