#!/usr/bin/perl -w
#
# A quick test to see which methods are quickest.  This is not terribly
# realistic as it throws away all output.
#
# @(#) $Id: benchmark.pl 477 2005-02-18 10:10:55Z dom $
#

use strict;
use warnings;

use Benchmark qw( cmpthese );
use File::Spec;
use XML::Genx::Simple;

# Set up some shared variables.
my $devnull = File::Spec->devnull;
open my $nullfh, '>', $devnull
    or die "open(>$devnull): $!\n";

my $genx = XML::Genx::Simple->new;
my $xml_output = '';

cmpthese(
    100_000,
    {
        'StartDocFile()'   => \&StartDocFile,
        'StartDocSender()' => \&StartDocSender,
        'StartDocString()' => \&StartDocString,
    }
);

sub StartDocSender {
    $xml_output = '';
    $genx->StartDocSender( sub { $xml_output .= shift } );
    $genx->StartElementLiteral( 'foo' );
    $genx->AddText( 'bar' );
    $genx->EndElement;
    $genx->EndDocument;
}

sub StartDocFile {
    $genx->StartDocFile( $nullfh );
    $genx->StartElementLiteral( 'foo' );
    $genx->AddText( 'bar' );
    $genx->EndElement;
    $genx->EndDocument;
}

sub StartDocString {
    $genx->StartDocString();
    $genx->StartElementLiteral( 'foo' );
    $genx->AddText( 'bar' );
    $genx->EndElement;
    $genx->EndDocument;
}

# vim: set ai et sw=4 syntax=perl :
