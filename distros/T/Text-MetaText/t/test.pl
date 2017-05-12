#!/usr/bin/perl -w
#
# test.pl: generic test functions used by test scripts
#

use Date::Format;

my $TESTDIR = 't';
my $SRCDIR  = "$TESTDIR/src";
my $DESTDIR = "$TESTDIR/dest";
my $EXPDIR  = "$TESTDIR/expect";
my $LOGFILE = "$TESTDIR/test.log";
my $ERROR   = "";
my $DEBUG   = 0;


sub init {
    unless (-d $DESTDIR) {
	mkdir $DESTDIR, 0755 || die "$DESTDIR: $!\n";
    }
    &log_init();
}


# a post-processing function hook to allow the calling function to 
# do something after the file has been processed, but before checking.
# The function should return 0 to indicate success or return an error 
# string to indicate failure.  
my $post_hook;

sub set_post_hook {
    my $fn = shift;

    if (defined($fn) && ref($fn) eq 'CODE') {
	$post_hook = $fn;
    }
    else {
    	warn "post_hook is not a CODE reference\n"
    }
}




#
# test_file($ntest, $mt, $file, $defs)
#
# Calls process() to process the file, $file, with the MetaText object, 
# $mt.  If $post_hook is defined, the function that it references is called,
# passing the MetaText object, and the output file, &$post_hook($mt, $file).
# Finally, compare() is called to check the file output (dest/$file) with 
# the expected output (expect/$file).  Prints "ok $ntest" on success or 
# "not ok $ntest" on error;
#

sub test_file {
    my $ntest = shift;
    my $mt    = shift;
    my $file  = shift;
    my $defs  = shift || {};
    my $ok;

    print STDERR "$file...";
    
    if ($ok = process($mt, $file, $defs)) {
	if (defined $post_hook) {
	    $ERROR = &$post_hook($mt, $file);
	    $ok = 0 if $ERROR;   
	}
	$ok = compare($file) if $ok;
    }
    print $ok ? "ok $ntest\n" : "not ok $ntest\n";
   
    &log_entry("$file: %s\n", $ok ? "ok" : "FAILED - $ERROR");

    print STDERR $ok ? "ok $ntest\n" : "not ok $ntest [$ERROR]\n" if $DEBUG;
}



#
# process($mt, $file, $defs)
#
# Process the file "src/$file" using the MetaText object, $mt, adding any
# definitions in the hash array reference, $defs.  The output is written
# to a corresponding file in the "dest" directory.
#
# Returns 1 on success.  0 is returned on error and $ERROR is set to 
# contain an appropriate error message.
#

sub process {
    my $mt   = shift;
    my $file = shift;
    my $vars = shift || {};
    my $output;
    local (*OUTPUT);

    $ERROR = '';

    # process file 
    unless (defined ($output = $mt->process("$SRCDIR/$file", $vars))) {
	$ERROR = "No MetaText output\n";
	return 0;
    }

    # spit out processed text 
    open(OUTPUT, "> $DESTDIR/$file") || do {
	$ERROR = "$DESTDIR/$file: $!";
	return 0;
    };
    print OUTPUT $output;
    close(OUTPUT);

    1;
}



#
# compare($file)
#
# Compares the file ./expected/$file against ./dest/$file, returning 1
# if they are identical or 0 if not.  $ERROR is set with an appropriate
# message if the files are not identical or another error occurs.
#

sub compare {
    my $file     = shift;
    my $expfile  = "$EXPDIR/$file";
    my $destfile = "$DESTDIR/$file";
    my ($exp, $dest);
    my $ignore = 0;
    local (*EXP, *DEST);

    $ERROR = '';

    # attempt to open files
    foreach ([ $expfile, *EXP ], [ $destfile, *DEST ]) {
	open ($_->[1], $_->[0]) || do { 
	    $ERROR = "$_->[0]: $!";
	    return 0;
	}
    }

    while (defined($exp = <EXP>)) {

	# "#pragma ignore" tells the checker to ignore any 
	# subsequent lines up to the next "#pragma"
	$exp =~ /^#pragma\s+ignore/ && do {
	    $ignore = 1;
	    next;
	};

	# and "#pragma check" tells it to start checking again
	$ignore && ($exp =~ /^#pragma\s+check/) && do {
	    $ignore = 0;
	    next;
	};

	# dest may be shorter than expected
	defined($dest = <DEST>) || do {
	    $ERROR = "$destfile ends at line $.";
	    return 0;
	};

	next if ($ignore);

	# dest line may be different than expected
	unless ($exp eq $dest) {
	    foreach ($exp, $dest) {
		s/\n/\\n/g;
	    }
	    $ERROR = "files $expfile and $destfile differ at line $.\n" 
		. "  expected: [$exp]\n"
		. "       got: [$dest]";
	    return 0;
	}
    }

    # dest file may be longer than expected
    unless(eof DEST) {
	$ERROR = "$destfile is longer than $expfile";
	return 0;
    }


    # close files and be done
    close(EXP);
    close(DEST);

    1;
}



#
# log_init()
#
# Initialise the log file.
#

sub log_init {
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)
		= localtime(time);

    &log_entry("Test logfile started at %s\n", 
	time2str("%H:%M:%S on %d:%b:%y", time));
}



#
# log_entry($format, @params)
#
# Writes an entry to the log file.  $format and @params are formatted as per
# printf(3C).
#

sub log_entry {
    open(LOGFILE, ">> $LOGFILE") && do {
	printf(LOGFILE shift, @_);
	close(LOGFILE);
    };
}


1;
