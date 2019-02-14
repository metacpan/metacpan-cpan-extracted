package Test::OnlySome;
use 5.012;
use strict;
use warnings;
use Data::Dumper;   # DEBUG

use Carp qw(croak);
use Keyword::Declare;   # {debug=>1};
use List::Util::MaybeXS qw(all);
use Scalar::Util qw(looks_like_number);

use vars;
use Import::Into;

use parent 'Exporter';
our @EXPORT = qw( skip_these skip_next );

our $VERSION = '0.001003';

use constant { true => !!1, false => !!0 };

# TODO move $TEST_NUMBER_OS into the options structure.

# Docs, including osprove and T::OS::RerunFailed example {{{3

=head1 NAME

Test::OnlySome - Skip individual tests in a *.t file

=head1 INSTALLATION

Easiest: install C<cpanminus> if you don't have it - see
L<https://metacpan.org/pod/App::cpanminus#INSTALLATION>.  Then run
C<cpanm Test::OnlySome>.

Manually: clone or untar into a working directory.  Then, in that directory,

    perl Makefile.PL
    make
    make test

... and if all the tests pass,

    make install

If some of the tests fail, please check the issues and file a new one if
no one else has reported the problem yet.

=head1 SYNOPSIS

Suppose you are testing a C<long_running_function()>.  If it succeeded last
time, you don't want to take the time to test it again.  In your test file
(e.g., C<t/01.t>):

    use Test::More tests => 2;
    use Test::OnlySome::RerunFailed;    # rerun only failed tests
    os ok(long_running_function());     # "os" marks tests that might be skipped
    os ok(0, 'fails');

At the command line, supposing the function passes the test:

    $ osprove -lv
    ...
    ok 1 - passes
    not ok 2 - fails
    ...
    Result: FAIL

This creates C<.onlysome.yml>, which holds the test results from C<t/01.t>.
Then, re-run:

    $ osprove -lv
    ...
    ok 1 # skip Test::OnlySome: you asked me to skip this
    not ok 2 - fails
    ...

Since test 1 passed the first time, it was skipped the second time.

You don't have to use L<Test::OnlySome::RerunFailed>.  You can directly
use C<Test::OnlySome>, and you can decide in some other way which tests
you want to skip.

The argument to L</os> can be a statement or block, and it doesn't have to
be a L<Test::More> test.  You can wrap long-running tests in functions,
and apply L</os> to those functions.

Please note that L</os> can take a C<test_count> argument, e.g., if there
are multiple tests in a block.  The whole block will be skipped if and only
if all the tests in that block are skipped.  Otherwise, the whole block
will be rerun.  The moral?  Use a C<test_count> of 1 for all tests run under
L<Test::OnlySome::RerunFailed> and you won't be surprised.

=head1 MARKING TESTS

You can pick which tests to skip using implicit or explicit configuration.
Explicit configuration uses a hashref:

    my $opts = { skip => { 2=>true } };

    os $opts ok(1, 'This will run');    # Single statement OK

    os $opts {                          # Block also OK
        ok(0, 'This will be skipped');  # Skipped since it's test 2
    };

Implicit configuration uses a hashref in the package variable C<$TEST_ONLYSOME>,
which Test::OnlySome creates in your package when you C<use> it:

    $TEST_ONLYSOME->{skip} = { 2=>true };
    os ok(1, 'Test 1');                     # This one runs
    os ok(0, 'Test 2 - should be skipped'); # Skipped since it's test 2

=cut

# }}}3
# Forward declarations of internal subs {{{3
sub _gen;
sub _is_testnum;
sub _opts;
sub _nexttestnum;
sub _escapekit;
sub _printtrace;
# }}}3
# Caller-facing routines {{{1

=head1 EXPORTS

=head2 skip_these

A convenience function to fill in C<< $hashref_options->{skip} >>.

    skip_these $hashref_options, 1, 2;
        # Skip tests 1 and 2
    skip_these 1, 2;
        # If you are using implicit configuration

=cut

sub skip_these {
    my ($hrOpts, $should_shift) = _opts($_[0]);
    shift if $should_shift;
    croak 'Need an options hash reference' unless ref $hrOpts eq 'HASH';
    foreach(@_) {
        if(_is_testnum) {
            $hrOpts->{skip}->{$_} = true;
        } else {
            croak "'$_' is not a valid test number";
        }
    }
} #skip_these()

=head2 skip_next

Another convenience function: Mark the next test to be skipped.  Example:

    skip_next;
    os ok(0, 'This one will be skipped');

=cut

sub skip_next {
    my ($hrOpts, $should_shift) = _opts($_[0]);
    shift if $should_shift;
    croak 'Need an options hash reference' unless ref $hrOpts eq 'HASH';
    $hrOpts->{skip}->{_nexttestnum()} = true;
} #skip_next()

# }}}1
# Importer, and keyword definitions {{{1

=head2 import

The C<import> sub defines the keywords so that they will be exported (!).
This is per L<Keyword::Declare>.

=cut

sub import {
    my $self = shift;
    my $target = caller;
    my $level = 1;

    #print STDERR "$self import into $target\n";
    #_printtrace();

    # Special-case imports from Test::Kit, since Test::Kit doesn't know how
    # to copy the custom keyword from its fake package to the ultimate caller.
    if($target =~ m{^Test::Kit::Fake::(.*)::\Q$self\E$}) {
        ($target, $level) = _escapekit($1);
        #print STDERR "$self real target = $target at level $level\n";
        $self->import::into($target);   # Import into the real target
        return;     # *** EXIT POINT ***
    }

    # Sanity check - e.g., `perl -MTest::OnlySome -E `os ok(1);` will
    # die because skip() isn't defined.  However, we don't require
    # Test::More because there might be other packages that you are
    # using that provide skip().
    {
        no strict 'refs';
        croak "Test::OnlySome: ${target}::skip() not defined - I can't function!  (Missing `use Test::More`?)"
            unless (defined &{ $target . '::skip' });
    }

    # Copy symbols listed in @EXPORT first.  Ignore @_, which we are
    # going to use for our own purposes below.
    $self->export_to_level($level);

    # Put List::Util::all() in the caller's package so we can use it in
    # the generated code.  Otherwise, the caller would have to use
    # List::Util manually.
    {
        no strict 'refs';
        *{ $target . '::__TOS_all' } = \&all;
    }

    # Create the variables we need in the target package
    vars->import::into($target, qw($TEST_NUMBER_OS $TEST_ONLYSOME));

    # Initialize the variables unless they already have been
    my $hrTOS;
    {
        no strict 'refs';
        ${ $target . '::TEST_NUMBER_OS' } = 1       # tests start at 1, not 0
            unless ${ $target . '::TEST_NUMBER_OS' };
        ${ $target . '::TEST_ONLYSOME' } = {}
            unless 'HASH' eq ref ${ $target . '::TEST_ONLYSOME' };
        $hrTOS = ${ $target . '::TEST_ONLYSOME' };
    };

    $hrTOS->{n} = 1 unless $hrTOS->{n};
    $hrTOS->{skip} = {} unless $hrTOS->{skip};
    $hrTOS->{verbose} = 0 unless $hrTOS->{verbose};

    # Check the arguments.  Numeric arguments are tests to skip.
    my $curr_keyword = '';
    foreach(@_) {
        if(/^skip$/) { $curr_keyword='skip'; next; }
        if(/^verbose$/) { $curr_keyword='verbose'; next; }

        if ( $curr_keyword eq 'verbose' ) {
            $hrTOS->{verbose} = !!$_;
            next;
        }

        if ( $curr_keyword eq 'skip' && _is_testnum ) {
            #print STDERR "TOS skipping $_\n";
            $hrTOS->{skip}->{$_} = true;
            next;
        }

        croak "Test::OnlySome: I can't understand argument '$_'" .
            ($curr_keyword ? " to keyword '$curr_keyword'" : '');
    } # foreach arg

    if($hrTOS->{verbose}) {
        my $msg = "# Test::OnlySome $VERSION loading\nConfig:\n" .
            Dumper($hrTOS);
        $msg =~ s/^/# /gm;
        print STDERR $msg;
    }

# `os` keyword - mark each test-calling statement this way {{{2

=head2 os

Keyword C<os> marks a statement that should be excuted B<o>nly B<s>ome of
the time.  Example:

    os 'main::debug' $hrOpts  ok 1,'Something';
        # Run "ok 1,'Something'" if hashref $hrOpts indicates.
        # Save debug information into $main::debug.

Syntax:

    os ['debug::variable::name'] [$hashref_options] [test_count] <statement | block>

=over

=item *

C<$debug::variable::name> will be assigned at compilation time.  If specified,
the given package variable will be filled in with the L<Keyword::Declare>
parse of the os invocation.

=item *

C<$hashref_options> will be accessed at runtime.  If it is not given,
L</$TEST_ONLYSOME> will be used instead.

=item *

C<test_count> must be a numeric literal, if present.  If it is given,
it will be used instead of the number of tests specified in
C<< $hashref_options->{n} >>.

=back

=head3 Cautions

=over

=item *

The given statement or block will be run in its own lexical scope,
not in the caller's scope.

=item *

If you use C<< test_count>1 >>, the whole block will be skipped only if
every test in the block is marked to be skipped.  So, for example,

    os 2 { ok(1); ok(0); }

will still run the C<ok(1)> even if it was marked to be skipped if
the C<ok(0)> was not marked to be skipped.

=back

I recommend that, when using L<Test::OnlySome::RerunFailed>, you always use
C<< test_count == 1 >>.

=cut

    keyword os(String? $debug_var, Var? $opts_name, Num? $N,
                Block|Statement $controlled)
    {

        # At this point, caller() is in Keyword::Declare.
        #my $target = caller(2);     # Skip past Keyword::Declare's code.
        #                            # TODO make this more robust.

        if(defined $debug_var) {
            no strict 'refs';
            $debug_var =~ s/^['"]|['"]$//g;   # $debug_var comes with quotes
            ${$debug_var} = {opts_var_name => $opts_name, code => $controlled,
                n => $N};
            #print STDERR "# Stashed $controlled into `$debug_var`\n";
            #print STDERR Carp::ret_backtrace(); #join "\n", caller(0);
        }

        # Get the options
        my $hrOptsName = $opts_name || '$TEST_ONLYSOME';

#        print STDERR "os: Options in $hrOptsName\n";
#        _printtrace();

        croak "Need options as a scalar variable - got $hrOptsName"
            unless defined $hrOptsName && substr($hrOptsName, 0, 1) eq '$';

        return _gen($hrOptsName, $controlled, $N);
    } # os() }}}2

} # import()

# Unimport {{{2

=head2 unimport

Removes the L</os> keyword definition.

=cut

sub unimport {
    unkeyword os;
}

# }}}2
# }}}1
# Implementation of keywords (macro), and internal helpers {{{1

=head1 INTERNALS

=head2 _gen

This routine generates source code that, at runtime, will execute a given
only-some test.

=cut

sub _gen {
    my $optsVarName = shift or croak 'Need an options-var name';
    my $code = shift or croak 'Need code';
    my $N = shift;

    # Syntactic parts, so I don't have to disambiguate interpolation in the
    # qq{} below from hash access in the generated code.  Instead of
    # $foo->{bar}, interpolations below use $foo$W$L bar $R.
    my $W = '->';
    my $L = '{';
    my $R = '}';

    $N = "$optsVarName$W$L n $R // 1" unless $N;

    my $replacement = qq[
        {
            my \$__ntests = $N;
            my \$__first_test_num = \$TEST_NUMBER_OS;
            \$TEST_NUMBER_OS += \$__ntests;
            my \$__skips = $optsVarName$W$L skip $R;
            my \@__x=(\$__first_test_num .. (\$__first_test_num+\$__ntests-1));
            # print STDERR 'Tests: ', join(', ', \@__x), "\\n";

            SKIP: {
                skip 'Test::OnlySome: you asked me to skip this', \$__ntests
                    if __TOS_all { \$__skips$W$L \$_ $R } \@__x;

                $code
            }
        }
    ];

    #print STDERR "$replacement\n"; # DEBUG
    return $replacement;

} #_gen()

=head2 _is_testnum

Return True if the provided parameter, or C<$_>, is a valid test number.

=cut

sub _is_testnum {
    my $arg = shift // $_;
    return ($arg && !ref($arg) && looks_like_number($arg) && $arg >= 1);
} #_is_testnum()

# `os`, skip*() helpers {{{2

=head2 _opts

Returns the appropriate options hashref, and an indication of whether
the caller should C<shift> (true for explicit config).  Call as C<_opts($_[0])>.

=cut

sub _opts {
    my $target = caller(1) or croak 'Could not find caller';
    my $arg = shift;

#    print STDERR "_opts: Options in ", (ref $arg eq 'HASH' ?
#        'provided hashref' : "\$${target}::TEST_ONLYSOME\n");
#    _printtrace();

    return ($arg, true) if ref $arg eq 'HASH';

    # Implicit config: find the caller's package and get $TEST_ONLYSOME
    return do { no strict 'refs'; (${ "$target" . '::TEST_ONLYSOME' }, false) };

} #_opts()

=head2 _nexttestnum

Gets the caller's current C<$TEST_NUMBER_OS> value.

=cut

sub _nexttestnum {
    my $target = caller(1) or croak 'Could not find caller';
    return do { no strict 'refs'; ${ "$target" . '::TEST_NUMBER_OS' } };
} #_nexttestnum()

# }}}2
# `use` helpers {{{2

=head2 _escapekit

Find the caller that is using a Test::Kit package to use this module.  This
helps us import the keyword into the right module.

=cut

sub _escapekit {
# Find the real target package, in case we were called from Test::Kit
    my $kit = shift;
    #print STDERR "Invoked from Test::Kit module $kit\n";

    my $level;

    my $callpkg;

    # Find the caller of $kit, and import directly there.
    for($level=0; 1; ++$level) {
        $callpkg = caller($level);
        last unless $callpkg;
        last if $callpkg eq $kit;
    } #for levels

    if($callpkg && ($callpkg eq $kit)) {
        ++$level;
        $callpkg = caller($level);
        return ($callpkg, $level) if $callpkg;
    }

    die "Could not find the module that invoked Test::Kit module $kit";
} #_escapekit()

=head2 _printtrace

Print a full stack trace

=cut

sub _printtrace {
    # Print full stack trace
    my @callers;
    for(my $i=0; 1; ++$i) {
        ##       0         1          2      3            4
        #my ($package, $filename, $line, $subroutine, $hasargs,
        ##    5          6          7            8       9         10
        #$wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash)
        #= caller($i);
        push @callers, [caller($i)];
        last unless $callers[-1]->[0];
    }
    print Dumper(\@callers), "\n";
}

# }}}2
# }}}1
# More docs {{{3
=head1 VARIABLES

=head2 C<$TEST_NUMBER_OS>

Exported into the caller's package.  A sequential numbering of tests that
have been run under L</os>.

=head2 C<$TEST_ONLYSOME>

Exported into the caller's package.  A hashref of options, of the same format
as an explicit-config hashref.  Keys are:

=over

=item * C<n>

The number of tests in each L</os> call.

=item * C<skip>

A hashref of tests to skip.  That hashref is keyed by test number; any truthy
value indicates that the L</os> call beginning with that test number
should be skipped.

B<Note:> The test numbers used by L</os> are B<only> those run under L</os>.
For example:

    skip_these 2;
    os ok(1);       # os's test 1
    ok(0);          # oops - not skipped - no "os"
    os ok(0);       # this one is skipped - os's test 2

=back

=head1 AUTHOR

Christopher White, C<< <cxwembedded at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests on GitHub, at
L<https://github.com/cxw42/Test-OnlySome/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::OnlySome

You can also look for information at:

=over 4

=item * The GitHub repository

L<https://github.com/cxw42/Test-OnlySome>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-OnlySome>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Test-OnlySome>

=item * Search CPAN

L<https://metacpan.org/release/Test-OnlySome>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-OnlySome>

=back

This module is versioned with L<semantic versioning|https://semver.org>,
but in the backward-compatible Perl format.  So version C<0.001003> is
semantic version C<0.1.3>.

=cut

# }}}3
# License {{{3

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Christopher White.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut

# }}}3
1;

# vi: set fdm=marker fdl=2: #
