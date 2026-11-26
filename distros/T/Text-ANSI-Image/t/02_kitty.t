use strict;
use warnings;
use utf8;
use Test::More 0.98;
use File::Temp qw(tempdir);
use MIME::Base64 qw(encode_base64);
use File::Spec;

use lib 't/lib';
use Images;

use Text::ANSI::Image;

my $dir = tempdir(CLEANUP => 1);
my $tty = "$dir/tty";
sub sent { open my $fh, '<:raw', $tty or return ''; local $/; <$fh> }

my $PH = "\x{10EEEE}";
# the first of the combining characters for row and column numbers
my @D = map { chr hex } qw(0305 030D 030E 0310 0312);

sub kitty { Text::ANSI::Image->new(method => 'kitty', term => '80x24:16x34', tty => $tty, @_) }

my $a = png("$dir/a.png", 64, 68);	# 4 cells wide, 2 rows high

# the rows: placeholders with the row and the column, in the color of the id
{
    unlink $tty;
    my $img = kitty();
    my @rows = $img->rows($a);
    is(scalar @rows, 2, 'two rows');
    my($color) = $rows[0] =~ /^(\e\[38;2;\d+;\d+;\d+m)/;
    ok($color, 'a row has the id of the image as its color');
    for my $r (0, 1) {
	unlike($rows[$r], qr/\n/, "row $r: no newline");
	(my $cells = $rows[$r]) =~ s/\e\[[0-9;]*m//g;
	is($cells, join('', map { $PH . $D[$r] . $D[$_] } 0 .. 3), "row $r: 4 cells with row and column");
    }
    is(sent(), '', 'nothing is sent before flush');
    $img->flush;
    my($r, $g, $b) = $color =~ /(\d+);(\d+);(\d+)m/;
    my $id = ($r << 16) | ($g << 8) | $b;
    my $data = do { open my $fh, '<:raw', $a or die; local $/; encode_base64(<$fh>, '') };
    is(sent(), "\e_Ga=T,U=1,i=$id,f=100,q=2,c=4,r=2,m=0;$data\e\\", 'flush: the image with its id and size');
    $img->flush;
    is(length sent(), length("\e_Ga=T,U=1,i=$id,f=100,q=2,c=4,r=2,m=0;$data\e\\"), 'flush: once');

    my @again = $img->rows($a);
    isnt(($again[0] =~ /^(\e\[[0-9;]*m)/)[0], $color, 'another image has another id');
}

# osc: each row tells the id, the size and the file by a private OSC,
# for a program that draws the image itself, as ansi2pdf
{
    my @rows = kitty()->rows($a);
    unlike($rows[0], qr/\e\]/, 'no OSC by default');
    @rows = kitty(osc => 1)->rows($a);
    my($r, $g, $b) = $rows[0] =~ /\e\[38;2;(\d+);(\d+);(\d+)m/;
    my $id = ($r << 16) | ($g << 8) | $b;
    my $osc = "\e]7771;i=$id,c=4,r=2;" . File::Spec->rel2abs($a) . "\e\\";
    is(substr($rows[$_], 0, length $osc), $osc, "osc: row $_ begins with it") for 0, 1;
    png("$dir/a\eb.png", 64, 68);
    @rows = kitty(osc => 1)->rows("$dir/a\eb.png");
    is(scalar @rows, 2, 'a file name with a control character: rows');
    unlike($rows[0], qr/\e\]/, 'a file name with a control character: no OSC');
}

# the data is sent in chunks of 4096 bytes
{
    unlink $tty;
    my $big = png("$dir/big.png", 64, 68);
    open my $fh, '>>:raw', $big or die;
    print $fh "\0" x 8000;	# 10700 bytes of base64
    close $fh;
    my $img = kitty();
    $img->rows($big);
    $img->flush;
    my @apc = sent() =~ /\e_G([^;]*);/g;
    is(scalar @apc, 3, 'three chunks');
    like($apc[0], qr/^a=T,.*m=1$/, 'the first has the keys and more');
    is($apc[1], 'q=2,m=1', 'the second has more');
    is($apc[2], 'q=2,m=0', 'the last has no more');
}

# what is not shown
{
    unlink $tty;
    my $img = kitty();
    Images::write_file("$dir/fake.png", "not an image\n");
    is_deeply([ $img->rows("$dir/fake.png") ], [], 'not an image: no rows');
    is_deeply([ $img->rows("$dir/missing.png") ], [], 'no file: no rows');
    is_deeply([ $img->rows($a, types => ['jpeg']) ], [], 'a type not in types: no rows');
    is_deeply([ kitty(types => ['gif'])->rows($a) ], [], 'types given to new');
    is(scalar(() = kitty(types => ['gif'])->rows($a, types => ['png'])), 2, 'types given to rows take over');
    $img->flush;
    is(sent(), '', 'nothing sent for them');
}

# the size: width and rows, and the limit of the combining characters
{
    my $img = kitty(term => '400x400:16x34');
    png("$dir/wide.png", 16 * 400, 34);
    my @rows = $img->rows("$dir/wide.png");
    (my $cells = $rows[0]) =~ s/\e\[[0-9;]*m//g;
    is(length($cells) / 3, 297, 'no more columns than the combining characters');
    is(scalar(() = kitty()->rows($a, rows => 1)), 1, 'rows: one row');
}

# without sips and ImageMagick, a large PNG is sent as it is, and a
# GIF, which must be made PNG, is not shown
{
    no warnings 'once';
    local $Text::ANSI::Image::SIPS = '/nonexistent/sips';
    local $ENV{PATH} = '/nonexistent';
    my $img = kitty();
    png("$dir/large.png", 4000, 2000);
    is($img->png("$dir/large.png", 4000, 'png', 1600), "$dir/large.png", 'no converter: a large PNG as it is');
    is($img->png(gif("$dir/b.gif", 64, 68), 64, 'gif', 1600), undef, 'no converter: no GIF');
    is_deeply([ $img->rows("$dir/b.gif") ], [], 'no converter: no rows for a GIF');
}

# the terminals which support it
{
    my $K = 'Text::ANSI::Image::kitty';
    local %ENV = %ENV;
    delete @ENV{qw(TERM_PROGRAM TERM_PROGRAM_VERSION)};
    $ENV{TERM} = 'xterm-256color';
    ok(!$K->supported, 'not in a usual terminal');
    $ENV{TERM} = 'xterm-kitty';
    ok($K->supported, 'kitty');
    $ENV{TERM} = 'xterm-256color';
    $ENV{TERM_PROGRAM} = 'ghostty';
    ok($K->supported, 'Ghostty');
    $ENV{TERM_PROGRAM} = 'iTerm.app';
    for ([ '3.7.3', 1 ], [ '3.7.9', 1 ], [ '3.10.0', 1 ], [ '3.6.0beta2', 0 ], [ '3.7.2', 0 ], [ '', 0 ]) {
	$ENV{TERM_PROGRAM_VERSION} = $_->[0];
	is(!!$K->supported, !!$_->[1], "iTerm2 '$_->[0]'");
    }
    $ENV{TERM_PROGRAM} = 'Apple_Terminal';
    ok(!$K->supported, 'Terminal.app');
}

done_testing;
