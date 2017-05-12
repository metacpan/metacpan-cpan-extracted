#!/usr/bin/perl

# Test cases provided by Kevin Ryde,
# most with only minor changes.

use strict;
use warnings;
use Test::Weaken;
use Test::More tests => 5;
use Fatal qw(open read);
use Symbol;

## no critic (Miscellanea::ProhibitTies)

package MyTiedFileHandle;

my $leaky_file_handle;

sub TIEHANDLE {
    my ($class) = @_;
    my $i;
    my $tied_object = bless \$i, $class;
    $leaky_file_handle = $tied_object;
    return $tied_object;
} ## end sub TIEHANDLE

## no critic (Subroutines::RequireArgUnpacking)
sub READ {
    my $bufref = \$_[1];

## use critic

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

sub FETCHSIZE {
    return 0;    # no array elements
}

sub TIEHANDLE {
    goto \&TIESCALAR;
}

package main;

{
    my $test = Test::Weaken::leaks(
        sub {
            my $var;
            tie $var, 'MyTie';
            return \$var;
        }
    );
    my $unfreed_count = $test ? $test->unfreed_count() : 0;
    Test::More::is( $unfreed_count, 1, 'caught unfreed tied scalar' );
}

{
    my $test = Test::Weaken::leaks(
        sub {
            my %var;
            tie %var, 'MyTie';
            return \%var;
        }
    );
    my $unfreed_count = $test ? $test->unfreed_count() : 0;
    Test::More::is( $unfreed_count, 1, 'caught unfreed tied hash' );
}

{
    my $test = Test::Weaken::leaks(
        sub {
            my @var;
            tie @var, 'MyTie';
            return \@var;
        }
    );
    my $unfreed_count = $test ? $test->unfreed_count() : 0;
    Test::More::is( $unfreed_count, 1, 'caught unfreed tied array' );
}

{
    my $test = Test::Weaken::leaks(
        {   constructor => sub {
                our $FILEHANDLE;
                my $fh = *FILEHANDLE{'GLOB'};
                tie ${$fh}, 'MyTiedFileHandle';
                my $read;
                read $fh, $read, 1;
                if ( $read ne 'a' ) {
                    Carp::croak('Problem with tied file handle');
                }
                return $fh;
            },
        }
    );
    my $unfreed_count = $test ? $test->unfreed_count() : 0;
    my $unfreed_reftypes = q{};
    if ($test) {
        my $unfreed = $test->unfreed_proberefs;
        $unfreed_reftypes = ( join q{ }, sort map { ref $_ } @{$unfreed} );
    }
    Test::More::is( $unfreed_count, 1, 'caught unfreed tied file handle' );
    Test::More::is( $unfreed_reftypes, 'MyTiedFileHandle',
        'matched unfreed refs from tied file handle' );
}

exit 0;
