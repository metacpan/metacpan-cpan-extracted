use ExtUtils::MakeMaker;


# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %OPTS = (
    PREREQ_PM => {
        'MIME::Base64'   => 0,
        'Authen::SASL'   => 0,
        'Test::Reporter' => 0,
        'Net::SMTP'      => 0,
        'Net::SMTP::TLS' => 0,
        'CPAN::Reporter' => 0,
    }
);

if ( $] < 5.008 ) {
    warn "perl version $] not supported. exit";
    exit(0);
}
if ( $ExtUtils::MakeMaker::VERSION >= 6.48 ) {
    $OPTS{MIN_PERL_VERSION} = 5.008;
}
else {
    $OPTS{PREREQ_PM}{'perl'} = 5.008;
}

WriteMakefile(
    NAME => 'Test::Reporter::Transport::Net::SMTP::Authen',
    VERSION_FROM =>
      'lib/Test/Reporter/Transport/Net/SMTP/Authen.pm',    # finds $VERSION
    PREREQ_PM => {},    # e.g., Module::Name => 1.1
    (
        $] >= 5.005
        ?               ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM => 'lib/Test/Reporter/Transport/Net/SMTP/Authen.pm'
            ,           # retrieve abstract from module
            AUTHOR => 'A.G. Grishaev <grian@cpan.org>'
          )
        : ()
    ),
    LIBS   => [''],     # e.g., '-lm'
    DEFINE => '',       # e.g., '-DHAVE_SOMETHING'
    INC    => '-I.',    # e.g., '-I. -I/usr/include/other'
                        # Un-comment this if you add C files to link with later:
         # OBJECT            => '$(O_FILES)', # link all the C files too
    ( $ExtUtils::MakeMaker::VERSION >= 6.31 ? ( LICENSE => 'perl' ) : () ),
    %OPTS,
);
