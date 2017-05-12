#!perl
use jQuery;
use FindBin qw($Bin);
use Test::More tests => 1;

my $html = do {
    local $/; 
    open my $fh, '<', $Bin . '/html/removeClass.html';
    <$fh>;
};

my $expected = do {
    local $/;
    open my $fh, '<', $Bin . '/expected/removeClass.html';
    <$fh>;
};

my $dom = jQuery->new($html);
jQuery->new('<b>new</b>');
 
$dom->jQuery($dom->jQuery("p:odd"))->removeClass(sub {
  return 'blue under';
})->css('color','pink');

my $got = $dom->as_HTML;

$got =~ s/[\n\s+]//g;
$expected =~ s/[\n\s+]//g;

is($got,$expected);
