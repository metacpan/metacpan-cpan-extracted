use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

WriteMakefile(
	'NAME'			=> 'Tk::Text::SuperText',
	'VERSION_FROM'	=> 'lib/Tk/Text/SuperText.pm', # finds $VERSION
    'ABSTRACT_FROM' => 'lib/Tk/Text/SuperText.pm', # retrieve abstract from module
	'dist' 		    =>	{COMPRESS => 'gzip -9f',SUFFIX => '.gz'},
	'AUTHOR'	    => 'Alessandro Iob',
    'LICENSE'       => 'perl_5',

    ($mm_ver <= 6.46
        ? ()
        : ('META_MERGE' => {
            'meta-spec' => { version => 2 },
            'resources' => {
                'repository'  => {
                    'url'  => 'https://github.com/asb-capfan/Tk-Text-SuperText.git',
                    'web'  => 'https://github.com/asb-capfan/Tk-Text-SuperText',
                    'type' => 'git',
                },
            },
          })
    ),

    ($mm_ver <= 6.45
        ? ()
        : ('TEST_REQUIRES' => {
            # optional modules only required for testing
            'Test::More' => '0.98',
            'Test::Pod' => '1.0',
            'Test::Pod::Coverage' => '1.08',
        })
    ),
    
	'PREREQ_PM' => {
        'Tk::Text' => 0,
        'Tk' => '804.030',
    },
    
    MIN_PERL_VERSION => 5.008008,
);
