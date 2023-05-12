use strict;
use warnings;
use ExtUtils::MakeMaker;
require v5.10;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) {
    # developer release
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'         => 'Text::MacroScript',
    'VERSION_FROM' => 'lib/Text/MacroScript.pm', # finds $VERSION
    'DISTNAME'     => 'Text-MacroScript',
    ($] >= 5.005 ?
        (
            ABSTRACT_FROM => 'lib/Text/MacroScript.pm', 
            AUTHOR   => 'Mark Summerfield <summer@perlpress.com>',
        ) : () ),
	'PREREQ_PM'	   => {
		'enum'				=> 1.10,
		'Path::Tiny'		=> 0.068,
		'Capture::Tiny'		=> 0.22,
		'Test::Differences'	=> 0.61,
        'Test::More'		=> 1.001014,
		'Object::Tiny::RW'	=> 1.07,
		'Algorithm::Diff'	=> 1.201,
	},
	'EXE_FILES'	   => [
		'bin/macropp',
		'bin/macrodir',
	],
    'dist'         => { COMPRESS => "gzip -9", SUFFIX => "gz" },

    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.01)
        : ()
    ),

    ($mm_ver >= 6.31 ? (LICENSE => 'lgpl_2_1') : ()),

    ($mm_ver <= 6.45
        ? ()
        : (META_MERGE => {
            'meta-spec' => { version => 2 },
            resources => {
                repository  => {
                    type => 'git',
                    url  => 'git://github.com/pauloscustodio/Text-MacroScript.git',
                    web  => 'https://github.com/pauloscustodio/Text-MacroScript',
                },
            },
          })
    ),

    clean               => { FILES => [ 'Text-MacroScript-*',
										'*.tmp',
										'*.bak',
										'test*~',
									  ]
						   },
) ;
