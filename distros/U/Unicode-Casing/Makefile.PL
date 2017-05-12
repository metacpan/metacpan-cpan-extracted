use ExtUtils::MakeMaker;
use ExtUtils::Depends;

require 5.010;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $pkg = ExtUtils::Depends->new('Unicode::Casing',
                                 'B::Hooks::OP::Check',
                                 'B::Hooks::OP::PPAddr');
WriteMakefile(
    NAME              => 'Unicode::Casing',
    VERSION_FROM      => 'lib/Unicode/Casing.pm', # finds $VERSION
    MIN_PERL_VERSION  => '5.10.0',
    LICENSE           => 'perl_5',  
    PREREQ_PM         => {
                            'B::Hooks::OP::Check'  => 0,
                            'B::Hooks::OP::PPAddr' => 0,
                            'Test::More'           => 0,
                            'XSLoader'             => 0,
						},
    ABSTRACT_FROM     => 'lib/Unicode/Casing.pm', # retrieve abstract from module
    AUTHOR            => 'Karl Williamson <khw@cpan.org>',
    META_MERGE        => {
                           "meta-spec" => { version => 2 },
                           dynamic_config => 0,
                           resources => {
                               repository => {
                                   type => 'git',
                                   url => 'git@github.com:khwilliamson/Unicode-Casing.git',
                                   web => 'https://github.com/khwilliamson/Unicode-Casing',
                               },
                           },
                       },
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
    $pkg->get_makefile_vars,
    CONFIGURE_REQUIRES => {
                            'ExtUtils::MakeMaker'  => 0,
                            'ExtUtils::Depends'    => 0,

                            # Suggested by Florian Ragwitz to see if this
                            # clears up some load issues on some platforms
                            'B::Hooks::OP::PPAddr' => 0,
                            'B::Hooks::OP::Check'  => 0,
                          },
    clean => {
    	FILES => [ qw(Unicode-*) ],
    	}
);
