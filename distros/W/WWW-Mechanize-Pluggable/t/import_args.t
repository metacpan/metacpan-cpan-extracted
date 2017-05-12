use warnings;
use strict;
use Test::More tests => 3;

BEGIN {
    use FindBin;

    use lib "$FindBin::Bin/lib";
    use_ok( 'WWW::Mechanize::Pluggable' );
}

my $empty = new WWW::Mechanize::Pluggable;
is $empty->preserved, undef, "No args works ok";

my $have1 = new WWW::Mechanize::Pluggable Echo=>"foo=>bar", baz=>'quux';
is $have1->preserved, 'Echo => foo=>bar', "args work too";
