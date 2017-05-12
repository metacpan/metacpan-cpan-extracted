#!perl
use jQuery;
use FindBin qw($Bin);
use Test::More tests => 1;

my $html = do {
    local $/; 
    open my $fh, '<', $Bin . '/html/prevUntil.html';
    <$fh>;
};

my $expected = do {
    local $/;
    open my $fh, '<', $Bin . '/expected/prevUntil.html';
    <$fh>;
};

jQuery->new($html);

jQuery("#term-2")->prevUntil("dt")
  ->css("background-color", "red");
  
my $term1 = jQuery->document->getElementById('term-1');

jQuery("#term-3")->prevUntil($term1, "dd")
->css("color", "green");

my $got = jQuery->as_HTML;

$got =~ s/[\n\s+]//g;
$expected =~ s/[\n\s+]//g;

is($got,$expected);
