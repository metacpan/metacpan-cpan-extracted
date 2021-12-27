use strict;
use warnings;
use ExtUtils::MakeMaker 6.86;

WriteMakefile(
    NAME             => 'Tripletail',
    AUTHOR           => 'Ymirlink <tl@tripletail.jp>',
    LICENSE          => 'perl',
    VERSION_FROM     => 'lib/Tripletail.pm',
    ABSTRACT_FROM    => 'lib/Tripletail.pm',
    MIN_PERL_VERSION => '5.8.1',
    PL_FILES         => {},
    EXE_FILES        => [qw(bin/tltail.pl)],
    META_MERGE => {
        'meta-spec' => {
            version => 2,
           },
        no_index => {
            directory => [
                'sample'
               ]
           },
        prereqs => {
            test => {
                requires => {
                    'Test::Exception'   => 0,
                    'Test::More'        => '0.94'
                   },
                suggests => {
                    'Test::Dependencies'  => 0,
                    'Test::Pod'           => '1.14',
                    'Test::Pod::Coverage' => '1.04'
                   }
               },
            runtime => {
                recommends => {
                    'Cache::Memcached'  => 0,
                    'DBD::Pg'           => 0,
                    'DBD::SQLite'       => 0,
                    'DBD::mysql'        => 0,
                    'FCGI'              => 0,
                    'PadWalker'         => 0,
                    'Text::CSV_XS'      => 0
                   },
                suggests => {
                    'DBD::InterBase'    => 0,
                    'DBD::ODBC'         => 0,
                    'DBD::Oracle'       => 0,
                    'MongoDB'           => 'v1.6',
                    'Time::Moment'      => 0
                   }
               }
           }
       },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.86',
       },
    BUILD_REQUIRES => {},
    PREREQ_PM => {
        'version'           => '0.77',
        'Compress::Zlib'    => 0,
        'Crypt::CBC'        => 0,
        'Crypt::Rijndael'   => 0,
        'DBI'               => 0,
        'Digest::SHA'       => 0,
        'IO::Scalar'        => 0,
        'LWP::UserAgent'    => 0,
        'List::MoreUtils'   => 0,
        'MIME::Body'        => 0,
        'MIME::Decoder'     => 0,
        'MIME::Entity'      => 0,
        'MIME::Parser'      => 0,
        'MIME::Words'       => '5.411',
        'Scalar::Lazy'      => '0.03',
        'Sub::Install'      => 0,
        'Unicode::Japanese' => '0.43'
       },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);

sub MY::postamble {
    # NOTE: Hard-tabs in the following heredoc is mandatory due to the
    # nature of Makefile's syntax. Don't convert them to spaces.
    return <<'EOF';
.PHONY: html
html: $(TO_INST_PM)
	@$(ECHO) Generating HTML documentation
	@rm -rf blib/$@
	@mkdir -p blib/$@
	@$(PERL) \
		-MPod::Simple::HTMLBatch \
		-e Pod::Simple::HTMLBatch::go lib blib/$@
EOF
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
