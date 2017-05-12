use strict;
use warnings;
use Test::More qw(no_plan);
use Try::Catch;

{
    try {
        try {
            die "inner oops";
        }
        finally {
            pass("finally called");
        };

        fail("should not be called");
    }
    catch {
        ok ($_ =~ /^inner oops/);
    };
}

{
    try {
        try {
            die "inner oops";
        }
        catch {
            ok ($_ =~ /^inner oops/);
        }
        finally {
            pass("finally called");
        };
        pass("called after not handling error from catch block");
    }
    catch {
        fail("should not be called");
    };
}

{
    try {
        try {
            die "inner2 oops";
        }
        catch {
            ok($_ =~ /^inner2 oops/);
            die $_;
        }
        finally {
            pass("finally called");
        };
    }
    catch {
        ok($_ =~ /^inner2 oops/);
    };
}

{
    my $val = 0;
    my @expected;
    try {
        try {
            try {
                try {
                    die "9";
                } catch {
                    $val = 9;
                    die $_;
                } finally {
                    try {
                        push @expected, 1;
                        is($val, 9, "first finally called");
                        die "new Error";
                    } catch {};
                };
            } catch {
                pass("cach called");
                push @expected, 2;
            } finally {
                die "second finally called $val\n";
            };
            fail("should not reach here");
        }  catch {
            $val = 10;
            die $_;
        } finally {
            push @expected, 3;
            is ($val, 10, "final finally called");
        };
        fail("should not reach here");
    } catch {
        ok ($_ =~ /^second finally called 9/);
    };
    is_deeply \@expected, [1,2,3];
}
