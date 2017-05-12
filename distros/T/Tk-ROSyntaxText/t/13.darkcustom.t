#!perl

#   13.darkcustom.t

use strict;
use warnings;
use English qw{-no_match_vars};
use Test::More 0.94;

use Tk;
use Tk::ROSyntaxText;

my $mw = eval { MainWindow->new(
    -title => q{Tk::ROSyntaxText: 13.darkcustom.t},
); };

if ($mw) {
    plan tests => 3;
}
else {
    plan skip_all => q{No display detected.};
}

my $rh_custom = {
    -shek_Comment => [ -background => q{#ff0000}, -foreground => q{#ffff00} ],
    -spacing1 => 30,
    -width => 45,
    -height => 12,
    -wrap => q{char},
};

my $rosyn = eval { $mw->ROSyntaxText(-dark_style => 1, -custom_config => $rh_custom); };

ok(! $EVAL_ERROR, q{Test widget instantiaton})
    or diag $EVAL_ERROR;

eval { $rosyn->pack(-fill => q{both}, -expand => 1); };

ok(! $EVAL_ERROR, q{Test widget packing})
    or diag $EVAL_ERROR;

my $hello_world_code = <<'END_CODE';
#!perl -T
#
#   Prints: "Hello, world!"
my $greeting = q{Hello, world!};
print STDOUT $greeting, qq{\n};
exit 0;
END_CODE

eval { $rosyn->insert($hello_world_code); };

ok(! $EVAL_ERROR, q{Test text insertion})
    or diag $EVAL_ERROR;

my $exit_button
    = $mw->Button(-text => q{Exit}, -command => sub { exit; })->pack();

if (! $ENV{CPAN_TEST_AUTHOR}) {
    $exit_button->invoke();
}

MainLoop;

