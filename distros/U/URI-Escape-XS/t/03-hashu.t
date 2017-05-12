#!perl -w
#
# $Id: 03-hashu.t,v 0.3 2014/01/20 20:39:54 dankogai Exp $
#
# Original as URI-1.35/t/escape.t
#

use URI::Escape::XS;
use Test::More tests => 6;
use Encode;

my %esc =
  map { encode_utf8($_) } (
    '%uHHHH'                   => "%uHHHH",
    '%uD869%uDEB2%u5F3E%u0064' => "\x{2a6b2}\x{5F3E}d"
  );

for my $k (keys %esc) {
    is decodeURIComponent($k) => $esc{$k}, qq{decodeURI("$k")};
}

{
    # Test::Harness 3.x hates me!
    # skip 'Test::Harness->VERSION > 3', 4
    #   if Test::Harness->can('VERSION') and Test::Harness->VERSION >= 3;
    my $warn;
    local($SIG{__WARN__}) = sub { $warn = shift };
    is decodeURIComponent('%uD869') => '', qq{decodeURI("%uD869")};
    like $warn => qr/lo surrogate is missing/, $warn;
    is decodeURIComponent('%uDEB2') => '', qq{decodeURI("%uDEB2")};
    like $warn => qr/invalid surrogate hi/, $warn;
}
