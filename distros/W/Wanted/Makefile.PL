use ExtUtils::MakeMaker;
use strict;
use warnings;
use warnings::register;

sub MY::distsignature
{
    return << 'EOT';
distsignature : distmeta
	$(NOECHO) ./dev/cleanup.pl
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'eval { maniadd({q{SIGNATURE} => q{Public-key signature (added by MakeMaker)}}) }' \
	  -e '	  or die "Could not add SIGNATURE to MANIFEST: $${'\''@'\''}"' --
	$(NOECHO) cd $(DISTVNAME) && $(TOUCH) SIGNATURE
	cd $(DISTVNAME) && cpansign -s
EOT
}

my %WriteMakefileArgs = (
    NAME                => 'Wanted',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    VERSION_FROM        => 'lib/Wanted.pm',
    ABSTRACT_FROM       => 'lib/Wanted.pm',
    PL_FILES            => {},
    PREREQ_PM           => {
        'parent'            => 0,
        'strict'            => 0,
        'vars'              => 0,
        'warnings'          => 0,
        'DynaLoader'        => 0,
        'Exporter'          => 0,
    },
    TEST_REQUIRES =>
    {
        'lib'               => 0,
        'Test::More'        => 0,
        'Test::Pod'         => 0,
    },
    XS =>
    {
        'Wanted.xs' => 'Wanted.c',
    },
    LICENSE             => 'perl_5',
    # 2000-03-23
    MIN_PERL_VERSION    => 'v5.6.0',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp', PREOP => './dev/cleanup.pl' },
    clean               => { FILES => 'Wanted-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        keywords => [ 'context', 'XS', 'Want', 'perl', 'scalar', 'array', 'list' ],
        resources => {
            homepage    => 'https://gitlab.com/jackdeguest/Wanted',
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/Wanted.git',
                web         => 'https://gitlab.com/jackdeguest/Wanted',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/Wanted/issues',
            },
        },
        prereqs => {
            develop => {
                requires => {
                    'Module::Generic::File' => '0',
                },
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);

