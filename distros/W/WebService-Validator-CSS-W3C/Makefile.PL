use 5.006;
use ExtUtils::MakeMaker;

my %options = (
    NAME              => 'WebService::Validator::CSS::W3C',
    VERSION_FROM      => 'lib/WebService/Validator/CSS/W3C.pm',

    PREREQ_PM         => {

      SOAP::Lite => 0.65,
      LWP::UserAgent => 0,
      URI => 0,
      URI::QueryParam => 0,
      Carp => 0,
      Class::Accessor => 0,

    }, # e.g., Module::Name => 1.1

    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WebService/Validator/CSS/W3C.pm', # retrieve abstract from module
       AUTHOR         => 'Bjoern Hoehrmann <bjoern@hoehrmann.de>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
	# Insert -I. if you add *.h files later:
    INC               => '',

    XSOPT             => '',

	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too

    LICENSE           => 'perl',
    'dist'            => {
      PREOP     => 'chmod 600 Makefile.PL',
      TARFLAGS	=> '--group=none --owner=bjoern --mode=a+rw -cvf',
      COMPRESS  => 'gzip -9',
    },
    clean => { FILES => [], },
);

WriteMakefile(%options);
