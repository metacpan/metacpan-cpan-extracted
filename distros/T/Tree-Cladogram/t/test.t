use strict;
use warnings;

use File::Spec;
use File::Temp;

use Imager;

use Test::More;

use Tree::Cladogram::Imager;

# ------------------------------------------------

sub get_image_statistics
{
	my($image) = @_;

	return
	{
		bits_per_channel	=> $image -> bits,
		channels			=> $image -> getchannels,
		color_count			=> $image -> getcolorcount(maxcolors => 512) || '> 512',
		height				=> $image -> getheight,
		type				=> $image -> type eq 'direct' ? 0 : 1, # Make numeric for convenience.
		virtual				=> $image -> virtual,
		width				=> $image -> getwidth,
	};

} # End of get_image_statistics.

# ------------------------------------------------

# The EXLOCK option is for BSD-based systems.

my($file_name)		= 'wikipedia.01.png';
my($in_file_name)	= "t/$file_name";
my($temp_dir)		= File::Temp -> newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
my($out_file_name)	= File::Spec -> catfile($temp_dir, $file_name);

# Check that the files are actually different.

ok($in_file_name ne $out_file_name, "Comparing $in_file_name and $out_file_name");

done_testing;

__END__

# Since some CPAN testers have installed Imager without support for *.ttf fonts,
# there is no point in doing the following tests.
# Further, some CPAN testers report images of a different width that the one in t/.
# Worse, Imager::Font does not offer (according to the docs) any way of asking for
# a list of available fonts, so we can't even use a font which Imager /can/ process.

Tree::Cladogram::Imager -> new
(
	draw_frame		=> 1,
	input_file		=> 't/wikipedia.01.clad',
	leaf_font_file	=> 't/FreeSansBold.ttf',
	output_file		=> $out_file_name,
	title			=> 'A horizontal cladogram, with the root to the left',
	title_font_file	=> 't/FreeSansBold.ttf',
) -> run;

my(@images)			= (Imager -> new(file => $in_file_name), Imager -> new(file => $out_file_name) );
my(@statistics)		= map{get_image_statistics($_)} @images;

# Compare the statistics of each image.

for my $key (sort keys %{$statistics[0]})
{
	ok($statistics[0]{$key} == $statistics[1]{$key}, "Comparing $key: $statistics[0]{$key}");
}
