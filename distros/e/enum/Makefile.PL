use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

WriteMakefile(
    'NAME'	=> 'enum',
    'VERSION_FROM' => 'lib/enum.pm', # finds $VERSION

    PREREQ_PM => {
        'Carp'     => 0,
        'strict'   => 0,
        'warnings' => 0,
    },

    ($mm_ver >= 6.31 ? (LICENSE => 'perl') : ()),

    ($mm_ver <= 6.45 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker  => 'https://rt.cpan.org/Public/Dist/Display.html?Name=enum',
            repository  => {
                type => 'git',
                web  => 'https://github.com/neilbowers/enum',
                url  => 'git://github.com/neilbowers/enum.git',
            },
        },
    })),

    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.006)
        : ()
    ),

);
