# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tie::CharArray;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# modified from synopsis
eval {
    my $foo = "a string";
    tie my @foo, 'Tie::CharArray', $foo;
    $foo[0] = 'A';
    push @foo, '!';

    print "not " unless $foo eq "A string!";
    print "ok 2\n";
};
print "not ok 2 # $@" if $@;

# modified from synopsis
eval {
    my $foo = "A string!";
    tie my @foo, 'Tie::CharArray::Ord', $foo;
    $foo[0] += ord('1') - ord('A');
    pop @foo;

    print "not " unless $foo eq "1 string";
    print "ok 3\n";
};
print "not ok 3 # $@" if $@;

# does multiple tie work?
eval {
    my $foobar = "B";
    tie my @foo, 'Tie::CharArray', $foobar;
    tie my @bar, 'Tie::CharArray::Ord', $foobar;
    unshift @foo, "A";
    push @bar, ord("C");

    print "not " unless $foobar eq "ABC";
    print "ok 4\n";
};
print "not ok 4 # $@" if $@;

# does the tie leak?
eval {
    my $foo = sub { 1 };
    tie my @foo, 'Tie::CharArray', $foo;
    print "not " unless ref($foo) eq 'CODE' and !tied($foo);
    print "ok 5\n";
};
print "not ok 5 # $@" if $@;

# implicit string
eval {
    tie my @foo, 'Tie::CharArray';
    tie my @bar, 'Tie::CharArray';
    push @foo, qw/a b c/;
    push @bar, qw/x y z/;

    print "not " unless "@bar/@foo" eq "x y z/a b c";
    print "ok 6\n";
};
print "not ok 6 # $@" if $@;

# exported functions
eval {
    package Test7;
    use Tie::CharArray qw( chars codes );
    my $foobar = 'testing..';
    
    my $foo = chars $foobar;
    my $bar = codes $foobar;

    $foo->[-2] = '!';
    $bar->[0] = ord('T');
    pop @$bar;

    print "not " unless $foobar eq 'Testing!';
    print "ok 7\n";
};
print "not ok 7 # $@" if $@;

# functions in list context
eval {
    package Test8;
    use Tie::CharArray qw( chars );
    my $foo = 'testing';
    my $bar = 'CENSORED';

    $_ = chop($bar) for reverse chars $foo;

    print "not " unless $foo eq 'ENSORED';
    print "ok 8\n";
};
print "not ok 8 # $@" if $@;

# aliasing subroutine args
eval {
    package Test9;
    use Tie::CharArray qw( chars );

    sub munge { $_[0] = 'A', $_[-1] = 'Z' }

    my $foo = 'testing';
    munge chars $foo;

    print "not " unless $foo eq 'AestinZ';
    print "ok 9\n";
};
print "not ok 9 # $@" if $@;

__END__

