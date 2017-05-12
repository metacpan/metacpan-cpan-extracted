#!/usr/bin/perl -w
BEGIN { $ENV{WXPERL_OPTIONS} = 'NO_MAC_SETFRONTPROCESS'; }
use strict;
use Test::More tests => 4;
use Wx;
use Wx::PdfDocument;
use Wx qw( :font );

my $printdata = Wx::PrintData->new();
$printdata->SetPaperId(Wx::wxPAPER_A4());
my $pdc = Wx::PdfDC->new($printdata);
$pdc->SetFont(wxSWISS_FONT);
$pdc->StartDoc("unused text");
TODO: {
    local $TODO = 'currenty failing on 64 bit platforms';

    my($w,$h,$d,$e) = $pdc->GetTextExtent('The Cat Sat On The Mat');
    ok($w, 'GetTextExtent Width');
    ok($h, 'GetTextExtent Height');
    ok(defined($d), 'GetTextExtent Descent');
    ok(defined($e), 'GetTextExtent External Leading');
};

