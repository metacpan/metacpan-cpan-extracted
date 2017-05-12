use strict;
use warnings;
use utf8;
use Test::Base;
use LWP::Online ":skip_all";
use UNIVERSAL::require;
use Data::Dumper;
plan skip_all => "BROKEN";

eval "use CAM::PDF; 1;"; ## no critic.
if ($@) {
    plan skip_all => 'CAM::PDF required for testing pictogram info scraper';
} else {
    plan tests => 4*blocks;
}

filters {
    expected => 'yaml',
};

run {
    my $block = shift;

    my $class = "WWW::MobileCarrierJP::@{[ $block->input ]}::PictogramInfo";
    $class->use or die $@;
    my $dat = $class->scrape;

    is ref($dat), 'ARRAY', $block->input;
    cmp_ok scalar(@$dat), '>', 100;
    my ($row, ) = grep { $block->expected->{unicode} eq $_->{unicode} } @$dat;
    ok $row, "got this unicode";
    is_deeply($row, $block->expected, $block->name) or diag(Dumper($dat));
};

__END__

===
--- input: EZWeb
--- expected
email_jis: 753A
email_sjis: EB59
name: ！
number: 1
sjis: F659
unicode: E481

===
--- input: DoCoMo
--- expected
en_color: Red
en_name: Fine
jp_color: 赤
jp_name: 晴れ
sjis: F89F
unicode: E63E

===
--- input: Softbank
--- expected
unicode: E001

===
--- input: Softbank
--- expected
unicode: E02D

===
--- input: Softbank
--- expected
unicode: E02E

===
--- input: Softbank
--- expected
unicode: E05A

===
--- input: Softbank
--- expected
unicode: E537

