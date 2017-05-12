use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my @ppd = ();
if ($] >= 5.00503) {
	@ppd = (
		'AUTHOR'   => 'Henrique Dias <hdias@aesbuc.pt>',
		'ABSTRACT' => 'Extension for extract words from strings',
	);
}

WriteMakefile(
    'NAME'	=> 'Text::ExtractWords',
    'DISTNAME'	=> 'Text-ExtractWords',
    'VERSION_FROM' => 'ExtractWords.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm'
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING'
    'INC'	=> '',     # e.g., '-I/usr/include/other',
    'dist'         => { 'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz', },
    @ppd,
);
