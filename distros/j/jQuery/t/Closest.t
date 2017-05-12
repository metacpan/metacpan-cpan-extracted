#!perl
use jQuery;
use FindBin qw($Bin);
use Test::More tests => 1;

my $html = do {
    local $/; 
    open my $fh, '<', $Bin . '/html/Closest.html';
    <$fh>;
};

my $expected = do {
    local $/;
    open my $fh, '<', $Bin . '/expected/Closest.html';
    <$fh>;
};

jQuery->new($html);

my $listElements = jQuery("li")->css("color", "blue");

jQuery( 'b' )->each( sub {
    jQuery(this)->closest($listElements)->toggleClass("hilight");
});

my $got = jQuery->as_HTML;

$got =~ s/[\n\s+]//g;
$expected =~ s/[\n\s+]//g;

is($got,$expected);
