#!perl

#   09.spacing.t

use strict;
use warnings;
use English qw{-no_match_vars};
use Test::More 0.94;

use Tk;
use Tk::ROSyntaxText;

my $mw = eval { MainWindow->new(
    -title => q{Tk::ROSyntaxText: 09.spacing.t},
); };

if ($mw) {
    plan tests => 3;
}
else {
    plan skip_all => q{No display detected.};
}

my %spacing = (
    -spacing1 => 10,
    -spacing2 => 20,
    -spacing2 => 20,
);

my $rosyn = eval { $mw->ROSyntaxText(%spacing); };

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

