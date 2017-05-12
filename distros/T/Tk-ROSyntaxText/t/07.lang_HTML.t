#!perl

#   07.lang_HTML.t

use strict;
use warnings;
use English qw{-no_match_vars};
use Test::More 0.94;

use Tk;
use Tk::ROSyntaxText;

my $mw = eval { MainWindow->new(
    -title => q{Tk::ROSyntaxText: 07.lang_HTML.t},
); };

if ($mw) {
    plan tests => 3;
}
else {
    plan skip_all => q{No display detected.};
}

my $rosyn = eval { $mw->ROSyntaxText(-syntax_lang => q{HTML}); };

ok(! $EVAL_ERROR, q{Test widget instantiaton})
    or diag $EVAL_ERROR;

eval { $rosyn->pack(-fill => q{both}, -expand => 1); };

ok(! $EVAL_ERROR, q{Test widget packing})
    or diag $EVAL_ERROR;

my $hello_world_code = <<'END_CODE';
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
    "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
    <!-- For HTML syntax highighting -->
    <head>
        <title>Greeting</title>
    </head>
    <body>
        <h1>Greeting</h1>

        <p>
            Hello, world!
        </p>
    </body>
</html>
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

