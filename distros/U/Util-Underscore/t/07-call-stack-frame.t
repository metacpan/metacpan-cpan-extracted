#!perl

use strict;
use warnings;

use Test::More tests => 13;

BEGIN { use_ok 'Util::Underscore::CallStackFrame'; }

my $class = 'Util::Underscore::CallStackFrame';

subtest 'constructor' => sub {
    plan tests => 3;

    can_ok $class, 'of';
    isa_ok $class->of(0), $class;
    my $call_depth = 0;
    $call_depth++ while caller $call_depth;
    is_deeply [$class->of($call_depth)], [],
        "constructor returns () if there's no frame";
};

subtest 'package' => sub {
    plan tests => 1;

    is +(sub { $class->of(0)->package })->(), __PACKAGE__, "correct return value";
};

subtest 'file' => sub {
    plan tests => 1;

    is +(sub { $class->of(0)->file })->(), __FILE__, "correct return value";
};

subtest 'line' => sub {
    plan tests => 1;

    is +(sub { $class->of(0)->line })->(), __LINE__, "correct return value";
};

subtest 'subroutine' => sub {
    plan tests => 2;

    ## no critic (ProhibitMultiplePackages)
    package Local::SomeTest;

    my $package = __PACKAGE__;
    local *freddy;
    eval q{ sub freddy { $class->of(0) } };  ## no critic (ProhibitStringyEval)
    die $@ if $@;
    my $anon = sub { $class->of(0) };

    Test::More::is freddy()->subroutine, "${package}::freddy", "named sub";
    Test::More::is $anon->()->subroutine, "${package}::__ANON__", "anon sub";
};

subtest 'has_args' => sub {
    plan tests => 3;

    my $sub = sub { $class->of(0) };
    ok not(&$sub->has_args), "no new argument list";
    ok $sub->()->has_args, "new argument list";
    my @args = ([ 1, 2 ], { a => 42 }, undef);
    is_deeply scalar($sub->(@args)->has_args), \@args, "complicated arguments";
};

subtest 'wantarray' => sub {
    plan tests => 4;

    my $obj;
    my $sub = sub { $obj = $class->of(0) };

    () = $sub->();
    ok scalar $obj->wantarray, "list context";

    scalar $sub->();
    ok not($obj->wantarray), "scalar context is false";
    ok defined($obj->wantarray), "scalar context is defined";

    $sub->();
    ok not(defined $obj->wantarray), "scalar context is undef";
};

subtest 'is_eval, is_require' => sub {
    plan tests => 12;

    my $sub = sub { $class->of(0) };
    my $eval_block = sub {
        eval { $class->of(0) };
    };
    my $code = q{ $class->of(0); };
    my $eval_string = sub { eval $code };  ## no critic (ProhibitStringyEval

    ok not($sub->()->is_eval), "ordinary frame not is_eval";
    ok $eval_block->()->is_eval(),  "block-eval is_eval";
    ok $eval_string->()->is_eval(), "string-eval is_eval";

    is $eval_block->()->is_eval->source, undef, "block-eval has no source";
    like $eval_string->()->is_eval->source, qr/\A \Q$code\E (?:\n[;])? \z/smx,
        "string-eval has correct source";

    ok not($eval_block->()->is_eval->is_require),
        "block-eval not (is_eval AND is_require)";
    ok not($eval_string->()->is_eval->is_require),
        "string-eval not (is_eval AND is_require)";

    ok not($eval_block->()->is_require),  "block-eval not is_require";
    ok not($eval_string->()->is_require), "string-eval not is_require";

    # What follows is a horrible hack to simulate a require without using
    # an external file. Basically. you can put callbacks into `@INC` which are
    # executed when resolving a package name. This handler returns a callback
    # that reads a file in line by line.
    # For more details, read `perldoc -f require`.
    {
        # clear @INC, %INC so that our handler is the only entry
        local *INC;

        # add the handler.
        push @INC, sub {
            my (undef, $name) = @_;
            return if $name ne 'Local/Whatever.pm';
            return (
                sub {
                    my (undef, $state) = @_;
                    if (@$state) {
                        $_ = shift @$state;
                        return 1;
                    }
                    else {
                        return 0;
                    }
                },
                [
                    q{package Local::Whatever;},
                    qq{my \$instance = $class->of(0);},
                    q{sub get { $instance };},
                    q{1;}
                ],
            );
        };

        # execute the require, which launches the handler.
        # this is an eval to hide it from autmatic dependency discovery
        eval q{ require Local::Whatever };
        die $@ if $@;
    }

    my $obj = Local::Whatever::get();
    ok $obj->is_eval, "require is_eval";
    ok $obj->is_eval->is_require, "require is_eval AND is_require";
    ok $obj->is_require, "require is_require";
};

my $hints;
subtest 'hints' => sub {
    plan tests => 1;

    BEGIN { $hints = $^H }
    my $obj = (sub { $class->of(0) })->();
    is_deeply $obj->hints, $hints, "correct hints scalar";
};

my $bitmask;
subtest 'bitmask' => sub {
    plan tests => 1;

    BEGIN { $bitmask = ${^WARNING_BITS} }
    my $obj = (sub { $class->of(0) })->();
    is_deeply $obj->bitmask, $bitmask, "correct warning bits";
};

my $hinthash;
subtest 'hinthash' => sub {
    plan tests => 1;

    # make sure %^H isn't empty
    BEGIN {
        ## no critic (RequireLocalizedPunctuationVars)
        $^H{'Local::TestPackage/value'} = 42;
    }
    BEGIN { $hinthash = \%^H }
    my $obj = (sub { $class->of(0) })->();
    is_deeply $obj->hinthash, $hinthash, "correct hint hash";
};

subtest 'stack frames obtained correctly' => sub {
    plan tests => 3;

    #<<< formatting is important
    my @frames = Local::TestPackage::bar([ __PACKAGE__, __FILE__, __LINE__, 'Local::TestPackage::bar' ]);
    #>>>

    for (my $i = 0 ; $i < @frames ; $i++) {
        subtest "frame $i" => sub {
            my ($obj, $package, $file, $line, $sub) = @{ $frames[$i] };
            is $obj->package,    $package, "expected package";
            is $obj->file,       $file,    "expected file";
            is $obj->line,       $line,    "expected line";
            is $obj->subroutine, $sub,     "expected sub name";
        };
    }
};

{
    ## no critic (ProhibitMultiplePackages)
    package Local::TestPackage;

    sub foo {
        my ($expect_a, $expect_b) = @_;
        my $sub = sub { $class->of(shift) };  ## no critic (RequireArgUnpacking)
        my @frames;
        #>>> formatting is important
        push @frames, [ $sub->(0), __PACKAGE__, __FILE__,  __LINE__, 'Local::TestPackage::__ANON__' ];
        #<<<
        push @frames, [ $sub->(1), @$expect_a ];
        push @frames, [ $sub->(2), @$expect_b ];
        return @frames;
    }

    ## no critic (RequireArgUnpacking)
    sub bar {
        #>>> formatting is important
        return foo([ __PACKAGE__, __FILE__, __LINE__, 'Local::TestPackage::foo' ], @_);
        #<<<
    }
}
