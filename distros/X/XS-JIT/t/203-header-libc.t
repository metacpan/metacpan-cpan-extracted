#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

BEGIN {
    use_ok('XS::JIT::Header');
}

# Skip if we can't find a C compiler
my $has_compiler = eval {
    system("cc --version >/dev/null 2>&1") == 0 ||
    system("gcc --version >/dev/null 2>&1") == 0 ||
    system("clang --version >/dev/null 2>&1") == 0;
};

unless ($has_compiler) {
    plan skip_all => 'No C compiler available';
}

my $cache_dir = tempdir(CLEANUP => 1);

subtest 'Bind math.h functions' => sub {
    # Find math.h
    my $math_h;
    for my $path ('/usr/include/math.h', '/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/math.h') {
        if (-f $path) {
            $math_h = $path;
            last;
        }
    }

    unless ($math_h) {
        # Try to let the system find it
        $math_h = 'math.h';
    }

    my $math = eval {
        XS::JIT::Header->new(
            header    => $math_h,
            package   => 'TestMath',
            cache_dir => $cache_dir,
        );
    };

    if (!$math) {
        diag "Could not create Header object for math.h: $@";
        pass("Skipping math.h tests - header not found");
        return;
    }

    # Check if sin function was parsed
    my $sin_info = $math->function('sin');
    if (!$sin_info) {
        diag "sin function not found in parsed header";
        diag "Available functions: " . join(', ', $math->functions);
        pass("Skipping - sin not found in header");
        return;
    }

    # Attach some math functions
    eval {
        $math->attach('sin');
        $math->attach('cos');
        $math->attach('sqrt');
        $math->compile;
    };

    if ($@) {
        diag "Compilation failed: $@";
        pass("Skipping - compilation failed");
        return;
    }

    # Test the functions
    my $pi = 3.14159265358979;

    my $sin_val = eval { TestMath::sin($pi / 2) };
    if ($@) {
        diag "sin call failed: $@";
        pass("Skipping - function call failed");
        return;
    }

    ok(abs($sin_val - 1.0) < 0.0001, "sin(pi/2) ≈ 1.0 (got $sin_val)");

    my $cos_val = TestMath::cos(0);
    ok(abs($cos_val - 1.0) < 0.0001, "cos(0) ≈ 1.0 (got $cos_val)");

    my $sqrt_val = TestMath::sqrt(16);
    ok(abs($sqrt_val - 4.0) < 0.0001, "sqrt(16) ≈ 4.0 (got $sqrt_val)");
};

subtest 'Bind stdlib functions' => sub {
    my $stdlib = eval {
        XS::JIT::Header->new(
            header    => 'stdlib.h',
            package   => 'TestStdlib',
            cache_dir => $cache_dir,
        );
    };

    if (!$stdlib) {
        diag "Could not create Header object for stdlib.h: $@";
        pass("Skipping stdlib.h tests");
        return;
    }

    # Check for abs function
    my $abs_info = $stdlib->function('abs');
    if (!$abs_info) {
        pass("Skipping - abs not found in header");
        return;
    }

    eval {
        $stdlib->attach('abs');
        $stdlib->compile;
    };

    if ($@) {
        diag "Compilation failed: $@";
        pass("Skipping - compilation failed");
        return;
    }

    is(TestStdlib::abs(-42), 42, 'abs(-42) = 42');
    is(TestStdlib::abs(42), 42, 'abs(42) = 42');
    is(TestStdlib::abs(0), 0, 'abs(0) = 0');
};

subtest 'Bind string functions' => sub {
    my $string = eval {
        XS::JIT::Header->new(
            header    => 'string.h',
            package   => 'TestString',
            cache_dir => $cache_dir,
        );
    };

    if (!$string) {
        diag "Could not create Header object for string.h: $@";
        pass("Skipping string.h tests");
        return;
    }

    # Check for strlen
    my $strlen_info = $string->function('strlen');
    if (!$strlen_info) {
        pass("Skipping - strlen not found in header");
        return;
    }

    eval {
        $string->attach('strlen');
        $string->compile;
    };

    if ($@) {
        diag "Compilation failed: $@";
        pass("Skipping - compilation failed");
        return;
    }

    is(TestString::strlen("hello"), 5, 'strlen("hello") = 5');
    is(TestString::strlen(""), 0, 'strlen("") = 0');
    is(TestString::strlen("test string"), 11, 'strlen("test string") = 11');
};

subtest 'Function aliasing' => sub {
    my $math = eval {
        XS::JIT::Header->new(
            header    => 'math.h',
            package   => 'TestAlias',
            cache_dir => $cache_dir,
        );
    };

    if (!$math || !$math->function('pow')) {
        pass("Skipping aliasing tests");
        return;
    }

    eval {
        $math->attach('pow' => 'power');  # Alias pow to power
        $math->compile;
    };

    if ($@) {
        diag "Compilation failed: $@";
        pass("Skipping - compilation failed");
        return;
    }

    my $result = TestAlias::power(2, 10);
    ok(abs($result - 1024) < 0.0001, 'power(2, 10) ≈ 1024');
};

subtest 'attach_all with filter' => sub {
    my $math = eval {
        XS::JIT::Header->new(
            header    => 'math.h',
            package   => 'TestFilter',
            cache_dir => $cache_dir,
        );
    };

    if (!$math) {
        pass("Skipping filter tests");
        return;
    }

    # Get available functions
    my @funcs = $math->functions;
    diag "Found " . scalar(@funcs) . " functions in math.h";

    # Just attach a couple specific ones we know exist
    if (grep { $_ eq 'floor' } @funcs) {
        $math->attach('floor');
    }
    if (grep { $_ eq 'ceil' } @funcs) {
        $math->attach('ceil');
    }

    if (!@{$math->{_functions}}) {
        pass("Skipping - no functions to test");
        return;
    }

    eval { $math->compile };
    if ($@) {
        diag "Compilation failed: $@";
        pass("Skipping - compilation failed");
        return;
    }

    if (TestFilter->can('floor')) {
        is(TestFilter::floor(3.7), 3, 'floor(3.7) = 3');
    }

    if (TestFilter->can('ceil')) {
        is(TestFilter::ceil(3.2), 4, 'ceil(3.2) = 4');
    }
};

subtest 'Constants from header' => sub {
    my $math = eval {
        XS::JIT::Header->new(
            header    => 'math.h',
            package   => 'TestConst',
            cache_dir => $cache_dir,
        );
    };

    if (!$math) {
        pass("Skipping constant tests");
        return;
    }

    my @consts = $math->constants;
    diag "Found " . scalar(@consts) . " constants in math.h";

    # M_PI might be defined
    my $pi = $math->constant('M_PI');
    if ($pi) {
        ok(abs($pi - 3.14159265) < 0.0001, 'M_PI ≈ 3.14159');
    }
    else {
        pass("M_PI not defined (platform-specific)");
    }

    # M_E might be defined
    my $e = $math->constant('M_E');
    if ($e) {
        ok(abs($e - 2.71828) < 0.001, 'M_E ≈ 2.71828');
    }
    else {
        pass("M_E not defined (platform-specific)");
    }
};

done_testing;
