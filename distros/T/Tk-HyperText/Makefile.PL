use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tk::HyperText',
    VERSION_FROM      => 'lib/Tk/HyperText.pm', # finds $VERSION
    PREREQ_PM         => {
        'HTML::TokeParser' => 0,
        'Tk::BrowseEntry'  => 0,
        'Tk::Derived'      => 0,
        'Tk::JPEG'         => 0,
        'Tk::Listbox'      => 0,
        'Tk::PNG'          => 0,
        'Tk::Text'         => 0,
        'URI::Escape'      => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Tk/HyperText.pm', # retrieve abstract from module
       AUTHOR         => 'Noah Petherbridge <kirsle@cpan.org>') : ()),

    ($mm_ver >= 6.31
        ? (LICENSE => 'perl')
        : ()
    ),

    ($mm_ver <= 6.45 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker  => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Tk-HyperText',
            repository  => {
                type => 'git',
                web  => 'https://github.com/kirsle/Tk-HyperText',
                url  => 'git://github.com/kirsle/Tk-HyperText.git',
            },
        },
    })),

);
