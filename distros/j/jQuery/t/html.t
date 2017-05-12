#!perl
use jQuery;
use FindBin qw($Bin);
use Test::More tests => 1;

my $html = do {
    local $/; 
    open my $fh, '<', $Bin . '/html/html.html';
    <$fh>;
};

my $expected = do {
    local $/;
    open my $fh, '<', $Bin . '/expected/html.html';
    <$fh>;
};

jQuery->new($html);

jQuery("div")->html('<b>Wow!</b> Such excitement...');

jQuery("div b")
->append(jQuery->document->createTextNode("!!!"))
->css("color", "red");

my $got = jQuery->as_HTML;

$got =~ s/[\n\s+]//g;
$expected =~ s/[\n\s+]//g;

is($got,$expected);
