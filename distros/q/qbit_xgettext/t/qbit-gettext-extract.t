use Test::More;
use Test::Differences;

use qbit;

use FindBin qw($Bin);

use QBit::Gettext::Extract;

sub get_po_from_file {
    my ($filename) = @_;
    my $po_data = readfile($filename);
    $po_data =~ s/\$BIN/$Bin/g;

    return $po_data;
}

my $extractor = QBit::Gettext::Extract->new(lang_extensions => {'Lang::MyTemplate' => ['.my.tt2']});

is_deeply(
    $extractor->{'__EXT2LANG__'},
    {
        '.pl'     => 'QBit::Gettext::Extract::Lang::Perl',
        '.pm'     => 'QBit::Gettext::Extract::Lang::Perl',
        '.tt2'    => 'QBit::Gettext::Extract::Lang::TT2',
        '.tpl'    => 'QBit::Gettext::Extract::Lang::TT2',
        '.my.tt2' => 'Lang::MyTemplate',
    },
    'Check merge langs extensions'
);

is(
    $extractor->_get_lang_class_by_filename('/dir/filename.tt2'),
    'QBit::Gettext::Extract::Lang::TT2',
    'Check detect class by extensuin'
  );

is($extractor->_get_lang_class_by_filename('/dir/filename.my.tt2'),
    'Lang::MyTemplate', 'Check detect class by extensuin (matryoshka)');

$extractor = QBit::Gettext::Extract->new();
$extractor->extract_from_file("$Bin/files/file.pl");
eq_or_diff(
    $extractor->po->as_string(),
    get_po_from_file("$Bin/files/perl.pot"),
    "Check generating POT from perl files"
);

$extractor = QBit::Gettext::Extract->new();
$extractor->extract_from_file("$Bin/files/template.tt2");
eq_or_diff(
    $extractor->po->as_string(),
    get_po_from_file("$Bin/files/tt2.pot"),
    "Check generating POT from TT2 files"
);

done_testing;
