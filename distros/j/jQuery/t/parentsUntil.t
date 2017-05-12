#!perl
use jQuery;
use FindBin qw($Bin);
use Test::More tests => 1;

my $html = do {
    local $/; 
    open my $fh, '<', $Bin . '/html/parentsUntil.html';
    <$fh>;
};

my $expected = do {
    local $/;
    open my $fh, '<', $Bin . '/expected/parentsUntil.html';
    <$fh>;
};

jQuery->new($html);

jQuery("li.item-a")->parentsUntil(".level-1")
->css("background-color", "red");


jQuery("li.item-2")->parentsUntil( jQuery("ul.level-1"), ".yes" )
  ->css("border", "3px solid green");

my $got = jQuery->as_HTML;

$got =~ s/[\n\s+]//g;
$expected =~ s/[\n\s+]//g;

is($got,$expected);
