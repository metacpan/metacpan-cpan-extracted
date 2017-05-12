#!/usr/bin/perl -w

use strict;
use Test::More;

BEGIN {
    eval { require PerlX::MethodCallWithBlock; };
    plan skip_all => "PerlX::MethodCallWithBlock not installed" if $@;
}

use PerlX::MethodCallWithBlock;
plan tests => 11;
use Test::XPath;

my $html = '<html><head><title>Hello</title><body><p><em><b>first</b></em></p><p><em><b>post</b></em></p></body></html>';

ok my $xp = Test::XPath->new(
    xml     => $html,
    is_html => 1,
), 'Should be able to parse HTML';

# Try a recursive call.
$xp->ok( '/html/body/p', 'Find paragraphs' ) {
    shift->ok('./em', 'Find em under para') {
        shift->ok('./b', 'Find b under em');
    };
};

# Now without descriptions.
$xp->ok( '/html/body/p' ) {
    shift->ok('./em') {
        shift->ok('./b');
    };
};

