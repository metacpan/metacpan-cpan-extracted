#!perl

#   03.colour.t

use strict;
use warnings;
use English qw{-no_match_vars};
use Test::More 0.94;

use Tk;
use Tk::ROSyntaxText;

my $mw = eval { MainWindow->new(
    -title => q{Tk::ROSyntaxText: 03.colour.t},
); };

if ($mw) {
    plan tests => 3;
}
else {
    plan skip_all => q{No display detected.};
}

my %dark_aspect = (
    -foreground         => q{#ffffff},
    -background         => q{#000000},
    -shek_Alert         => [ -background => q{#000000}, -foreground => q{#66ff66} ],
    -shek_BaseN         => [ -background => q{#000000}, -foreground => q{#0099ff} ],
    -shek_BString       => [ -background => q{#000000}, -foreground => q{#cc99ff} ],
    -shek_Char          => [ -background => q{#000000}, -foreground => q{#9966cc} ],
    -shek_Comment       => [ -background => q{#000000}, -foreground => q{#666666} ],
    -shek_DataType      => [ -background => q{#000000}, -foreground => q{#0066ff} ],
    -shek_DecVal        => [ -background => q{#000000}, -foreground => q{#00ccff} ],
    -shek_Error         => [ -background => q{#000000}, -foreground => q{#ff3333} ],
    -shek_Float         => [ -background => q{#000000}, -foreground => q{#339999} ],
    -shek_Function      => [ -background => q{#000000}, -foreground => q{#00ffff} ],
    -shek_IString       => [ -background => q{#000000}, -foreground => q{#ff6699} ],
    -shek_Keyword       => [ -background => q{#000000}, -foreground => q{#ffff00} ],
    -shek_Normal        => [ -background => q{#000000}, -foreground => q{#ffffff} ],
    -shek_Operator      => [ -background => q{#000000}, -foreground => q{#cc6633} ],
    -shek_Others        => [ -background => q{#000000}, -foreground => q{#cc9966} ],
    -shek_RegionMarker  => [ -background => q{#000000}, -foreground => q{#99ccff} ],
    -shek_Reserved      => [ -background => q{#000000}, -foreground => q{#9999ff} ],
    -shek_String        => [ -background => q{#000000}, -foreground => q{#00cc00} ],
    -shek_Variable      => [ -background => q{#000000}, -foreground => q{#33cccc} ],
    -shek_Warning       => [ -background => q{#000000}, -foreground => q{#ff9933} ],
);

my $rosyn = eval { $mw->ROSyntaxText(%dark_aspect); };

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

