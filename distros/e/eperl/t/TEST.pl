##
##  TEST.pl -- Test Suite utility functions
##  Copyright (c) 1997 Ralf S. Engelschall, All Rights Reserved. 
##

package TEST;

@TMPFILES = ();
$TMPFILECNT = 0;

sub init {
	return;
}

sub tmpfile {
    local (*FP, $file);

    $file = "tmp." . sprintf("%02d", $TMPFILECNT++);
    push(@TMPFILES, $file);

    if (@_ != -1) {
        open(FP, ">$file");
        print FP @_;
        close(FP);
	}

    return $file;
}

sub tmpfile_with_name {
	local ($name) = shift @_;
    local (*FP, $file);

    $file = $name;
    push(@TMPFILES, $file);

    if (@_ != -1) {
        open(FP, ">$file");
        print FP @_;
        close(FP);
	}

    return $file;
}

sub system {
	local ($cmd) = @_;
	local ($rc);

	$rc = system($cmd);
	return $rc;
}

sub cleanup {
    foreach $file (@TMPFILES) {
        unlink($file);
    }
}

1;
##EOF##
