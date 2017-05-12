
use 5.006;
use ExtUtils::MakeMaker 6.31;    # XXX yes, that's not a nice thing to do

my $EUMM_VERSION = eval $ExtUtils::MakeMaker::VERSION;

WriteMakefile(
    NAME         => 'WWW::CPAN',
    VERSION_FROM => 'lib/WWW/CPAN.pm',

    PREREQ_PM => {
        'strict'   => 0,
        'warnings' => 0,

        #    'LWP::UserAgent'   => 0,
        'LWP::UserAgent::Determined' => 0,
        'URI'                        => 0,
        'parent'                     => 0,
        'Class::Accessor'            => 0,
        'Class::Lego::Constructor'   => 0.004,
        'Class::Lego::Myself'        => 0.001,
        'Carp'                       => 0,

        'JSON::MaybeXS' => 0,
        'XML::Simple'   => 0,

        # required by bin/cpanq
        'Data::Dump::Streamer' => 0,
        'Cache::FileCache'     => 0,
        'File::HomeDir'        => 0,
        'Path::Class'          => 0,
        'Pod::Usage'           => 0,

        'Test::More' => 0.17,    # can_ok

    },
    ($EUMM_VERSION > 6.4501 ? (
            META_MERGE => {
                resources => {
                    repository => 'http://github.com/aferreira/cpan-WWW-CPAN',
                }
            },
          )
    : () ),

    # recommends => {
    #       'Test::Script' => 0,
    #}
    EXE_FILES => ['bin/cpanq'],
    ($EUMM_VERSION >= 6.31 ? ( 
		    LICENSE => 'perl', 
    ) : ()),
    ($EUMM_VERSION >= 6.07 ? (
            ABSTRACT_FROM => 'lib/WWW/CPAN.pod',
            AUTHOR        => 'Adriano R. Ferreira <ferreira@cpan.org>'
          )
    : () ),
);
