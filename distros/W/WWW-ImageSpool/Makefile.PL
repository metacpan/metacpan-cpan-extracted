
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=>	"WWW::ImageSpool",
	VERSION_FROM	=>	"lib/WWW/ImageSpool.pm",
	EXE_FILES		=>	[ "bin/imagespoold.pl" ],
	AUTHOR			=>	"Tyler MacDonald <tyler@yi.org>",
	PREREQ_PM		=>	{
		'WWW::Google::Images'	=>	0.4,
		'Image::Size'			=>	0,
		'LWP'					=>	0,
		'Getopt::Long'			=>	0
	}
);



