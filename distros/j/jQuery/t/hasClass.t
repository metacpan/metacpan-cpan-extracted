#!perl
use jQuery;
use FindBin qw($Bin);
use Test::More tests => 1;

my $html = do {
    local $/; 
    open my $fh, '<', $Bin . '/html/hasClass.html';
    <$fh>;
};

my $expected = do {
    local $/;
    open my $fh, '<', $Bin . '/expected/hasClass.html';
    <$fh>;
};

jQuery->new($html);

jQuery("div#result1")->append(jQuery("p:first")->hasClass("selected"));
jQuery("div#result2")->append(jQuery("p:last")->hasClass("selected"));
jQuery("div#result3")->append(jQuery("p")->hasClass("selected"));

my $got = jQuery->as_HTML;

$got =~ s/[\n\s+]//g;
$expected =~ s/[\n\s+]//g;

is($got,$expected);
