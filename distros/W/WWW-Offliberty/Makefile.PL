use ExtUtils::MakeMaker;
use strict;
use warnings;

my $has_br = $ExtUtils::MakeMaker::VERSION >= 6.5503;

WriteMakefile(
	NAME             => 'WWW::Offliberty',
	VERSION_FROM     => 'lib/WWW/Offliberty.pm',
	ABSTRACT_FROM    => 'lib/WWW/Offliberty.pm',
	AUTHOR           => 'Marius Gavrilescu <marius@ieval.ro>',
	EXE_FILES        => ['off'],
	MIN_PERL_VERSION => '5.8.9',
	LICENSE          => 'perl',
	(BUILD_REQUIRES => {
		qw/Test::RequiresInternet 0/,
	}) x $has_br,
	SIGN             => 1,
	PREREQ_PM        => {
		qw/HTML::TreeBuilder 0
		   HTTP::Tiny        0.014/, # post_form was introduced in 0.014
		('Test::RequiresInternet' => 0) x !$has_br
	},
	META_ADD         => {
		dynamic_config => 0,
		resources      => {
			repository   => 'https://git.ieval.ro/?p=www-offliberty.git',
		},
	}
);
