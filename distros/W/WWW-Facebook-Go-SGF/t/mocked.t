#!perl
# $Id: mocked.t,v 1.1 2009/02/27 19:54:29 drhyde Exp $

use WWW::Facebook::Go::SGF qw(facebook2sgf);

use Test::More tests => 4;
use strict;
use warnings;
no warnings qw(redefine);

sub WWW::Facebook::Go::SGF::_download {
    local $/ = undef;
    my $html = shift;
    open FOO, $html || die("Can't read $html\n");
    my $foo = <FOO>;
    close FOO;
    $foo
}

foreach my $html (glob("t/*.html")) {
    local $/ = undef;
    (my $sgf = $html) =~ s/html/sgf/;
    open(SGF, $sgf) || die("Can't read $sgf\n");
    $sgf = <SGF>;
    close(SGF);
    is_deeply(facebook2sgf($html), $sgf, "$html parsed OK");
}
