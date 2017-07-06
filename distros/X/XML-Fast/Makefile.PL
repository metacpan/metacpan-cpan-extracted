use 5.008008;
use ExtUtils::MakeMaker;
use Config;

our $AUTHOR = -e '.gitignore';
our $CCFLAGS = $Config::Config{ccflags};
$CCFLAGS .= ' -std=c99' unless $CCFLAGS =~ /\Q-std=c99\E/;
if ($AUTHOR) {
	system( 'pod2text lib/XML/Fast.pm > README' ) and die "$!";
	$CCFLAGS .= ' -Wunused';
}
else {
	$CCFLAGS .= ' -Wno-parentheses -Wno-pointer-sign';
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
	CCFLAGS           => $CCFLAGS,
	OPTIMIZE          => ($AUTHOR ? '-g ' : '').'-O2',
	OBJECT            => 'Fast.o xmlfast.o', # link all the C files too
	META_ADD          => { license => 'perl' },
);
