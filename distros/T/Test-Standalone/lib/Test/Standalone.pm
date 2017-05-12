###########################################
package Test::Standalone;
###########################################
use strict;
use warnings;
use Filter::Util::Call;
use Getopt::Std;

my $CODE       = "";
my $IN_TEST    = 0;
my $TEST_START = qr(^=begin test);
my $TEST_END   = qr(^=end test);

our $VERSION = "0.01";

###########################################
sub import {
###########################################
    my($type, @arguments) = @_ ;
    filter_add([]) ;

    if(@ARGV and $ARGV[0] eq "--test") {
        $IN_TEST = 1;
    }
}

###########################################
sub filter {
###########################################
    my $status = filter_read();
    if(/$TEST_START/ .. /$TEST_END/) {
        if(!/$TEST_START/ and !/$TEST_END/) {
            $CODE .= $_;
        }
    }
    if($IN_TEST) {
        if( s/^\s*main\s*\(\)/Test::Standalone::test_run()/ ) {
            $IN_TEST = 0;
        }
    }
    $status;
}

###########################################
sub test_run {
###########################################
    my $code = "package main; " .
               Test::Standalone::test_code();

    eval $code or die "eval failed: $!";
    exit 0;
}

###########################################
sub test_code {
###########################################
    return $CODE;
}

1;

__END__

=head1 NAME

Test::Standalone - Embed regression test suites in standalone scripts

=head1 SYNOPSIS

        # Normal operation
    $ script.pl 
    ...

        # Regression test mode
    $ script.pl --test
    1..3
    ok 1 - Dies with non-existent files
    ...

    # ==============================
    #!/usr/bin/perl
    # ==============================
    use Test::Standalone;

    main();

    sub main {
        # script code
    }

    =begin test

        # test code, only executed if script 
        # gets called with --test option

        use Test::More tests => 3;
        use Test::Exception;

        @ARGV = ("/tmp/does/not/exist");
        throws_ok { main() } qr/No such file/, 
                  "Dies with non-existent files";
        ...

    =end test

=head1 DESCRIPTION

C<Test::Standalone> helps embedding regression test suites into standalone
scripts without disrupting them.

During normal operation, the test suite doesn't even get compiled. It can 
use all kinds of fancy test modules which don't need to be present
for the script to operate in normal mode. Only when the script gets called
with the C<--test> option, a source filter kicks in and executes the
test suite embedded between these POD directives:

    =begin test
    ...
    =end test

=head1 EXAMPLE

If the following script gets called with one or more file names, it
prints out the byte sizes of these files:

    $ script.pl /etc/passwd /etc/group
    /etc/passwd has 2900 bytes
    /etc/group has 935 bytes

If it gets called with the C<--test> option, the embedded test regression 
suite gets executed:

    $ script.pl --test
    1..2
    ok 1 - Test STDOUT
    ok 2 - Check with -s
    ok 3 - Dies with non-existent files

Here's the code. Note how it uses C<main()> to call the script's main
code and how the test suite uses C<main()> and C<@ARGV> to run the 
script with different arguments and to check its STDOUT output with
C<Test::Output>:

    use Test::Standalone;

    main();

    sub main {
        for my $file (@ARGV) {
            print "$file has ", -s $file, " bytes\n";
        }
    }

    =begin test

    use Test::More tests => 2;

    use File::Temp qw(tempfile); 

    my($fh, $file) = tempfile();
    print $fh "123";
    close $fh;

    @ARGV = ($file);
    use Test::Output;
    stdout_is(\&main, "$file has 3 bytes\n", "Test STDOUT");
    is(-s $file, 3, "Check with -s");

    @ARGV = ("/tmp/does/not/exist");
    use Test::Exception;
    throws_ok { main() } qr/No such file/, 
              "Dies with non-existent files";
    
    =end test

It works like this: C<use Test::Standalone> calls
the C<import> function in
C<Test::Standalone>, which invokes a source
filter on the main script. 

B<It is paramount that the main body of the 
script is encapsulated in a function called C<main> and that C<main>
gets called by the script at the beginning.>

The C<import> function checks if the C<--test> command line option was
set. If not, it does nothing and lets the script resume its normal
operation.

If C<--test> command line option is set, however, the source filter
kicks in and extracts the test suite code embedded between the
C<=begin test> and C<=end test> directives.
Also, it rewrites the call
to C<main()> to C<Test::Standalone::test_run()>. This will run the test
suite instead of the script.

The test script runs in the C<main> namespace.
Tests in the test suite are typically run by setting C<@ARGV> (therefore
setting different command line parameters) and then running C<main()>
to execute the script. The test suite can employ all kinds of test modules,
C<Test::More>, C<Test::Output>, C<Test::Exception> and many more. They
are not required during normal operation of the script, typically
only for the script developer running the regression test suite.

=head1 LEGALESE

Copyright 2005 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2006, Mike Schilli <cpan@perlmeister.com>
