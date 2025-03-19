package  # hide from PAUSE
    StrTest;

use Test2::Tools::TypeTiny;

use Test2::API            qw< intercept >;
use Test2::Tools::Basic;
use Test2::Tools::Compare qw< is like >;
use Test2::Tools::Subtest qw< subtest_buffered >;

use Types::Standard qw< StrMatch Num Enum Tuple Ref >;

use List::Util   qw< first >;
use Scalar::Util qw< blessed >;

###################################################################################################

# Example type test
sub string_test {
    my ($include_intentional_failures) = @_;

    type_subtest StrMatch[qr/^(\S+) (\S+)$/, Tuple[Num, Enum[qw< mm cm m km >]]], sub {
        my $type = shift;

        my @pass_list = (
            '1 km',
            '-1.6 cm',
            '+1.6 m',
        );
        my @fail_list = (
            'xyz km',
            '7 miles',
            '7 km    ',
        );

        should_pass_initially($type, @pass_list);
        should_fail_initially($type, @fail_list);
        should_pass($type, @pass_list);
        should_fail($type, @fail_list);

        should_sort_into(
            $type,
            [qw< aaa bbb qqq rrr sss ttt >],
        );

        # Intentional failures
        if ($include_intentional_failures) {
            should_pass($type, @fail_list);   # XXX: exact line number captured in subtest-events.t
            should_fail($type, @pass_list);
        }
    };

    # Fully passes
    my $enum_type = Enum[\1, qw< FOO BAR BAZ >];
    type_subtest $enum_type, sub {
        my $type = shift;

        should_pass_initially(
            $type,
            qw< FOO BAR BAZ >,
        );
        should_fail_initially(
            $type,
            qw< foo bar baz f b 0 1 2 3 XYZ >,
        );
        should_pass(
            $type,
            qw< FOO BAR BAZ foo f ba baz 0 1 2 -1 >,
        );
        should_fail(
            $type,
            undef, sub {}, \'string', qw< XYZ 3 4 5 6 -99 >,
        );
        should_coerce_into(
            $type,
            qw<
                foo   FOO
                f     FOO
                ba    BAR
                baz   BAZ
                0     FOO
                1     BAR
                2     BAZ
                -1    BAZ
            >,
        );
    };

    # Coercion failures
    type_subtest $enum_type, sub {
        my $type = shift;

        should_coerce_into(   # XXX: exact line number captured in subtest-events.t
            $type,
            $include_intentional_failures ? (
                # NOTE: Bad coercions, but will produce known failures.  Also, undef/'' should be different to
                # validate that the checks are not getting merged together (previous bug).
                undef,  '',
                '',     'blank',
                qw<
                    foo   FOO
                    f     FOO
                    XYZ   XYZ
                    -99   FOO
                    q     BAR
                >,
            ) : (
                qw<
                    foo   FOO
                    f     FOO
                >,
            )
        );
    };

    # Unparameterized tests
    type_subtest Ref, sub {
        my $type = shift;

        parameters_should_create_type(
            $type,
            map { [$_] } qw< SCALAR ARRAY HASH CODE REF GLOB LVALUE FORMAT IO VSTRING REGEXP Regexp >,
        );
        parameters_should_die_as(
            $type,
            [{}],    qr<Parameter to Ref\[\`a\] expected to be a Perl ref type; got HASH>,
            ['FOO'], qr<Parameter to Ref\[\`a\] expected to be a Perl ref type; got FOO>,
        );

        message_should_report_as(
            $type,
            undef, qr<Undef did not pass type constraint "Ref">,
        );
        explanation_should_report_as(
            $type,
            undef, [
                qr<^"Ref.*" is a subtype of "Defined">,
                qr<^Undef did not pass type constraint "Defined">,
                qr<^"Defined" is defined as:>,
            ],
        );
    };

    done_testing;
}

1;
