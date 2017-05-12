#!perl
use jQuery;
use FindBin qw($Bin);
use Test::More tests => 1;

my $html = do {
    local $/; 
    open my $fh, '<', $Bin . '/html/val.html';
    <$fh>;
};

my $expected = do {
    local $/;
    open my $fh, '<', $Bin . '/expected/val.html';
    <$fh>;
};

jQuery->new($html);

jQuery("#single")->val("Single2");
jQuery("#multiple")->val(["Multiple2", "Multiple3"]); 
jQuery("input")->val(["check1","check2", "radio1" ]);

my $got = jQuery->as_HTML;

$got =~ s/[\n\s+]//g;
$expected =~ s/[\n\s+]//g;

is($got,$expected);
