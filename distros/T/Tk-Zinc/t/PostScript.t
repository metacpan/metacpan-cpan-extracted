use strict;
use warnings;
use Test::More;
use Tk;
use Tk::Zinc;

my $mw = eval { MainWindow->new() };
plan skip_all => "Cannot create a Tk window: $@" unless $mw;
plan tests => 4;

my $zinc = $mw->Zinc(-width => 100, -height => 100, -render => 0)->pack;
$zinc->add('rectangle', 1, [10, 10, 50, 40],
           -filled => 1, -fillcolor => 'red');
$mw->update;

# Exercise the option array after the widget name and 'postscript' command.
my $ps = eval {
    $zinc->postscript(-prolog => 0, -width => 80, -height => 60,
                      -colormode => 'color');
};
is($@, '', 'PostScript accepts multiple options');
ok(defined($ps) && length($ps), 'PostScript contains drawing commands');

eval { $zinc->postscript(-not_a_postscript_option => 1) };
like($@, qr/(?:unknown|bad) option.*not_a_postscript_option/is,
     'PostScript rejects an unknown option');

eval { $zinc->postscript(-width => 'not_a_width') };
like($@, qr/bad screen distance/, 'PostScript validates option values');

$mw->destroy;
