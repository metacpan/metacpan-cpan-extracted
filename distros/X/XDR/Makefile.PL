use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	 => 'XDR',
    AUTHOR       => 'Gordon Matzigkeit <gord@fig.org>',
    ABSTRACT     => 'Perl XDR interface',
    VERSION_FROM => 'XDR.pm',
    dist         => { 'COMPRESS' => 'gzip -9',
		      'SUFFIX'   => 'gz',
		    },
);
