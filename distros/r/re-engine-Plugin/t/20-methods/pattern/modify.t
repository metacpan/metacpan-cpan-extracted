use strict;
use Test::More tests => 1;
use re::engine::Plugin (
    exec => sub {
        my ($re, $str) = @_;
        my $pattern = $re->pattern;

        $$pattern = "eek";

        return 1;
    },
);

my $sv = "ook";
if ("ook" =~ \$sv) {
    is($sv, "eek");
}

