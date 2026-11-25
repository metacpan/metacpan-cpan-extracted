use strict;
use warnings;
use Test::More 0.98;
use File::Temp qw(tempdir);

use lib 't/lib';
use Images;

use Text::ANSI::Image;

my $dir = tempdir(CLEANUP => 1);

# info: the size and the type, from the content, not the name
{
    is_deeply([ Text::ANSI::Image->info(png("$dir/a.png", 64, 68)) ], [ 64, 68, 'png' ], 'info: PNG');
    is_deeply([ Text::ANSI::Image->info(gif("$dir/a.gif", 30, 20)) ], [ 30, 20, 'gif' ], 'info: GIF');
    is_deeply([ Text::ANSI::Image->info(jpeg("$dir/a.jpg", 300, 200)) ], [ 300, 200, 'jpeg' ], 'info: JPEG');
    is_deeply([ Text::ANSI::Image->info(png("$dir/png.gif", 10, 10)) ], [ 10, 10, 'png' ], 'info: by the content, not the name');
    Images::write_file("$dir/fake.png", "not an image\n");
    is_deeply([ Text::ANSI::Image->info("$dir/fake.png") ], [], 'info: not an image');
    is_deeply([ Text::ANSI::Image->info("$dir/missing.png") ], [], 'info: no file');
}

# new: a method by its name, or the first one that the terminal supports
{
    my $img = Text::ANSI::Image->new(method => 'kitty');
    isa_ok($img, 'Text::ANSI::Image::kitty');
    isa_ok($img, 'Text::ANSI::Image');
    is($img->method, 'kitty', 'method: the name');

    eval { Text::ANSI::Image->new(method => 'nothing') };
    like($@, qr/nothing/, 'an unknown method dies');
    eval { Text::ANSI::Image->new(method => '../x') };
    like($@, qr/method/, 'a name which is not a word dies');

    local %ENV = (%ENV, TERM => 'dumb');
    delete $ENV{TERM_PROGRAM};
    is(Text::ANSI::Image->new, undef, 'auto: undef in a terminal which supports none');
    $ENV{TERM_PROGRAM} = 'ghostty';
    isa_ok(Text::ANSI::Image->new, 'Text::ANSI::Image::kitty', 'auto: kitty in Ghostty');
}

# terminal: the size given, or that of the tty
{
    my $img = Text::ANSI::Image->new(method => 'kitty', term => '80x24:16x34');
    is_deeply([ $img->terminal ], [ 80, 24, 16, 34 ], 'terminal: COLSxROWS:WxH');
    $img = Text::ANSI::Image->new(method => 'kitty', term => '100x30');
    is_deeply([ $img->terminal ], [ 100, 30, 0, 0 ], 'terminal: COLSxROWS, no pixels');
    eval { Text::ANSI::Image->new(method => 'kitty', term => 'large') };
    like($@, qr/COLSxROWS/, 'terminal: a wrong size dies');
}

# cells: as large as the pixels, and not larger than the room
{
    my $img = Text::ANSI::Image->new(method => 'kitty', term => '80x24:16x34');
    is_deeply([ $img->cells(64, 68) ], [ 4, 2 ], 'cells: by the pixels of a cell');
    is_deeply([ $img->cells(1600, 34) ], [ 80, 1 ], 'cells: not wider than the terminal');
    is_deeply([ $img->cells(1600, 34, width => 40) ], [ 40, 1 ], 'cells: not wider than width');
    is_deeply([ $img->cells(16, 3400) ], [ 1, 20 ], 'cells: not higher than the terminal minus four');
    is_deeply([ $img->cells(16, 3400, rows => 5) ], [ 1, 5 ], 'cells: not higher than rows');
    $img = Text::ANSI::Image->new(method => 'kitty', term => '100x30');
    is_deeply([ $img->cells(80, 34) ], [ 10, 2 ], 'cells: a cell of 8x17 without pixels');
}

done_testing;
