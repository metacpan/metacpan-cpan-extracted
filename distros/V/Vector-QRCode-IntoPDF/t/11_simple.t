use strict;
use utf8;
use Test::More;
use Vector::QRCode::IntoPDF;
use File::Spec;
use File::Temp 'tempdir';

my $tmpdir = tempdir(CLEANUP => 1);
my $src_pdf_file = File::Spec->catfile(qw/t data dummy.pdf/);
my $dst_pdf_file = File::Spec->catfile($tmpdir, 'result.pdf');
my $expect_pdf_file = File::Spec->catfile(qw/t data expected.pdf/);

my $obj = Vector::QRCode::IntoPDF->new(pdf_file => $src_pdf_file);

isa_ok $obj->pdf, 'PDF::API2';

$obj->imprint(
    page => 1,
    x    => 213,
    y    => 250,
    text => '退学失敗',
    size => 6,
    unit => 'cm',
);

$obj->save($dst_pdf_file);

open my $fh, '<', $dst_pdf_file or die $!;
my $pdf_data = do{local $/; <$fh>};
close $fh;

open $fh, '<', $expect_pdf_file or die $!;
my $expect_bin = do{local $/; <$fh>};
close $fh;

is $pdf_data, $expect_bin;

done_testing;
