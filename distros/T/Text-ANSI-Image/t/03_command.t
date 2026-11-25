use strict;
use warnings;
use utf8;
use Test::More 0.98;
use File::Temp qw(tempdir);
use File::Spec;

use lib 't/lib';
use Images;

my $dir = tempdir(CLEANUP => 1);
my $tty = "$dir/tty";
my $lib = File::Spec->rel2abs('lib');
my $cmd = qq{$^X -I"$lib" } . File::Spec->rel2abs('script/ansipic');
my $kitty = "$cmd -m kitty --term 80x24:16x34 --tty $tty";
sub sent { open my $fh, '<:raw', $tty or return ''; local $/; <$fh> }
sub placeholders { my $n = () = $_[0] =~ /\xf4\x8e\xbb\xae/g; $n }	# U+10EEEE in UTF-8

my $a = png("$dir/a.png", 64, 68);	# 4 x 2 cells
my $b = png("$dir/b.png", 32, 34);	# 2 x 1 cells

# the rows of the images go to the standard output, and the images to the tty
{
    unlink $tty;
    my $out = `$kitty $a`;
    is($? >> 8, 0, 'an image: success');
    is(scalar(() = $out =~ /\n/g), 2, 'an image: two lines');
    is(placeholders($out), 8, 'an image: 8 cells');
    like(sent(), qr/\A\e_Ga=T,U=1,i=\d+,f=100,q=2,c=4,r=2,m=0;/, 'an image: sent to the tty');

    unlink $tty;
    $out = `$kitty $a $b`;
    is(scalar(() = $out =~ /\n/g), 3, 'two images: one after another');
    is(scalar(() = sent() =~ /\e_Ga=T/g), 2, 'two images: both sent');
}

# the size
{
    is(placeholders(`$kitty -w 2 $a`), 2, '--width: 2 columns');
    is(scalar(() = `$kitty -H 1 $a` =~ /\n/g), 1, '-H: 1 row');

    # RPN with the size of the terminal (80x24) as the initial value.
    # The images are 75 and 50 cells wide, and not more than twice the
    # pixels of the room, so that they are not reduced by a command,
    # which these files, only headers, would not go through.
    my $wide = png("$dir/wide.png", 1200, 34);
    my $half = png("$dir/half.png", 800, 34);
    my $tall = png("$dir/tall.png", 16, 3400);
    is(placeholders(`$kitty -w 2/ $wide`), 40, '--width 2/: half the terminal');
    is(placeholders(`$kitty -w 10- $wide`), 70, '--width 10-: the terminal but 10');
    is(placeholders(`$kitty -w=2/ $wide`), 40, '-w=2/: as ansifold takes it');
    is(placeholders(`$kitty -w=40 $wide`), 40, '-w=40: a number after =');
    is(scalar(() = `$kitty --height 2/ $tall` =~ /\n/g), 12, '--height 2/: half the terminal');
    is(placeholders(`$cmd -m kitty --tty $tty -w 2/ --term 60x24:16x34 $half`), 30,
       '--width 2/: with --term given after it');
    `$kitty -w 2x $wide 2>&1`;
    is($? >> 8, 2, '--width: a wrong expression is an error');
    `$kitty -r 1 $a 2>&1`;
    is($? >> 8, 2, '-r is not an option');
}

# what is not shown: a warning, and the status 1
{
    unlink $tty;
    Images::write_file("$dir/fake.png", "not an image\n");
    my $out = `$kitty $dir/missing.png $dir/fake.png $a 2>&1`;
    is($? >> 8, 1, 'not shown: status 1');
    like($out, qr/missing\.png/, 'not shown: a missing file is named');
    like($out, qr/fake\.png/, 'not shown: a file which is not an image is named');
    is(placeholders($out), 8, 'not shown: the others are shown');

    $out = `$kitty -t jpeg,gif $a 2>&1`;
    is($? >> 8, 1, '--types: a PNG is not shown without png');
    $out = `$kitty -t png $a 2>&1`;
    is(placeholders($out), 8, '--types: a PNG is shown with png');
    $out = `$kitty -t svg $a 2>&1`;
    is($? >> 8, 2, '--types: an unknown type is an error');
}

# the terminal
{
    my $out = `TERM=dumb TERM_PROGRAM= $cmd --tty $tty $a 2>&1`;
    is($? >> 8, 2, 'no method for the terminal: status 2');
    like($out, qr/terminal/, 'no method for the terminal: a message');
    $out = `$cmd -m nothing $a 2>&1`;
    is($? >> 8, 2, 'an unknown method: status 2');
}

like(`$cmd --version`, qr/^ansipic \d/, '--version');
like(`$cmd --help`, qr/^Usage:\s+ansipic/, q(--help));
isnt(system("$cmd >/dev/null 2>&1") >> 8, 0, 'no file: an error');

done_testing;
