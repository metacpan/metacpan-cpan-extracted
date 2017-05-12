#!perl
use jQuery;
use FindBin qw($Bin);
use Test::More tests => 1;

my $html = do {
    local $/; 
    open my $fh, '<', $Bin . '/html/Children.html';
    <$fh>;
};

my $expected = do {
    local $/;
    open my $fh, '<', $Bin . '/expected/Children.html';
    <$fh>;
};

jQuery->new($html);

jQuery("div")->children()->css("border-bottom", "3px double red");

my $got = jQuery->as_HTML;

$got =~ s/[\n\s+]//g;
$expected =~ s/[\n\s+]//g;

is($got,$expected);
