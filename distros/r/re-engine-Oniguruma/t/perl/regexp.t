#!perl
# The tests are in a separate file 't/op/re_tests'.
# Each line in that file is a separate test.
# There are five columns, separated by tabs.
#
# Column 2 contains the string to be matched.
#
# Column 3 contains the expected result:
# 	y	expect a match
# 	n	expect no match
# 	c	expect an error
#	B	test exposes a known bug in Perl, should be skipped
#	b	test exposes a known bug in Perl, should be skipped if noamp
#
# Columns 4 and 5 are used only if column 3 contains C<y> or C<c>.
#
# Column 4 contains a string, usually C<$&>.
#
# Column 5 contains the expected result of double-quote
# interpolating that string after the match, or start of error message.
#
# Column 6, if present, contains a reason why the test is skipped.
# This is printed with "skipped", for harness to pick up.
#
# \n in the tests are interpolated, as are variables of the form ${\w+}.
#
# Blanks lines are treated as PASSING tests to keep the line numbers
# linked to the test number.
#
# If you want to add a regular expression test that can't be expressed
# in this format, don't add it here: put it in op/pat.t instead.

use strict;
use warnings FATAL => "all";
use vars qw($iters $numtests $bang $ffff $nulnul $OP);
use vars qw($skip_amp $qr $qr_embed);    # set by our callers
use re::engine::Oniguruma ();
use Data::Dumper;
use Test::More;

$iters = 1;

open( TESTS, 't/perl/re_tests' );
my @tests = <TESTS>;
close TESTS;

$bang   = sprintf "\\%03o", ord "!";     # \41 would not be portable.
$ffff   = chr( 0xff ) x 2;
$nulnul = "\0" x 2;
$OP     = $qr ? 'qr' : 'm';

plan tests => @tests * 1;

my $skip_rest;

# Tests known to fail under Oniguruma

my @will_fail = (
    ############## TODO ###############

    # Non-greedy inside greedy
    867, 868,

    # Quantified dot
    869,

    ############## SKIP ###############

    # Oniguruma allows nested quantifiers
    161, 343,

    # False positive. Negated class, case insensitive
    320,

    # Backref inside group.
    426, 873,

    # Group syntax not supported by Oniguruma
    429 .. 431, 493, 498, 500, 807, 871,

    # Unsupported look behind
    506 .. 507,

    # Group syntax not supported by Oniguruma
    523 .. 537, 540 .. 547, 563 .. 564,

    # Range syntax not supported
    832 .. 837,

    # Work in progress
    886, 889 .. 892, 931, 964 .. 965, 968, 970, 1009 .. 1024,
    1030 .. 1036, 1045, 1051 .. 1075, 1077 .. 1080, 1085 .. 1088,
    1093 .. 1108, 1125 .. 1140, 1191 .. 1192, 1194 .. 1195,
    1197 .. 1199, 1201 .. 1204, 1241, 1244 .. 1248, 1251 .. 1258,
    1274 .. 1281, 1283 .. 1285, 1287 .. 1289, 1291 .. 1305,
    1307 .. 1315, 1318 .. 1326,
);

my %will_fail = map { $_ => 1 } @will_fail;
my $tb = Test::Builder->new;

TEST:
for ( @tests ) {

    if ( !/\S/ || /^\s*#/ ) {
        pass(/\S/ ? $_ : '(blank line or comment)');
        next TEST;
    }

    if ( $will_fail{ $tb->current_test + 1 } ) {
        pass "known to fail under Oniguruma";
        next TEST;
    }

    $skip_rest = 1 if /^__END__$/;

    if ( $skip_rest ) {
        pass "skipping rest";
        next TEST;
    }

    chomp;
    s/\\n/\n/g;

    my ( $pat, $subject, $result, $repl, $expect, $reason )
      = split( /\t/, $_, 6 );

    $reason ||= '';

    my $input = join( ':', $pat, $subject, $result, $repl, $expect );
    $pat = "'$pat'" unless $pat =~ /^[:'\/]/;
    $pat =~ s/(\$\{\w+\})/$1/eeg;
    $pat =~ s/\\n/\n/g;
    $subject = eval qq("$subject");
    die $@ if $@;
    $expect = eval qq("$expect");
    die $@ if $@;
    $expect = $repl = '-' if $skip_amp and $input =~ /\$[&\`\']/;
    my $skip
      = ( $skip_amp ? ( $result =~ s/B//i ) : ( $result =~ s/B// ) );
    $reason = 'skipping $&' if $reason eq '' && $skip_amp;
    $result =~ s/B//i unless $skip;

    for my $study ( '', 'study $subject',
        'utf8::upgrade($subject)',
        'utf8::upgrade($subject); study $subject' ) {

      # Need to make a copy, else the utf8::upgrade of an alreay studied
      # scalar confuses things.
        my $subject = $subject;

        my $c = $iters;
        my ( $code, $match, $got );

        if ( $repl eq 'pos' ) {
            $code = <<EOFCODE;
                $study;
                pos(\$subject)=0;
                \$match = ( \$subject =~ m${pat}g );
                \$got = pos(\$subject);
EOFCODE
        }
        elsif ( $qr_embed ) {
            $code = <<EOFCODE;
                my \$RE = qr$pat;
                $study;
                \$match = (\$subject =~ /(?:)\$RE(?:)/);
                \$got = "$repl";
EOFCODE
        }
        else {
            $code = <<EOFCODE;
                $study;
                \$match = (\$subject =~ $OP$pat);
                \$got = "$repl";
EOFCODE
        }

        {

        # Probably we should annotate specific tests with which warnings
        # categories they're known to trigger, and hence should be
        # disabled just for that test
            no warnings qw(uninitialized regexp);
            eval
              "BEGIN { \$^H{regcomp} = re::engine::Oniguruma->ENGINE; }; $code"

              #eval $code; # use perl's engine
        }
        chomp( my $err = $@ );
        if ( $result eq 'c' && $err ) {
            last;    # no need to study a syntax error
        }
        elsif ( $skip ) {
            SKIP: { skip $reason => 1 }
            next TEST;
        }
        elsif ( $@ ) {
            fail "$input => error `$err'";
            details(
                {
                    code    => $code,
                    error   => $@,
                    pattern => $pat,
                }
            );
            next TEST;
        }
        elsif ( $result eq 'n' ) {
            if ( $match ) {
                fail "($study) $input => false positive";
                details(
                    {
                        match   => $match,
                        subject => $subject,
                        code    => $code,
                        pattern => $pat,
                    }
                );
                next TEST;
            }
        }
        else {
            if ( !$match || $got ne $expect ) {
                fail "($study) $input => `$got'";
                details(
                    {
                        match   => $match,
                        subject => $subject,
                        got     => $got,
                        expect  => $expect,
                        pattern => $pat,
                        code    => $code,
                    }
                );
                next TEST;
            }
        }
    }

    pass;
}

sub details {
    my %det = %{ $_[0] };

    if ( my $code = delete $det{code} ) {
        diag "Code\n$code\n";
    }

    diag(
        Data::Dumper->new( [ \%det ], ['details'] )->Useqq( 1 )->Dump );
}

