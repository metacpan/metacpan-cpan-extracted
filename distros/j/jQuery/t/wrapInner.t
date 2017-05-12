#!perl
use jQuery;
use FindBin qw($Bin);
use Test::More tests => 1;

my $html = do {
    local $/; 
    open my $fh, '<', $Bin . '/html/wrapInner.html';
    <$fh>;
};

my $expected = do {
    local $/;
    open my $fh, '<', $Bin . '/expected/wrapInner.html';
    <$fh>;
};

my $dom = jQuery->new($html);
jQuery->new('<b>another</b>');

my $t = $dom->jQuery("body");
$t->wrapInner("<div><div><p><em><b></b></em></p></div></div>");

my $got = $dom->as_HTML;

$got =~ s/[\n\s+]//g;
$expected =~ s/[\n\s+]//g;

is($got,$expected);
