use warnings;
use strict;
use Test::More tests => 4;

BEGIN {
    use FindBin;

    use lib "$FindBin::Bin/lib";
}
use WWW::Mechanize::Pluggable NoParam=>[ qw(foo) ];

my $empty = new WWW::Mechanize::Pluggable;
is $empty->preserved, undef, "No args works ok";
is $empty->no_params, 'foo', 'import param also works';

my $have1 = new WWW::Mechanize::Pluggable Echo=>"foo=>bar", baz=>'quux';
is $have1->preserved, 'Echo => foo=>bar', "args work too";
is $have1->no_params, 'foo', 'import param also works';
