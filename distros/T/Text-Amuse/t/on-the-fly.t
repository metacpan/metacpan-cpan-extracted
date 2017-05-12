use strict;
use warnings;
use utf8;
use Test::More tests => 4;
use Text::Amuse::Functions qw/muse_to_html muse_to_tex/;

my $muse =<<'EOF';
#title ààć

Hello there ààć;
EOF

my $ltx =<<'EOF';

Hello there ààć;

EOF

my $html =<<'EOF';

<p>
Hello there ààć;
</p>
EOF

is(muse_to_tex($muse), $ltx, "LaTeX ok");
is(muse_to_html($muse), $html, "HTML ok");

diag "Trying passing a ref to a scalar";

is(muse_to_tex(\$muse), $ltx, "LaTeX ok");
is(muse_to_html(\$muse), $html, "HTML ok");
