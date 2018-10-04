use 5.010;
use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

WriteMakefile(
    NAME              => 'Tk::WaitBoxFixed',
    VERSION_FROM      => 'lib/Tk/WaitBoxFixed.pm', # finds $VERSION
    ABSTRACT_FROM  => 'lib/Tk/WaitBoxFixed.pm', # retrieve abstract from module
	AUTHOR         => 'Rene Schickbauer <rene.schickbauer@magnapowertrain.com>',
	PREREQ_PM         => {
            Tk  => 804.0, 
    }, # e.g., Module::Name => 1.1
    ($mm_ver <= 6.45
        ? ()
        : (META_MERGE => {
            'meta-spec' => { version => 2 },
            resources => {
                repository  => {
                    type => 'hg',
                    web  => 'https://cavac.at/public/mercurial/Tk-WaitBoxFixed/',
                    url  => 'https://cavac.at/public/mercurial/Tk-WaitBoxFixed/file/',
                },
            },
          })
    ),
    ($mm_ver <= 6.31
        ? ()
        : (LICENSE => 'perl_5')
    ),
    ($mm_ver <= 6.48
        ? ()
        : (MIN_PERL_VERSION => 5.010)
    ),
);
