#!perl
use jQuery;
use FindBin qw($Bin);
use Test::More tests => 1;

my $html = do {
    local $/; 
    open my $fh, '<', $Bin . '/html/next.html';
    <$fh>;
};

my $expected = do {
    local $/;
    open my $fh, '<', $Bin . '/expected/next.html';
    <$fh>;
};

jQuery->new($html);

jQuery("#term-2")->nextUntil("dt")
  ->css("background-color", "red");

my $term3 = jQuery->document->getElementById("term-3");

jQuery("#term-1")->nextUntil($term3, "dd")
->css("color", "green");

my $got = jQuery->as_HTML;

$got =~ s/[\n\s+]//g;
$expected =~ s/[\n\s+]//g;

is($got,$expected);
