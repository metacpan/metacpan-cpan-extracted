use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'VANAMBURG::Magic',
	AUTHOR       => q{"Gordon Van Amburg" <"vanamburg@cpan.org">},
	VERSION_FROM => 'lib/VANAMBURG/Magic.pm',
	ABSTRACT     => 'A resource for the discriminating card magician.!',
	( $ExtUtils::MakeMaker::VERSION >= 6.3002
		? ( 'LICENSE' => 'perl' )
		: () ),
	PL_FILES  => {},
	PREREQ_PM => {
		'Test::More'                   => 0,
		'Test::Pod'                    => 1.22,
		'Moose'                        => 1.23,
		'MooseX::Singleton'            => 0.28,
		'Moose::Util::TypeConstraints' => 0,
		'Moose::Role'                  => 0,
		'Term::ReadLine'               => 0,
		'List::MoreUtils'              => 0,
	},
	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES    => 'VANAMBURG-Magic-*' },
);
