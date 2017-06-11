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
		'DateTime::Format::Strptime' => 1.68
	},
	TEST_REQUIRES => {
		'Test::Most'       => 0.34,
		'Test::Class'      => 0.50,
	}
);


$ExtUtils::MakeMaker::VERSION > 6.30 and $wm{LICENSE} = "perl";


if ($ExtUtils::MakeMaker::VERSION > 6.52) { 
	$wm{CONFIGURE_REQUIRES} = {"ExtUtils::MakeMaker" => 6.48};
}

if ($ExtUtils::MakeMaker::VERSION > 6.5503 ) { 
	$wm{BUILD_REQUIRES} = {"ExtUtils::MakeMaker" => 6.48};
} else {
	$wm{PREREQ_PM}{"ExtUtils::MakeMaker"} = 6.48;
}

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

