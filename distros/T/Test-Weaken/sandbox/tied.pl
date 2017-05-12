#!/usr/bin/perl

use strict;
use warnings;
use Fatal qw(open read);
use Symbol;
use Data::Dumper;
use Scalar::Util;
use IO::File;
use English qw( -no_match_vars );
use Carp;

## no critic (Miscellanea::ProhibitTies)

package MyTiedFileHandle;

use English qw( -no_match_vars );
use Carp;

my $leaky_file_handle;

sub TIEHANDLE {
    my ($class) = @_;
    my $i;
    my $tied_object = bless \$i, $class;
    $leaky_file_handle = $tied_object;
    return $tied_object;
} ## end sub TIEHANDLE

sub PRINT {
    my ( $r, @rest ) = @_;
    ${$r}++;
    print join( $OFS, map { uc $_ } @rest ), $ORS
        or Carp::croak("Cannot print to STDOUT: $ERRNO");
    return;
} ## end sub PRINT

## no critic (Subroutines::RequireArgUnpacking)
sub READ {
    my $bufref = \$_[1];

## use critic
## no critic (Miscellanea::ProhibitTies)

    my ( $self, undef, $len, $offset ) = @_;
    defined $offset or $offset = 0;
    ${$bufref} .= 'a';
    return 1;
} ## end sub READ

package MyTie;

my $leaky;

sub TIESCALAR {
    my ($class) = @_;
    my $tobj = bless {}, $class;
    $leaky = $tobj;
    return $tobj;
} ## end sub TIESCALAR

sub TIEHASH {
    goto \&TIESCALAR;
}

sub FIRSTKEY {
    return;    # no keys
}

sub TIEARRAY {
    goto \&TIESCALAR;
}

sub FETCH {return}

sub FETCHSIZE {
    return 0;    # no array elements
}

sub TIEHANDLE {
    goto \&TIESCALAR;
}

package main;

my $scalar     = 42;
my $scalar_ref = \$scalar;
my $ref_ref    = \$scalar_ref;
my $regexp_ref = qr/./xms;

## no critic (Subroutines::ProhibitCallsToUndeclaredSubs)
my $vstring = v1.2.3.4;
## use critic
my $vstring_ref = \$vstring;

our $GLOB_HANDLE_NAME;
our $IO_HANDLE_NAME;
our $AUTOVIV_HANDLE_NAME;
our $FH_HANDLE_NAME;

my $glob_ref = *GLOB_HANDLE_NAME{'GLOB'};
my $io_ref   = *IO_HANDLE_NAME{'IO'};
my $fh_ref   = do {
    no warnings qw(deprecated);
    *FH_HANDLE_NAME{'FILEHANDLE'};
};

## no critic (InputOutput::RequireBriefOpen)
open my $autoviv_ref, q{<}, '/dev/null';
## use critic

my $string     = 'abc' x 40;
my $lvalue_ref = \( pos $string );
${$lvalue_ref} = 7;

my %data = (
    'scalar'  => $scalar_ref,
    'ref'     => $ref_ref,
    'regexp'  => $regexp_ref,
    'vstring' => $vstring_ref,
    'lvalue'  => $lvalue_ref,
    'glob'    => $glob_ref,
    'autoviv' => $autoviv_ref,
);

my %star_deref = map { ( $_, 1 ) } qw(glob autoviv);

REF:
while ( my ( $name, $ref ) = each %data ) {
    print "$name: ", ( ref $ref ), q{,}, ( Scalar::Util::reftype $ref), q{: }
        or Carp::croak("Cannot print to STDOUT: $ERRNO");
    my $return;
    if ( $star_deref{$name} ) {
        ## no critic (Miscellanea::ProhibitTies)
        $return = eval { tie *{$ref}, 'MyTiedFileHandle'; 1 };
        ## use critic
    }
    else {
        ## no critic (Miscellanea::ProhibitTies)
        $return = eval { tie ${$ref}, 'MyTie'; 1 };
        ## use critic
    }
    print $return ? "ok\n" : "tie failed: $EVAL_ERROR"
        or Carp::croak("Cannot print to STDOUT: $ERRNO");
    my $underlying = q{};
    if ( $star_deref{$name} ) {
        $underlying = tied *{$ref};
    }
    else {
        $underlying = tied ${$ref};
    }
    print Data::Dumper->Dump( [$underlying], ['underlying'] )
        or Carp::croak("Cannot print to STDOUT: $ERRNO");
} ## end while ( my ( $name, $ref ) = each %data )

exit 0;
