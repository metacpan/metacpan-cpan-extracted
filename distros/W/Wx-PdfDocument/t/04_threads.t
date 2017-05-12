#!/usr/bin/perl
BEGIN { $ENV{WXPERL_OPTIONS} = 'NO_MAC_SETFRONTPROCESS'; }
use strict;
use Config;
use if !$Config{useithreads} => 'Test::More' => skip_all => 'no threads';
use threads;
use Wx;
use if !Wx::wxTHREADS, 'Test::More' => skip_all => 'No thread support';
use Wx::PdfDocument;
use Wx qw(:pdfdocument);
use Wx::Print;

use Test::More tests => 4;

package main;

my $app = Wx::App->new( sub { 1 } );

my @keeps;
my @undef;

my $printdata = Wx::PrintData->new();
$printdata->SetPaperId(Wx::wxPAPER_A4());

push @keeps, Wx::PdfDC->new($printdata);
push @undef, Wx::PdfDC->new($printdata);

push @keeps, Wx::PlPdfDocument->new();
push @undef, Wx::PlPdfDocument->new();

push @keeps, Wx::PlPdfDocument->new()->GetCurrentFont;
push @undef, Wx::PlPdfDocument->new()->GetCurrentFont;

push @keeps, Wx::PdfColour->new(Wx::Colour->new(10,10,10));
push @undef, Wx::PdfColour->new(100,100,100);

push @keeps, Wx::PdfFontDescription->new();
push @undef, Wx::PdfFontDescription->new(Wx::PdfFontDescription->new());

push @keeps, Wx::PdfInfo->new();
push @undef, Wx::PdfInfo->new();

push @keeps, Wx::PdfLayer->new('First');
push @undef, Wx::PdfLayer->new('Second');

push @keeps, Wx::PdfOcg->new();
push @undef, Wx::PdfOcg->new();

push @keeps, Wx::PdfLayerMembership->new();
push @undef, Wx::PdfLayerMembership->new();

push @keeps, Wx::PdfLayerGroup->new();
push @undef, Wx::PdfLayerGroup->new();

push @keeps, Wx::PdfShape->new();
push @undef, Wx::PdfShape->new();

push @keeps, Wx::PdfLineStyle->new();
push @undef, Wx::PdfLineStyle->new(Wx::PdfLineStyle->new());

push @keeps, Wx::PdfLink->new('http://wxperl.sourceforge.net');
push @undef, Wx::PdfLink->new('http://wxperl.sourceforge.net');

push @keeps, Wx::PdfPageLink->new(10,10,10,10,Wx::PdfLink->new('http://wxperl.sourceforge.net'));
push @undef, Wx::PdfPageLink->new(10,10,10,10,Wx::PdfLink->new('http://wxperl.sourceforge.net'));

push @keeps, Wx::PdfBarCodeCreator->new(Wx::PlPdfDocument->new());
push @undef, Wx::PdfBarCodeCreator->new(Wx::PlPdfDocument->new());

while ( my $item = pop( @undef ) ) {
      undef $item;
}
undef @undef;

my $t = threads->create
  ( sub {
        ok( 1, 'In thread' );
    } );
ok( 1, 'Before join' );
$t->join;
ok( 1, 'After join' );

END { ok( 1, 'At END' ) };
