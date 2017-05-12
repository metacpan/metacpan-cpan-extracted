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
    PREREQ_PM         => {
            Tk  => 804.0, 
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Tk/WaitBoxFixed.pm', # retrieve abstract from module
       AUTHOR         => 'Rene Schickbauer <rene.schickbauer@magnapowertrain.com>') : ()),
    ($mm_ver <= 6.45
        ? ()
        : (META_MERGE => {
            'meta-spec' => { version => 2 },
            resources => {
                repository  => {
                    type => 'hg',
                    web  => 'https://sourceforge.net/p/tk-waitboxfixed/code/ci/default/tree/',
                    url  => 'http://hg.code.sf.net/p/tk-waitboxfixed/code tk-waitboxfixed-code',
                },
            },
          })
    ),
    ($mm_ver <= 6.31
        ? ()
        : (LICENSE => 'perl_5')
    ),
);
