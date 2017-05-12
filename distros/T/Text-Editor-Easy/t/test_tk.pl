BEGIN {
    eval 'use Tk';
    if ( $@ ) {
        print "couldn't connect to display :.1.\n";
        print STDERR "1 - Tk is not installed or can't be used :\n";
        print STDERR "1 - ==> Check Tk installation and execute the tests in a graphical environment\n";
        exit;
    }
}

use IO::File;
autoflush STDOUT;

open STDERR, ">&STDOUT" or die "cannot dup STDERR to STDOUT: $!\n";
autoflush STDERR;

#use Tk; in BEGIN bloc for safe try with eval

eval "MainWindow->new()";

if ( $@ ) {
    print "couldn't connect to display :.2.\n";
    print STDERR "2 - Tk is not installed or can't be used :\n";
    print STDERR "2 - ==> Check Tk installation and execute the tests in a graphical environment\n";
    exit;
}

print "TK is OK\n";

