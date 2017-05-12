use 5.6.0;
use ExtUtils::MakeMaker;
use ExtUtils::Command qw( touch rm_f );
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
# Customizations stolen from WWW::Mechanize
eval { use HTML::Parser };
if ($@ and $@ =~ /Can't load .*\/Parser\.so/) {
    print "Your HTML::Parser .so isn't installed correctly; can't install";
    exit 2;
}

my $parms = 
  {
    NAME              => 'Test::WWW::Simple',
    VERSION_FROM      => 'lib/Test/WWW/Simple.pm', # finds $VERSION
    PREREQ_PM         => {'Test::Builder' => 0,
                          'Test::LongString' => 0,
                          'Test::Tester' => 0,
                          'HTML::Tree' => 0,
                          'WWW::Mechanize' => 0,
                          'WWW::Mechanize::Pluggable' => 1.07,
                          'Regexp::Common' => 0,
                          'Mojolicious::Lite' => 0,
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Test/WWW/Simple.pm', # retrieve abstract from module
       AUTHOR         => 'Joe McMahon <mcmahon@cpan.org>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
  };

WriteMakefile(%$parms);
