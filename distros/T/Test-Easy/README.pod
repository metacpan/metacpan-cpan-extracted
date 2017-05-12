use strict;
use warnings;
package Test::Easy;
use base qw(Exporter);

use 5.006002;

# used as helper modules within this module
require Test::More;
use Carp qw(confess);

# this module re-exports functions from these modules
use Test::Easy::DataDriven;
use Test::Easy::DeepEqual;
use Test::Easy::Time;
use Test::Resub;

our $VERSION = 1.11;

## spend a little time moving things around into @EXPORT, @EXPORT_OK
our @EXPORT = qw(nearly_ok around_about wiretap);
our @EXPORT_OK = qw(nearly test_sub);
foreach my $supplier (qw(
  Test::Resub
  Test::Easy::DataDriven
  Test::Easy::Time
  Test::Easy::DeepEqual
)) {
  no strict 'refs';
  push @EXPORT, @{"$supplier\::EXPORT"};
  push @EXPORT_OK, @{"$supplier\::EXPORT_TAGS"};
}

# Set up %EXPORT_TAGS based on whatever we've shoved into @EXPORT, @EXPORT_OK
our %EXPORT_TAGS = (
  helpers => [@EXPORT_OK],
  all => [@EXPORT, @EXPORT_OK],
);
foreach my $supplier (qw(Test::Resub Test::Easy::DataDriven)) {
  no strict 'refs';
  %EXPORT_TAGS = _merge(%EXPORT_TAGS, %{"$supplier\::EXPORT_TAGS"});
}

sub _merge {
  my %out;
  while (my ($k, $v) = splice @_, 0, 2) {
    push @{$out{$k}}, @$v;
  }
  return %out;
}

# code begins here

sub nearly_ok {
  my ($got, $expected, $epsilon, $message) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  Test::More::ok( nearly($got, $expected, $epsilon), $message )
     or warn "expected $got to be $expected +/- $epsilon; actual difference was " . ($expected - $got) . "\n";
}

sub nearly {
  my ($got, $expected, $epsilon) = @_;
  my $close = abs($expected - $got) <= $epsilon;
  return !!$close;
}

sub around_about {
  my ($now, $epsilon) = @_;

  $epsilon ||= 0;

  return Test::Easy::equivalence->new(
    raw  => [$now, $epsilon],
    explain => sub {
      my ($got, $raw) = @_;
      return sprintf '%s within %s seconds of %s', $got, reverse @$raw;
    },
    test => sub {
      my ($got) = @_;
      return time_nearly($got, $now, $epsilon);
    },
  );
}

sub test_sub (&) {
  my $test = shift;
  return sub {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    goto &$test;
  };
}

sub wiretap {
  my ($target, $pre, @args) = @_;
  my $orig = do { no strict 'refs'; *{$target}{CODE} };
  return resub $target, sub {
    $pre->(@_) if $pre;
    $orig->(@_);
  }, @args;
}

1;

__END__

=head1 NAME

Test::Easy - facilitates easy testing patterns

=head1 SYNOPSIS

Easy "x is within an expected range" testing:

    # prove that $got is within $offset of $expected
    use Test::Easy qw(nearly_ok);

    my $got = 1;
    my $expected = 1.25;
    my $offset = .7;
    nearly_ok( $got, $expected, $offset, "$got is within $offset of $expected" );

    # build your own close-approximation tests:
    use Test::Easy qw(nearly);
    ok( nearly(1, 1.25, .7), '1 is within .7 of 1.25' );


Easy tests-in-a-loop:

    use Test::Easy qw(each_ok);
    each_ok { nearly($_, 1.25, .7) } (1, 1.1, .9); # each value is within 1.25 +/- .7


C<deep_ok()> uses L<Data::Difflet> to provide easy understanding of test failures when checking
data structures:

    use Test::Easy qw(deep_ok);
    deep_ok(
        [1, {2 => 4}, 3],
        ['a', {b => '4'}, 'c', 3],
        'this test fails meaningfully'
    );

    __END__
    #   Failed test 'this test fails meaningfully'
    # $GOT
    # @
    #     1
    #     %
    #         2 => 4
    #     3
    # $EXPECTED
    # @
    #     a
    #     %
    #         b => 4
    #     c
    #     3
    # $DIFFLET
    # [
    #   1,   # != a
    #     {
    #       '2' => 4,
    #       'b' => '4',
    #     }
    #   3,   # != c
    #   3,
    # ]

deep_ok() makes it easy to do equivalence testing; here's an example of checking that a given
B<date string> ('Wed Apr 17 19:28:55 2013') is "close enough" to a given B<epoch time> (1366241335).
Spoiler alert: it's just two different representations of the exact same time.

    use Test::Easy qw(around_about);

    sub Production::Code::do_something_expensive {
        my $got = localtime(time);
        sleep 2;
        return (some_datetime => $got);
    }

    my $now = time;
    deep_ok(
        +{Production::Code->do_something_expensive}, # eg: Wed Apr 17 19:28:55 2013
        +{some_datetime => around_about($now, 3)},   # eg: 1366241335-plus-or-minus-3-seconds
        "within 2 seconds of now!"
    );


Easy monkey patching:

    use Test::Easy qw(resub);

    # Within this block, 'Production::Code::do_something_expensive' will sleep 2 seconds
    # and return some static data.
    {
        my $rs = resub 'Production::Code::do_something_expensive', sub {
            sleep 2;
            return (some_datetime => 'Wed Apr 17 19:28:55 2013');
        };

        like( {Production::Code->do_something_expensive}->{some_datetime}, qr/wed apr 17/i );
    }

    # Scope ends, the resub goes away, and your original code is restored.
    unlike( {Production::Code->do_something_expensive}->{some_datetime}, qr/wed apr 17/i );

=head1 DESCRIPTION

I prefer working in a test driven development environment. One of the downsides of having a large
test suite is that test files often grow into monstrosities: it's often easier to plug some new
little testblock into an existing file, or stick some new failing test into the middle of some
mostly unrelated test block - simply because the file or block in question happens to do a lot of
the setup that you need to write.

Another downside is that any interesting system generally has tests that have pretty complicated
setup: you may need to create test records in a database, mock out your network connection, and
monkey patch some expensive functions. Once discovered, these pieces of setup aquire a mystical
quality to them, leading to cargo-cult copy-paste setup in other tests.

Test::Easy doesn't try to prevent you from doing these things. It tries to minimize the pain that
you deal onto your future self. My primary goals in writing this library for myself are:

=over 4

=item * L</"Write Highly Expressive Tests">: C<deep_ok>, C<each_ok>, C<resub>, C<wiretap>, C<time_nearly>

=item * L</"Receive Highly Informative Test Failures">: C<deep_ok>, C<each_ok>

=item * L</"Minimize Manual State Tracking and Resetting">: C<run_where>

=item * L</"Recognize Missing Test Coverage">: C<run_where>

=back

A brief description of each of these functions is provided below. For a more complete description of
each function, view the documentation for the indicated module. As a cautionary note: documentation
drifts; comments lie - but test always tell the truth. If the documentation for a given function is
unclear, consult the relevant tests in the t/ directory included in this module's tarball.

=head1 EXPORTS

Test::Easy re-exports a lot of functionality from various other modules within the Test::Easy ecosystem.

=head2 resub SUBNAME [, CODEREF [, ARGS] ]

Easily monkey-patch SUBNAME to perform CODEREF instead. ARGS, if given, control behavior of the resub
object. When the resub object goes out of lexical scope, its DESTROY method restores the previous bit
of code that was lurking at SUBNAME back in place.

B<resub> objects may be stacked; this is legitimate code:

    use Test::More;
    use Test::Easy qw(resub);

    sub somewhere::foo { 'hi' }

    is( somewhere->foo, 'hi', 'sanity test' );

    {
        my $rs = resub 'somewhere::foo', sub { 'bye' };
        is( somewhere->foo, 'bye' );

        {
            my $rs2 = resub 'somewhere::foo', sub { 'hello there' };
            is( somewhere->foo, 'hello there' );
        }

        is( somewhere->foo, 'bye' );
    }

    is( somewhere->foo, 'hi', 'world is restored to sanity' );

B<resub> knows how to handle subroutines with prototypes without causing errors. If you are monkey-
patching a method in a Moose class which has some 'before', 'around', or 'after' advice applied to
it, the unadorned method will be swapped out for the CODEREF of your choosing - and then the advice
is re-applied around your patched-in code.

See also: L<Test::Resub>

=head2 wiretap SUBNAME [, CODEREF [, ARGS] ]

This is similar to C<resub>, except that instead of *replacing* SUBNAME with CODEREF, instead CODEREF
will be called immediately before SUBNAME is called. This allows you to inspect the arguments coming
in to a given function, while still allowing the function to maintain its real behavior. Note that
your C<wiretap> does not have the ability to prevent the original SUBNAME from being called.

See also: L<Test::Wiretap>

=head2 each_ok BLOCK LIST

Apply the checks in BLOCK across LIST. C<each_ok> is itself your testing function; though BLOCK
may contain individual test assertions, I recommend against doing so: C<each_ok> is an implicit
loop over LIST, which means any test assertion you add within BLOCK will inflate your test count
by one.

Your BLOCK is expected to return either:

=over 4

=item * a single value: its truthines will be tested (i.e. each_ok will act like ok())

=item * two values: they will be treated as $got and $expected, respectively, and will be checked for a match.

See also: L<Test::Easy::DataDriven>.

=back

=head2 run_where LIST, CODEREF

Set up the data structure preconditions specified in LIST, then run CODEREF - which presumably closes over
variables mentioned in LIST.

Each precondition in LIST is an ARRAYREF, and has the form: REFERENCE => $NEW_VALUE_FOR_CODEREF_TO_SEE. Some
examples:

    my $just_a_scalar = 1;
    my $arrayref      = [1..10];
    my $hashref       = {'a'..'f'};
    my $coderef       = sub { 'hi' };

    run_where(
        [\$coderef => sub { 'bye' }],
        [\$hashref => {apple => 'banana'}],
        [\$arrayref => [qw(hi mom)]],
        [\$just_a_scalar => 8843],
        sub {
            $coderef->() . join ',', %$hashref, @$arrayref, $just_a_scalar,
        }
    );

=head2 time_nearly GOT_TIME, EXPECTED_TIME, ALLOWABLE_OFFSET

Check that GOT_TIME is EXPECTED_TIME, +/- ALLOWABLE_OFFSET.

GOT_TIME and EXPECTED_TIME need not be the same types of times. For example, GOT_TIME
can be a date string (Sat Apr 20 05:05:58 2013), whereas EXPECTED_TIME can be an
epoch (1366448758). As long as you have instructed L<Test::Easy::Time> how to handle
your given time format, C<time_nearly> will be able to answer your burning time equivalence
questions.

    ok( time_nearly('Sat Apr 20 05:05:58 2013', 1366448758, 1), "It's within 1 second of the expected epoch" );

Being able to work with expected time values in tests as epoch seconds is handy, because you can easily perform math them.

See C<t/nearly.t>, included with Test::Easy, for how to add a different time format to time_nearly().

See also the code for L<Test::Easy::Time>.

=head2 deep_ok GOT, EXPECTED [, DESCRIPTION]

Check the equality or equivalence of two data structures. This differs from L<Test::Deep> in that L<Test::Deep> supports
a limited set of equivalence objects (re, num, str); deep_ok() allows you to build your own equivalence objects for
handling arbitrary this-looks-enough-like-that testing.

You can do this with deep_ok:

    deep_ok(
        +{beginning_of_time => 'Wed Dec 31 19:00:00 1969'}, # i.e. epochtime = 0
        +{beginning_of_time => around_about(300, 1800)},    # i.e. "epoch 300 is within 1800 seconds of the date above"
    );

Additionally, deep_ok() produces very informative output when things fail to match, for example:

    deep_ok(
        [1, {2 => 4}, 3],
        ['a', {b => '4'}, 'c', 3],
        'this test fails meaningfully'
    );

    __END__
    #   Failed test 'this test fails meaningfully'
    # $GOT
    # @
    #     1
    #     %
    #         2 => 4
    #     3
    # $EXPECTED
    # @
    #     a
    #     %
    #         b => 4
    #     c
    #     3
    # $DIFFLET
    # [
    #   1,   # != a
    #     {
    #       '2' => 4,
    #       'b' => '4',
    #     }
    #   3,   # != c
    #   3,
    # ]

This is not intended to be concise. It is intended to be fully descriptive of the difference between your
got and expected values.

See also: L<Test::Easy::DeepEqual>. For guidance on how to create your own equivalence objects, see the
source for L<Test::Easy> and look for 'sub around_about'.

=head2 deep_equal GOT, EXPECTED

This is the function that does the heavy lifting for deep_ok(). This does all of the checking whether GOT
and EXPECTED are strictly equal (or loosely equivalent, depending on what your EXPECTED looks like). It
simply returns a success or fail value. It does not produce an 'ok' line of TAP output, nor does it produce
any diagnostic output.

See also: L<Test::Easy::DeepEqual>.

=head1 WHAT'S COMING NEXT

Finish documenting the individual functions in more detail in their own modules.

Better deep_ok dumping of equivalence objects that have matched in a failing-match data structure.

Add simple libraries for mocking and stubbing out other classes.

=head1 GOALS

=head2 Write Highly Expressive Tests

Test failure is an expected state within TDD. A well-written failing test is a useful test. A well-spoken
failing test is invaluable. Writing tests well means being able to express a complex thought with minimum
effort.

Consider this bit of code, which does a Schwartzian transform on a list:

    my @files = qw(photo1 video10 photo2 video3 photo12);
    my @temp1 = map { my ($word, $number) = m{^ (\D+) (\d+) $}x; [$1, $2, $_] } @files;
    my @temp2 = sort { $a->[0] cmp $b->[0] || $a->[1] <=> $b->[1] } @temp1;
    my @final = map { $_->[2] } @temp2;

This accomplishes the task of sorting the original list into the order C<qw(photo1 photo2 photo12 video3 video10)>,
but most Perl developers would find it jangly to read. This is a more common expression:

    my @files = qw(photo1 video10 photo2 video3 photo12);

    my @final =
        map { $_->[2] }
        sort { $a->[0] cmp $b->[0] || $a->[1] <=> $b->[1] }
        map { my ($word, $number) = m{^ (\D+) (\d+) $}x; [$1, $2, $_] } @files;

This looks "backwards" to newcomers until one day it does not. The advantage of the second form over the first
is that the first is emphasizing the individual transformations done to the data; the second form expresses
the general pattern of applying a complex sorting function cheaply across a list.

Consider now tests such as this:

    # pretend you actually implemented this for some horrible reason
    sub Your::Production::Code { return qw(photo1 video10 photo2 video3 photo12) }

    # and now you need to test it
    use Test::More tests => 5;
    use Your::Production;

    foreach my $file (Your::Production::Code) {
        my ($word, $number) = $file =~ m{^ (\D+) (\d+) $}x;
        like( $word, m{^ (?: photo | video ) }, "$word is 'photo' or 'video'" );
    }

How many lines of test output will there be? Currently 5 - but once someone adds another item to
Your::Production::Code, then there will be 6, and you'll have testcount failures. Here's an intermediate
improvement:

    use Test::More tests => 1;
    use Your::Production;

    my @bad;
    foreach my file (Your::Production::Code) {
        my ($word, $number) = $file =~ m{^ (\D+) (\d+) $}x;
        push @bad, $word if $word !~ m{^ (?: photo | video ) }x;
    }
    is_deeply( \@bad, [], "All items are either 'photo' or 'video'" );

This is marginally better, but there's a lot of extra data management there. Plus the use of
C<Test::More::is_deeply> only shows us a first failure. Here's a more compact expression of this
test:

    use Test::More tests => 1;
    use Test::Easy qw(each_ok);
    use Your::Production;

    each_ok {
        my ($word, $number) = $file =~ m{^ (\D+) (\d+) $}x;
        $word =~ m{^ (?: photo | video ) }x;
    } Your::Production::Code;

=head2 Receive Highly Informative Test Failures

Until recently, I've never been very satisfied with the state of the art on CPAN for expressing failures
when testing deep data structures. L<Matsuno Tokuhiro|http://metacpan.org/authors/tokuhirom> released
L<Data::Difflet> which produces concise colorized data diffs for arbitrary data structures.

Consequently, instead of seeing this type of failure for this test:

    use Test::More tests => 1;

    is_deeply( [1, 2, 3], [4, 5, 3], 'lists are the same' );

    __END__
    #   Failed test 'lists are the same'
    #     Structures begin differing at:
    #          $got->[0] = '1'
    #     $expected->[0] = '4'

You can instead see this failure:

    use Test::More tests => 1;

    deep_ok( [1, 2, 3], [4, 5, 3], 'lists are the same' );

    __END__
    #   Failed test 'lists are the same'
    #   at (eval 4) line 120.
    # $GOT
    # @
    #     1
    #     2
    #     3
    # $EXPECTED
    # @
    #     4
    #     5
    #     3
    # $DIFFLET
    # [
    #   1,   # != 4
    #   2,   # != 5
    #   3,
    # ]

The $GOT and $EXPECTED representations of your data come from L<Data::Denter>. The $DIFFLET comes from L<Data::Difflet>,
except the $DIFFLET you'll see is actually more meaningful, because it has color.

=head2 Minimize Manual State Tracking and Resetting

Sometimes in the course of a test you'll be tracking and resetting the state of some variables:

    my $foo = 1;
    my $bar = {hello => 'world'};
    is( some_code($foo, $bar), "hello, world", 'got key => value once' );

    $foo = 2;
    is( some_code($foo, $bar), "hello, world\nhello, world", 'got key => value twice' );

    $bar = {};
    is( some_code($foo, $bar), "", 'no data gives empty string' );

    {
        $foo = 0;
        $bar = {goodnight => 'moon'};
        is( some_code($foo, $bar), 'something surprising', "zero count gives 'something surprising'" );
    }

    $foo = undef;
    is( some_code($foo, $bar), undef, 'undefined multiplier gives undef back' );


The inner block, presumably representing some bugfix, exposes every subsequent test to risk: two global
test variables are tweaked but not reset to their previous values. At a minimum, that inner test block
should be written like this:

    {
        my (@original) = ($foo, $bar);
        $foo = 0;
        $bar = {goodnight => 'moon'};
        is( some_code($foo, $bar), 'something surprising', "zero count gives 'something surprising'" );
        ($foo, $bar) = @original;
    }

Another way to write that inner block is like so:

    run_where(
        [\$foo => 0],
        [$bar => {goodnight => 'moon'}],
        sub {
            is( some_code($foo, $bar), 'something surprising', "zero count gives 'something surprising'" );
        }
    );

This becomes particularly handy when some_code() needs to learn about a third argument, perhaps representing
some terminal piece of punctuation. At this point, all tests need to have a third agument, $baz, and the
Cartesian product of variables needs to be accurately represented within the test.

If all of the tests were originally written to track their individual pieces of data, then this whole problem
of "Did I cover all combinations?" becomes easy to answer at a glance:

    my ($foo, $bar) = (undef, {});

    run_where(
        [\$foo => 1],
        [$bar => {hello => 'world'}],
        sub {
            is( some_code($foo, $bar), "hello, world", 'got key => value once' );
        }
    );

    run_where(
        [\$foo => 2],
        [$bar => {hello => 'world'}],
        sub {
            is( some_code($foo, $bar), "hello, world\nhello, world", 'got key => value twice' );
        }
    );

    run_where(
        [\$foo => 2],
        [$bar => {}],
        sub {
            is( some_code($foo, $bar), "", 'no data gives empty string' );
        }
    );

    run_where(
        [\$foo => 0],
        [$bar => {goodnight => 'moon'}],
        sub {
            is( some_code($foo, $bar), 'something surprising', "zero count gives 'something surprising'" );
        }
    );

    run_where(
        [\$foo => undef],
        [$bar => {}],
        sub {
            is( some_code($foo, $bar), undef, 'undefined multiplier gives undef back' );
        },
    );

There's no reason these all need to be expressed as individual tests. You can set up a data structure that
holds each of the precondition clauses for the run_where()s, and which holds the expected output, and then
use C<run_where()> inside an C<each_ok> to reduce all of the above to a more compact form still:

     1      my ($foo, $bar) = (undef, {});
     2
     3      each_ok {
     4          run_where(
     5            @{$_->{preconditions}},
     6            sub { some_code($foo, $bar), $_->{expected_output} }
     7          );
     8      } ({
     9          preconditions => [
    10              [\$foo => 1],
    11              [$bar => {hello => 'world'}],
    12          ],
    13          expected_output => "hello, world",
    14      }, {
    15          preconditions => [
    16              [\$foo => 2],
    17              [$bar => {hello => 'world'}],
    18          ],
    19          expected_output => "hello, world\nhello, world",
    20      }, {
    21          preconditions => [
    22              [\$foo => 2],
    23              [$bar => {}],
    24          ],
    25          expected_output => '',
    26      }, {
    27          preconditions => [
    28              [\$foo => 0],
    29              [$bar => {goodnight => 'moon'}],
    30          ],
    31          expected_output => 'something surprising',
    32      }, {
    33          preconditions => [
    34              [\$foo => undef],
    35              [$bar => {}],
    36          ],
    37          expected_output => undef,
    38      });

Let's break that down a bit:

    Line 1 simply sets up $foo and $bar to default undefined values.

    Lines 3-8 encompass a call to each_ok BLOCK. In order to pass, the return value of each_ok must
              either be a single value (in which case it is checked for truthiness, a-la ok()), or
              it must be a pair of values (in which case they are treated as $got and $expected,
              respectively, and compared using deep_ok().

    Lines 4-7 encompass a run_where(LIST, CODEREF) block. The return value of run_where() is the return
              value of whatever CODEREF you have provided. In this case, the return value will be a
              pair of values: the result of calling some_code($foo, $bar), and the corresponding
              expected piece of output. In Line 5, we expand the preconditions into the LIST of
              conditions that run_where() expects.

    Lines 9-38 are simply data representing the various conditions we are testing, and their
               expected pieces of output.

This is dense, yes. But once I discovered this pattern and explained it to my former team, we found
our tests to be easier to maintain (there's only 1 call to the function; adding support for a third
argument is now dead simple) and faster to read (understand the testing crank that we're going to turn,
then scan the data to make sure nothing looks missing).

=head2 Recognize Missing Test Coverage

Looking at the data structure above, you might notice that this condition is not tested:

          preconditions => [
              [\$foo => undef],
              [$bar => {fly_me => 'to the moon'}],
          ],
          expected_output => ..., # well, what should we expect here? 'something surprising'? undef? croak?

It's very rare that I've rewritten some large state-tracking test to use C<each_ok { run_where ... } ...>
and B<not> discovered some unreached combination of state variables. Once you see what you've missed
testing, it's quite simple to add coverage and either accept what your function does and codify that as
the expected value, or to decide on enforcing different behavior from your function.

=head1 AUTHOR AND COPYRIGHT

    (c) 2013 Belden Lyman <belden@cpan.org>

=head1 CONTRIBUTING

My hope is that other developers who also favor TDD will find these functions useful, and consider
contributing their own. You may fork this project via L<Github|http://github.com/belden/perl-test-easy>,
and submit a pull request in the standard fashion.

=head1 BUGS AND OVERSIGHTS

No bugs are known. There are certainly various oversights within this library. If you discover a bug,
or simply want these functions to behave differently or better, please file a request via this project's
L<issues page|http://github.com/belden/perl-test-easy/issues>.

=head1 SEE ALSO

L<Data::Difflet> does the hard work of comparing two data structures and presenting nice output.

L<Test::Deep> provides useful functions for testing the equality of data structures.

=head1 LICENSE

You may use this under the same terms as Perl itself.
