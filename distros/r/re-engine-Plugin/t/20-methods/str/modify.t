use strict;
use Test::More tests => 1;
use re::engine::Plugin (
    exec => sub {
        my ($re, $str) = @_;

        $$str = "eek";

        return 1;
    },
);

my $sv = "ook";
if (\$sv =~ /pattern/) {
    is($sv, "eek");
}
