use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

WriteMakefile(
	PREREQ_PM	=> {
			     ExtUtils::MakeMaker => '5.41',   # for #! fixing
			     Tk => '402.002',		      # opt. aliases
			   },

	DISTNAME	=> 'Tk-ACH',
        NAME	=> 'Tk::ACH',
	VERSION		=> '0.08',

	DIR		=> [],
	EXE_FILES	=> [ 'ptktrl' ],

	linkext		=> { LINKTYPE => '' },
	dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
    
    ($mm_ver <= 6.45
        ? ()
        : ('BUILD_REQUIRES' => {
            # optional modules only required for testing
            'Test::More' => '1.0',
        })
    ),
);

__END__

