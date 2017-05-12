#!perl

# This is a sandbox for experiments with referencing and dereferencing.
# It is not part of a test suite, not even an "author" test suite.

use strict;
use warnings;

use Scalar::Util qw(reftype weaken);
use Data::Dumper;
use Carp;
use English qw( -no_match_vars );
use Fatal qw(open);

sub try_dumper {
    my $probe_ref = shift;

    my @warnings = ();
    local $SIG{__WARN__} = sub { push @warnings, $_[0]; };
    printf {*STDERR} 'Dumper: %s', Data::Dumper::Dumper( ${$probe_ref} )
        or Carp::croak("Cannot print to STDERR: $ERRNO");
    for my $warning (@warnings) {
        print {*STDERR} "Dumper warning: $warning"
            or Carp::croak("Cannot print to STDERR: $ERRNO");
    }
    return scalar @warnings;
}

my $array_ref = \@{ [qw(42)] };
my $hash_ref   = { a => 1, b => 2 };
my $scalar_ref = \42;
my $ref_ref    = \$scalar_ref;
my $regexp_ref = qr/./xms;

## no critic (Subroutines::ProhibitCallsToUndeclaredSubs)
my $vstring_ref = \(v1.2.3.4);
## use critic

my $code_ref = \&try_dumper;

## no critic (Miscellanea::ProhibitFormats,References::ProhibitDoubleSigils,Subroutines::ProhibitCallsToUndeclaredSubs)
format fmt =
@<<<<<<<<<<<<<<<
$_
.
## use critic

## no critic (Subroutines::ProhibitCallsToUndeclaredSubs)
my $format_ref = *fmt{FORMAT};
my $glob_ref   = *STDOUT{GLOB};
my $io_ref     = *STDOUT{IO};
my $fh_ref     = do {
    no warnings qw(deprecated);
    *STDOUT{FILEHANDLE};
};
## use critic

## no critic (InputOutput::RequireBriefOpen)
open my $autoviv_ref, q{>&STDERR};
## use critic

my $string     = 'abc' x 40;
my $lvalue_ref = \( pos $string );
${$lvalue_ref} = 7;

my %data = (
    'scalar'  => $scalar_ref,
    'array'   => $array_ref,
    'hash'    => $hash_ref,
    'ref'     => $ref_ref,
    'code'    => $code_ref,
    'regexp'  => $regexp_ref,
    'vstring' => $vstring_ref,
    'format'  => $format_ref,
    'glob'    => $glob_ref,
    'io'      => $io_ref,
    'fh'      => $fh_ref,
    'autoviv' => $autoviv_ref,
    'lvalue'  => $lvalue_ref,
);

REF:
while ( my ( $name, $ref ) = each %data ) {
    printf {*STDERR} "==== $name, %s, %s ====\n", ( ref $ref ),
        ( reftype $ref)
        or Carp::croak("Cannot print to STDERR: $ERRNO");
    try_dumper( \$ref );
}

REF:
for my $data_name (qw(scalar vstring regexp ref )) {
    my $ref = $data{$data_name};
    printf {*STDERR} "=== Deref test $data_name, %s, %s ===\n", ( ref $ref ),
        ( reftype $ref )
        or Carp::croak("Cannot print to STDERR: $ERRNO");
    my $old_probe = \$ref;
    try_dumper($old_probe);
    my $new_probe = \${ ${$old_probe} };
    try_dumper($new_probe);
}

REF: for my $ref ($format_ref) {
    my $probe = \$ref;
    print {*STDERR} 'Trying to deref ', ( ref $probe ), q{ }, ( ref $ref ),
        "\n"
        or Carp::croak("Cannot print to STDERR: $ERRNO");
    try_dumper($probe);

    # How to dereference ?
}

REF: for my $ref ($lvalue_ref) {
    my $probe = \$ref;
    print {*STDERR} 'Trying to deref ', ( ref $probe ), q{ }, ( ref $ref ),
        "\n"
        or Carp::croak("Cannot print to STDERR: $ERRNO");
    try_dumper($probe);
    my $new_probe = \${ ${$probe} };
    printf {*STDERR} "pos is %d\n", ${$lvalue_ref};
    ${$lvalue_ref} = 11;
    printf {*STDERR} "pos is %d\n", ${$lvalue_ref};
}

REF: for my $ref ($io_ref) {
    my $probe = \$ref;
    print {*STDERR} 'Trying to deref ', ( ref $probe ), q{ }, ( ref $ref ),
        "\n"
        or Carp::croak("Cannot print to STDERR: $ERRNO");
    try_dumper($probe);
    my $new_probe = \*{ ${$probe} };
    print { ${$new_probe} } "Printing via IO ref\n"
        or Carp::croak("Cannot print via IO ref: $ERRNO");
}

REF: for my $ref ($fh_ref) {
    my $probe = \$ref;
    print {*STDERR} 'Trying to deref ', ( ref $probe ), q{ }, ( ref $ref ),
        "\n"
        or Carp::croak("Cannot print to STDERR: $ERRNO");
    try_dumper($probe);
    my $new_probe = \*{ ${$probe} };
    print { ${$new_probe} } "Printing via FH ref\n"
        or Carp::croak("Cannot print via FH ref: $ERRNO");
}

REF: for my $ref ($glob_ref) {
    my $probe = \$ref;
    print 'Trying to deref ', ( ref $probe ), q{ }, ( ref $ref ), "\n"
        or Carp::croak("Cannot print to STDERR: $ERRNO");
    try_dumper($probe);
    my $new_probe = \*{ ${$probe} };
    print { ${$new_probe} } "Printing via GLOB ref\n"
        or Carp::croak("Cannot print via GLOB ref: $ERRNO");
}

REF:
for my $data_name (qw( glob autoviv )) {
    my $ref = $data{$data_name};
    printf {*STDERR} "=== Deref test $data_name, %s, %s ===\n", ( ref $ref ),
        ( reftype $ref )
        or Carp::croak("Cannot print to STDERR: $ERRNO");
    my $old_probe = \$ref;
    try_dumper($old_probe);
    my $new_probe = \*{ ${$old_probe} };
    print { ${$new_probe} } "Printing via $data_name ref\n"
        or Carp::croak("Cannot print via $data_name ref: $ERRNO");
    try_dumper($new_probe);
}

REF:
while ( my ( $name, $ref ) = each %data ) {
    my $ref_value     = ref $ref;
    my $reftype_value = reftype $ref;
    printf
        "==== scalar ref test of $name, ref=$ref_value, reftype=$reftype_value\n"
        or Carp::croak("Cannot print to STDERR: $ERRNO");
    my $eval_result = eval { my $deref = ${$ref}; 1 };
    if ( defined $eval_result ) {
        print "scalar deref of $reftype_value ok\n"
            or Carp::croak("Cannot print to STDOUT: $ERRNO");
    }
    else {
        print "scalar deref of $reftype_value failed: $EVAL_ERROR"
            or Carp::croak("Cannot print to STDOUT: $ERRNO");
    }
} ## end while ( my ( $name, $ref ) = each %data )
