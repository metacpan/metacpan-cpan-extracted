#!perl
use jQuery;
use FindBin qw($Bin);
use Test::More tests => 1;

my $html = do {
    local $/; 
    open my $fh, '<', $Bin . '/html/attr.html';
    <$fh>;
};

my $expected = do {
    local $/;
    open my $fh, '<', $Bin . '/expected/attr.html';
    <$fh>;
};

jQuery->new($html);

jQuery("div")->attr("id", sub {
    my $arr = shift;
    return "div-id" . $arr;
})->each( sub {
  jQuery("span", this)->html("(ID = '<b>" . this->id . "</b>')");
});

my $got = jQuery->as_HTML;

$got =~ s/[\n\s+]//g;
$expected =~ s/[\n\s+]//g;

is($got,$expected);
