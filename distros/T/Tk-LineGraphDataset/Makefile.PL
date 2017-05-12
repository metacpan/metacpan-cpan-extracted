use ExtUtils::MakeMaker;

my $pm = 'LineGraphDataset';
WriteMakefile(NAME           => "Tk::$pm",
	      DISTNAME       => "Tk-$pm",
	      VERSION_FROM   => "$pm.pm",
	      dist           => {COMPRESS => 'gzip', SUFFIX => 'gz'},
	      ($] >= 5.005 ?
	       (ABSTRACT => 'LinePlot Dataset',
		AUTHOR => 'Tom Clifford (Still_Aimless@yahoo.com)') : (),
	       ),
	      );
print "Writing MANIFEST for Tk::$pm\n";
open MANIFEST, ">MANIFEST" or die "Cannot open MANIFEST: $!";
print MANIFEST <<"end-of-manifest";
MANIFEST
Makefile.PL
$pm.pm
README
end-of-manifest
print MANIFEST "$widtrib\n" if $widtrib;
close MANIFEST or die $!;

 
