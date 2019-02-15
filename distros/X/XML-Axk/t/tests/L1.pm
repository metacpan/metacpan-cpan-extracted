# Tests for XML::Axk::L1.
# Copyright (c) 2018 cxw42.  All rights reserved.  Artistic 2.
# Test XML::Axk::L::L1;
package L1;

use AxkTest;
use parent 'Test::Class';
use Test::Exception;

sub class { "XML::Axk::L::L1" };

diag("Testing ", class);

# Inline script, operation at runtime ============================= {{{1
sub t1 :Test(1) {
    my $core = XML::Axk::Core->new();
    $core->load_script_text(text => q{
        -L1
        perform { say $E; } xpath("//item");
        perform { say $E; } xpath(q<//@attrname>);
    } =~ s/^\h*//gmr);
    # Note: q<> is because Perl tries to interpolate an array into "//@attrname"

    my $out = capture_stdout { $core->run(tpath 'ex/ex1.xml'); };
    like($out, qr<(XML::DOM::Element[^\n]*\n){2}>, 'matched multiple elements');
}

# }}}1

sub t2 :Test(1) {
    my $core = XML::Axk::Core->new();
    $core->load_script_text(text => q{
        -L1
        # It has to be `leaving` because otherwise the text-node child
        # hasn't been loaded yet!
        leaving { xpath(q<//sodium>) } run {
            say $E->getFirstChild->getNodeValue;
        }} =~s/^\h*//gmr);
    my $out = capture_stdout { $core->run(tpath 'ex/nutrition.xml'); };
    like($out, qr<2400\s+210\s+510\s+1100\s+810\s+15\s+65\s+20\s+180\s+420\s+10>, 'extracted node text using leaving{}');
}

sub t3 :Test(1) {
    my $core = XML::Axk::Core->new();
    $core->load_script_text(text => q{
        -L1
        # `on` is an alias of `leaving`.
        on { xpath(q<//sodium>) } run {
            say $E->getFirstChild->getNodeValue;
        }} =~s/^\h*//gmr);
    my $out = capture_stdout { $core->run(tpath 'ex/nutrition.xml'); };
    like($out, qr<2400\s+210\s+510\s+1100\s+810\s+15\s+65\s+20\s+180\s+420\s+10>, 'extracted node text using on{}');
}

sub t4 :Test(1) {
    my $core = XML::Axk::Core->new();
    $core->load_script_text(text => q{
        -L1
        entering { xpath(q<//sodium>) } run {
            say $E->getFirstChild->getNodeValue;
        }} =~s/^\h*//gmr);
    dies_ok { $core->run(tpath 'ex/nutrition.xml'); } "entering{} doesn't get the node's text content";
}

1;

# vi: set ts=4 sts=4 sw=4 et ai fdm=marker fdl=1: #
