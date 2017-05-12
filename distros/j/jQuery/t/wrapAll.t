#!perl
use jQuery;
use FindBin qw($Bin);
use Test::More tests => 1;

my $html = do {
    local $/; 
    open my $fh, '<', $Bin . '/html/wrapAll.html';
    <$fh>;
};

my $expected = do {
    local $/;
    open my $fh, '<', $Bin . '/expected/wrapAll.html';
    <$fh>;
};

jQuery->new($html);

jQuery("span")->wrapAll("<div><div><p><em><b></b></em></p></div></div>");

my $got = jQuery->as_HTML;

$got =~ s/[\n\s+]//g;
$expected =~ s/[\n\s+]//g;

is($got,$expected);
