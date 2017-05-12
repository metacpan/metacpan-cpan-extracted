use 5.008008;
use ExtUtils::MakeMaker;

our $AUTHOR = -e '.gitignore';
if ($AUTHOR) {
	system( 'pod2text lib/XML/Fast.pm > README' ) and die "$!";
}

WriteMakefile(
	NAME              => 'XML::Fast',
	VERSION_FROM      => 'lib/XML/Fast.pm', # finds $VERSION
	ABSTRACT_FROM     => 'lib/XML/Fast.pm', # retrieve abstract from module
	PREREQ_PM         => { 'Encode' => 0 }, # e.g., Module::Name => 1.1
	AUTHOR            => 'Mons Anderson <mons@cpan.org>',
	LIBS              => [''],
	DEFINE            => '',
	INC               => '-I.',
	$AUTHOR ? (
		CCFLAGS           => '-Wunused -std=c99', # only author mode
	) : (),
	OPTIMIZE		  => '-g',
	OBJECT            => 'Fast.o xmlfast.o', # link all the C files too
	META_ADD          => { license => 'perl' },
);
