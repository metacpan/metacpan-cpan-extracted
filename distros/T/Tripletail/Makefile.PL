use strict;
use warnings;
use ExtUtils::MakeMaker;

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
        no_index => {
            directory => [
                'sample'
               ]
           }
       },
    PREREQ_PM => {
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
    BUILD_REQUIRES => {
        'Test::Exception'   => 0,
        'Test::More'        => '0.94'
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
