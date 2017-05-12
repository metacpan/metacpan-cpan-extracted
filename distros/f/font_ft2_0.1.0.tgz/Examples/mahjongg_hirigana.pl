#!/usr/bin/perl

=head1 mahjongg_hirigana.pl

=item Written: 20020521

=back

=item Creator: Andrew Robertson

=back

=item Revised: 20020527

=back

=item License: GPL 2

=back

Description:

  This simple script creates a new gnome mahjong tileset.  The tile set will be
  named temp.xpm .  And, will contain about half of the Japanese hirigana

  To use the tileset, execute this script.  Then, change the file temp.xpm to
  an PNG file, with the .png extension.  Then, copy the file to the gnome-mahjonng
  tileset directory.  On my system, this is /usr/share/pixmaps/mahjongg.  Start
  mahjongg, go to the Settings->Preferences menu.  Once the new window has loaded,
  select the new tileset in the Tiles frame.  Then, click OK.  You sould see the
  new tileset!

Caveats:

  Mahjongg does not use perfect matching.  So, often two unrelated characters will
  need to be selected to move forward in the game.  I'm trying to get a "Perfect
  Match Only" option added to gnome-mahjongg in the future to avoid this problem.

Syntax:

  ./mahjongg_hirigana.pl

=cut

use FONT::FT2 ':all';

$retval = init("/usr/share/fonts/ja/TrueType/kochi-mincho.ttf"); #japanese italic
if (!defined($retval)) {
	print "Unable to initialize font!\n";
	exit(0);
}

# basic HIRIGANA table
my $kana =  [
0x3042, 0x3044, 0x3046, 0x3048, 0x304a, 0x304b, 0x304d, 0x304f, 0x3051, 0x3053,
0x3055, 0x3057, 0x3059, 0x305b, 0x305d, 0x305f, 0x3061, 0x3064, 0x3066, 0x3068,
0x306a, 0x306b, 0x306c, 0x306d, 0x306e, 0x306f, 0x3072, 0x3075, 0x3078, 0x307b,
0x307e, 0x307f, 0x3080, 0x3081, 0x3082, 0x3084, 0x3086, 0x3088, 0x3089, 0x308a,
0x308b, 0x308c,
0x3042, 0x3044, 0x3046, 0x3048, 0x304a, 0x304b, 0x304d, 0x304f, 0x3051, 0x3053,
0x3055, 0x3057, 0x3059, 0x305b, 0x305d, 0x305f, 0x3061, 0x3064, 0x3066, 0x3068,
0x306a, 0x306b, 0x306c, 0x306d, 0x306e, 0x306f, 0x3072, 0x3075, 0x3078, 0x307b,
0x307e, 0x307f, 0x3080, 0x3081, 0x3082, 0x3084, 0x3086, 0x3088, 0x3089, 0x308a,
0x308b, 0x308c
];

# Color and Character numbers must match.  However, an undefined color will translate to black normally.
my $colors = [
undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,
undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,
"0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff","0xff00ff"
];

$retval = render_table (40, 56, 4, 21, $kana, $colors, 0x20000, 0x20000);

if (defined($retval->{'ok'})) {
	$retval = bitmap_as_xpm($retval);
	if (defined($retval)) {
		open (OUTPUT, '> temp.xpm');
	        print OUTPUT $retval;
		close (OUTPUT);
		print "SUCCESS!\n";
	} else {
		print "FAILURE!  Unable to convert bitmap to xpm\n";
	}
} else {
	print "FAILURE!  Unable to render bitmap\n";
}
