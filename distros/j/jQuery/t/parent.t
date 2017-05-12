#!perl
use jQuery;
use FindBin qw($Bin);
use Test::More tests => 1;

my $html = do {
    local $/; 
    open my $fh, '<', $Bin . '/html/parent.html';
    <$fh>;
};

my $expected = do {
    local $/;
    open my $fh, '<', $Bin . '/expected/parent.html';
    <$fh>;
};

jQuery->new($html);

jQuery("*", jQuery->document->body)->each(sub {
    my $parentTag = jQuery(this)->parent->get(0)->tagName;
    this->prepend(jQuery->document->createTextNode($parentTag . " > "));
});

my $got = jQuery->as_HTML;

$got =~ s/[\n\s+]//g;
$expected =~ s/[\n\s+]//g;

is($got,$expected);
