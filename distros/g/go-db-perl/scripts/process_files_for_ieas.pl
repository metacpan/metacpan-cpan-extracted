#!/usr/local/bin/perl

use strict;


my $IEAsDir = shift;

my $noIEAsDir = $IEAsDir;

opendir(DH, $IEAsDir) || die "Cannot open $IEAsDir";

while(my $file= readdir DH) {
    ### skip all directories
    next if (-d "$IEAsDir$file");

    my $newFile;
    ### if a gzipped file, use gzcat to read it
    if ($file =~ m/(.+)\.gz/) {
	$newFile = $1;

	open (OUT, ">$noIEAsDir$newFile") || die "Cannot open $noIEAsDir$newFile for writing:$!\n";
	open (IN, "/usr/bin/gzcat $IEAsDir$file |") ||  die "Cannot open $IEAsDir$file:$!\n";
        while (defined(my $line = <IN>)) {
	    next if ($line =~ m/IEA/);
	    print OUT "$line";
	}
    }
    else {
        $newFile = $file . 'tmp';
	open (OUT, ">$noIEAsDir$newFile") || die "Cannot open $noIEAsDir$newFile:$!\n";
	open (IN, "$IEAsDir$file") ||  die "Cannot open $IEAsDir$file:$!\n";
        while (defined(my $line = <IN>)) {
	    next if ($line =~ m/IEA/);
	    print OUT "$line";
	}
    }
    close(IN);
    close(OUT);

    if ($file =~ m/(.+)\.gz/) {
	if (-e "$noIEAsDir$newFile.gz") {
	    unlink("$noIEAsDir$newFile.gz");
	}
	system("gzip <$noIEAsDir$newFile > $noIEAsDir$newFile.gz");
	unlink("$noIEAsDir$newFile");
    }
    else {
	system("/usr/bin/mv $noIEAsDir$newFile $noIEAsDir$file");
    }
}

exit;
