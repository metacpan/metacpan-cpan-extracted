use strict;
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
our @tests;
BEGIN { 
    @tests = glob("test_templates/*.tmpl");
    # idx starts at 1, and test1 is for loading
    my $num_tests = $#tests + 5;
    my $idx = 0;
    my %find_idx = map { ( $_, $idx++ ) } @tests;
    my @todos;


    # we add 2 similarly to above
    plan tests => $num_tests, todo => [ map { $find_idx{$_} + 2 } @todos  ] 
    #plan tests => $num_tests;
};
use Text::Macro;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.


#print "files: ", join( ", ", @tests ), "\n";

our %dontparse = map { ($_,$_) } qw( text.tmpl );



#get check-data
our %check;
for my $key ( @tests )
{
    my $val = $key;
    $val =~ s/\.tmpl/\.chk/;

    $key =~ s!.*/!!;

    my $fh = new IO::File "$val" or die "Couldn't open file: $val";
    my $data = join("", $fh->getlines() );
    $data =~ s/\s+//sg unless exists $dontparse{$key};
    $check{$key} = $data;
    #print "check=[$check{$key}], key=[$key], data=[$data]\n";
}

#print "files: ", join(", ", @tests ), "\n";

for my $key ( @tests )
{
    testFile( $key );
}


printTest("text.tmpl");

pipeTest("text.tmpl");

toFileTest("text.tmpl");

# ------------------------------

sub testFile($)
{
    my ( $test ) = @_;
    print "Testing file $test\n";
    my ( $obj, $str );
    eval {
    $obj = new Text::Macro path => 'test_templates/', file => $test or die "Couldn't parse file: $test";
    }; if ( $@ ) { 
		print "Could not compile: $@\n";
        #print "CODE{\n$obj->{src}\n}CODE\n";
	 	ok(0);
		return;
	 }

    eval {
        $str  = $obj->toString( 
        {
            true_var => 1,
            false_var => 0,
            undef_var => undef,
            for_block =>
            [
                { a => 1, b => 2 },
                { a => 3, b => 4 },
                { a => 5, b => 6 },
            ],
			nested_for_block =>
			[
				{ a => 1, s => [ { a => 2 }, { a => 3 } ] },
				{ a => 4, s => [ { a => 5 }, { a => 6 } ] },
			],
            value => 'dog',
			my_array => [ qw( zero one two three ) ],
			my_hash => { qw( key1 val1 key2 val2 ), complex => [ 0, 1, 2 ] },
        } );
    }; if ( $@ ) { 
        print "Could not render: $@\n"; 
        print "CODE{\n$obj->{src}\n}CODE\n";
        ok(0);
        return;
    }
    #print "CODE\n$obj->{src}\nCODE\n";

	#print "str=$str\n";
    $str =~ s/\s+//sg unless exists $dontparse{$test};
    if ( ! ok( $str, $check{$test} ) ) {
    	print "CODE\n$obj->{src}\nCODE\n";
	}
} # end testFile


sub printTest
{
    print "print-test\n";
    my $test = shift;
    my $obj;
    eval {
        $obj = new Text::Macro path => 'test_templates/', file => $test or die "Couldn't parse file: $test";
    }; if ( $@ ) {
        print "Could not compile: $@\n"; ok(0); return;
    }

    eval {
        $obj->print( {} );
    }; if ( $@ ) {
        print "Could not render: $@\n"; 
        print "CODE\n$obj->{src}\nCODE\n";
        ok(0);
        return;
    }
    ok(1);
} # end printTest


sub pipeTest
{
    my $test = shift;
    print "pipe-test\n";
    my $obj;
    eval {
        $obj = new Text::Macro path => 'test_templates/', file => $test or die "Couldn't parse file: $test";
    }; if ( $@ ) {
        print "Could not compile: $@\n"; ok(0); return;
    }

    my $str;
    eval {
        my $fname = "/tmp/test_$$";
        my $fh = new IO::File ">$fname";
        $obj->pipe( {}, $fh );
        $fh->close();
        $fh = new IO::File $fname;
        $str = join( "", $fh->getlines() );
        $fh->close();
        unlink $fname;
    }; if ( $@ ) {
        print "Could not render: $@\n"; 
        print "CODE\n$obj->{src}\nCODE\n";
        ok(0);
        return;
    }
    ok( $str, $check{$test} );
} # end pipeTest

sub toFileTest
{
    my $test = shift;
    print "pipe-test\n";
    my $obj;
    eval {
        $obj = new Text::Macro path => 'test_templates/', file => $test or die "Couldn't parse file: $test";
    }; if ( $@ ) {
        print "Could not compile: $@\n"; ok(0); return;
    }

    my $str;
    eval {
        my $fname = "/tmp/test_$$";
        $obj->toFile( {}, $fname );

        my $fh = new IO::File $fname;
        $str = join( "", $fh->getlines() );
        $fh->close();
        unlink $fname;
    }; if ( $@ ) {
        print "Could not render: $@\n"; 
        print "CODE\n$obj->{src}\nCODE\n";
        ok(0);
        return;
    }
    ok( $str, $check{$test} );
} # end toFileTest
