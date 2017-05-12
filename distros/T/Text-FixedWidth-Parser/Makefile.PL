use strict;
use warnings;

use 5.10.1;

use ExtUtils::MakeMaker;

my %wm = (
	NAME         => 'Text::FixedWidth::Parser',
	DISTNAME     => 'Text-FixedWidth-Parser',
	ABSTRACT     => 'FixedWidth text file parser',
	AUTHOR       => 'Venkatesan Narayanan',
	VERSION_FROM => 'lib/Text/FixedWidth/Parser.pm',
	PREREQ_PM    => {
		'Moose'            => 2.1804,
		'Math::Expression' => 1.47,
		'Test::Most'       => 0.34,
		'Test::Class'      => 0.50,
	},
);


$ExtUtils::MakeMaker::VERSION > 6.30 and $wm{LICENSE} = "perl";

$ExtUtils::MakeMaker::VERSION > 6.46 and $wm{META_MERGE} = {
	'meta-spec' => { version => 2 },
	'resources' => {
		'repository'  => {
			type => 'git',
			url => 'https://github.com/VenkatesanNarayanan/Text-FixedWidth-Parser.git',
			web => 'https://github.com/VenkatesanNarayanan/Text-FixedWidth-Parser'
		}
	}
};

WriteMakefile(%wm);

