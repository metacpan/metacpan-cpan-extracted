use strict;
use warnings;

use Test::More;
use Test::TypeTiny 'ok_subtype';
use Types::Numbers ':all';

use lib 't/lib';
use NumbersTest;

### XXX: Structured fairly similarly to 01-basic.t, but just different enough

my @types = (
    NumRange, IntRange,

    PositiveNum, PositiveOrZeroNum, PositiveInt, PositiveOrZeroInt,
    NegativeNum, NegativeOrZeroNum, NegativeInt, NegativeOrZeroInt,
    SingleDigit,
);

my $pass_types = {
    NumLike  => [qw( pos zero neg int frac digits nan pinf ninf )],
    NumRange => [qw( pos zero neg int frac digits nan pinf ninf )],
    IntRange => [qw( pos zero neg int      digits               )],

    PositiveNum       => [qw( pos          int frac digits     pinf      )],
    PositiveOrZeroNum => [qw( pos zero     int frac digits     pinf      )],
    PositiveInt       => [qw( pos          int      digits               )],
    PositiveOrZeroInt => [qw( pos zero     int      digits               )],
    NegativeNum       => [qw(          neg int frac digits          ninf )],
    NegativeOrZeroNum => [qw(     zero neg int frac digits          ninf )],
    NegativeInt       => [qw(          neg int      digits               )],
    NegativeOrZeroInt => [qw(     zero neg int      digits               )],
    SingleDigit       => [qw( pos zero neg int                           )],
};

my $supertypes = {
    NumLike  => [Types::Standard::Item, Types::Standard::Defined],
};
$supertypes = {
    %$supertypes,
    NumRange => [@{$supertypes->{'NumLike'}}, NumLike],
};
$supertypes = {
    %$supertypes,
    IntLike  => $supertypes->{'NumRange'},
};
$supertypes = {
    %$supertypes,
    IntRange => [@{$supertypes->{'IntLike'}}, IntLike],
};
$supertypes = {
    %$supertypes,
    PositiveNum       => [@{$supertypes->{'NumRange'}}, NumRange],
    PositiveOrZeroNum => [@{$supertypes->{'NumRange'}}, NumRange],
    PositiveInt       => [@{$supertypes->{'IntRange'}}, IntRange],
    PositiveOrZeroInt => [@{$supertypes->{'IntRange'}}, IntRange],
    NegativeNum       => [@{$supertypes->{'NumRange'}}, NumRange],
    NegativeOrZeroNum => [@{$supertypes->{'NumRange'}}, NumRange],
    NegativeInt       => [@{$supertypes->{'IntRange'}}, IntRange],
    NegativeOrZeroInt => [@{$supertypes->{'IntRange'}}, IntRange],
    SingleDigit       => [@{$supertypes->{'IntRange'}}, IntRange],
};

plan tests => scalar(@types);

foreach my $type (@types) {
    my $name = $type->name;
    my $is_pass;

    my $should_pass = {
        (map { $_ => 0 } @{ $pass_types->{'NumLike'} }),  # start with all zeros (since NumLike has all types)
        (map { $_ => 1 } @{ $pass_types->{$name}     })   # fill in the right ones with ones
    };

    subtest $name => sub {
        plan tests => scalar(@{$supertypes->{$name}}) + 50;
        note explain {
            name   => $name,
            inline => $type->inline_check('$num'),
        };

        foreach my $supertype (@{$supertypes->{$name}}) {
            ok_subtype($supertype, $type) ||
                diag join(', ', map { $_->name.($_->name eq $_->display_name ? '' : ' ('.$_->display_name.')') } ($type, $type->parents));
        }

        # No strings or undef
        numbers_test(undef, $type, 0);
        numbers_test('ABC', $type, 0);

        # NaN/INF
        $is_pass = $should_pass->{nan};
        numbers_test( $nan, $type, $is_pass);
        SKIP: {
            skip "Math::BigInt/Float NaN comparisons are buggy in older versions", 2 if $Math::BigInt::VERSION < 1.999710 && $name eq 'PositiveNum';
            numbers_test($Inan, $type, $is_pass);
            numbers_test($Fnan, $type, $is_pass);
        }

        $is_pass = $should_pass->{pinf};
        numbers_test( $pinf, $type, $is_pass);
        numbers_test($Ipinf, $type, $is_pass);
        numbers_test($Fpinf, $type, $is_pass);

        $is_pass = $should_pass->{ninf};
        numbers_test( $ninf, $type, $is_pass);
        numbers_test($Ininf, $type, $is_pass);
        numbers_test($Fninf, $type, $is_pass);

        # Positive integers
        $is_pass = $should_pass->{pos} && $should_pass->{int};
        numbers_test(      1, $type, $is_pass);
        numbers_test($bigtwo, $type, $is_pass);
        numbers_test(    $I1, $type, $is_pass);
        numbers_test(    $F1, $type, $is_pass);

        $is_pass = $should_pass->{pos} && $should_pass->{int} && $should_pass->{digits};
        numbers_test(     10, $type, $is_pass);
        numbers_test( 12_345, $type, $is_pass);
        numbers_test(_SAFE_NUM_MAX, $type, $is_pass);
        numbers_test($bigten, $type, $is_pass);
        numbers_test(  $IMAX, $type, $is_pass);
        numbers_test(  $FMAX, $type, $is_pass);

        # Positive fractionals
        $is_pass = $should_pass->{pos} && $should_pass->{frac};
        numbers_test(    0.5, $type, $is_pass);
        numbers_test(   25/3, $type, $is_pass);
        numbers_test(   $F05, $type, $is_pass);
        numbers_test(   $F15, $type, $is_pass);

        $is_pass = $should_pass->{pos} && $should_pass->{frac} && $should_pass->{digits};
        numbers_test(   10.5, $type, $is_pass);
        numbers_test( 123.45, $type, $is_pass);
        numbers_test($FMAX + 10.5, $type, $is_pass);

        # Zero
        $is_pass = $should_pass->{zero};
        numbers_test(  0, $type, $is_pass);
        numbers_test($I0, $type, $is_pass);
        numbers_test($F0, $type, $is_pass);

        # Negative integers
        $is_pass = $should_pass->{neg} && $should_pass->{int};
        numbers_test(      -1, $type, $is_pass);
        numbers_test(-$bigtwo, $type, $is_pass);
        numbers_test(    $I_1, $type, $is_pass);
        numbers_test(    $F_1, $type, $is_pass);

        $is_pass = $should_pass->{neg} && $should_pass->{int} && $should_pass->{digits};
        numbers_test(     -10, $type, $is_pass);
        numbers_test( -12_345, $type, $is_pass);
        numbers_test(_SAFE_NUM_MIN, $type, $is_pass);
        numbers_test(-$bigten, $type, $is_pass);
        numbers_test(   $IMIN, $type, $is_pass);
        numbers_test(   $FMIN, $type, $is_pass);
        numbers_test(  -$IMAX, $type, $is_pass);
        numbers_test(  -$FMAX, $type, $is_pass);

        # Negative fractionals
        $is_pass = $should_pass->{neg} && $should_pass->{frac};
        numbers_test(   -0.5, $type, $is_pass);
        numbers_test(  -25/3, $type, $is_pass);
        numbers_test(  -$F05, $type, $is_pass);
        numbers_test(  $F_25, $type, $is_pass);

        $is_pass = $should_pass->{neg} && $should_pass->{frac} && $should_pass->{digits};
        numbers_test(  -10.5, $type, $is_pass);
        numbers_test(-123.45, $type, $is_pass);
        numbers_test($FMIN - 10.5, $type, $is_pass);
    };
}

done_testing;
