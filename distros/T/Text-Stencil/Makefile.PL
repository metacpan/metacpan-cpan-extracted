use ExtUtils::MakeMaker;
use Config;

my $version = MM->parse_version('lib/Text/Stencil.pm');

WriteMakefile(
    NAME          => 'Text::Stencil',
    VERSION_FROM  => 'lib/Text/Stencil.pm',
    ABSTRACT_FROM => 'lib/Text/Stencil.pm',
    AUTHOR        => 'vividsnow',
    XS            => { 'XS.xs' => 'XS.c' },
    OBJECT        => 'XS$(OBJ_EXT)',
    # bench.pl lives at the top level so the docs can say "perl bench.pl"; left
    # implicit, MakeMaker treats every top-level .pl as installable and puts it
    # in site_perl as Text/bench.pl
    PM            => { 'lib/Text/Stencil.pm' => '$(INST_LIB)/Text/Stencil.pm' },
    # -O3 is worth ~6% here, but only ask for it where it means something:
    # $Config{optimize} carries the CRT model on MSVC, so replacing it wholesale
    # risks linking against a different runtime than perl itself
    # The C is C99 (declarations in for-loops, static inline, long long). gcc
    # only defaults to that from 5.x, so anything older -- RHEL/CentOS 7 ships
    # 4.8 -- needs telling, or the build fails outright.
    # ...but if this perl already asks for a dialect, leave it alone: appending
    # gnu99 to a ccflags carrying -std=c11 would downgrade it.
    ($Config{gccversion} && $Config{ccflags} !~ /-std=/
        ? (CCFLAGS => "$Config{ccflags} -std=gnu99") : ()),
    ($Config{gccversion} ? (OPTIMIZE => "$Config{optimize} -O3") : ()),
    MIN_PERL_VERSION => '5.020',
    LICENSE       => 'perl_5',
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '6.64' },
    TEST_REQUIRES => { 'Test::More' => '0.88' },
    META_MERGE    => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Text::Stencil' => {
                file    => 'lib/Text/Stencil.pm',
                version => $version,
            },
        },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/perl5-text-stencil.git',
                web  => 'https://github.com/vividsnow/perl5-text-stencil',
            },
            bugtracker => {
                web => 'https://github.com/vividsnow/perl5-text-stencil/issues',
            },
        },
    },
);

# README is generated from the module's POD, so the two cannot drift.  Hooking
# it to create_distdir (a prerequisite-only rule, portable to BSD make) means
# every tarball carries a current one without a normal build paying for it.
sub MY::postamble {
    return <<'MAKE';
README : lib/Text/Stencil.pm
	$(NOECHO) $(FULLPERLRUN) -MPod::Text -e "Pod::Text->new(sentence => 0, width => 78)->parse_from_file(@ARGV)" lib/Text/Stencil.pm README

create_distdir : README

readme : README
	$(NOECHO) $(NOOP)
MAKE
}
